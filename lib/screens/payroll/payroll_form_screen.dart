import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/employee.dart';
import '../../models/payroll.dart';
import '../../providers/employee_provider.dart';
import '../../providers/payroll_provider.dart';

class PayrollFormScreen extends StatefulWidget {
  const PayrollFormScreen({super.key});

  @override
  State<PayrollFormScreen> createState() => _PayrollFormScreenState();
}

class _PayrollFormScreenState extends State<PayrollFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _basicSalaryController = TextEditingController();
  final _bonusController = TextEditingController(text: '0');
  final _deductionsController = TextEditingController(text: '0');

  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM d, yyyy');

  Employee? _selectedEmployee;
  DateTime? _payPeriodStart;
  DateTime? _payPeriodEnd;
  bool _isSubmitting = false;

  double get _netPayPreview {
    final basic = double.tryParse(_basicSalaryController.text) ?? 0;
    final bonus = double.tryParse(_bonusController.text) ?? 0;
    final deductions = double.tryParse(_deductionsController.text) ?? 0;
    return basic + bonus - deductions;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchAll();
    });

    for (final controller in [
      _basicSalaryController,
      _bonusController,
      _deductionsController,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _basicSalaryController.dispose();
    _bonusController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_payPeriodStart ?? DateTime.now())
        : (_payPeriodEnd ?? _payPeriodStart ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _payPeriodStart = picked;
        // Keep end date valid relative to the new start date.
        if (_payPeriodEnd != null && !_payPeriodEnd!.isAfter(picked)) {
          _payPeriodEnd = null;
        }
      } else {
        _payPeriodEnd = picked;
      }
    });
  }

  String? _validateDates() {
    if (_payPeriodStart == null) return 'Pay period start is required';
    if (_payPeriodEnd == null) return 'Pay period end is required';
    if (!_payPeriodEnd!.isAfter(_payPeriodStart!)) {
      return 'Pay period end must be after pay period start';
    }
    return null;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final dateError = _validateDates();

    final employeeId = _selectedEmployee?.id;
    if (employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }

    if (!formValid) return;

    if (dateError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(dateError)));
      return;
    }

    setState(() => _isSubmitting = true);

    final payroll = Payroll(
      basicSalary: double.parse(_basicSalaryController.text),
      bonus: double.tryParse(_bonusController.text) ?? 0,
      deductions: double.tryParse(_deductionsController.text) ?? 0,
      payPeriodStart: _payPeriodStart!,
      payPeriodEnd: _payPeriodEnd!,
    );

    final payrollProvider = context.read<PayrollProvider>();
    final created = await payrollProvider.create(payroll, employeeId);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (created != null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            payrollProvider.errorMessage ?? 'Failed to create payroll record',
          ),
        ),
      );
    }
  }

  String? _requiredNumberValidator(String? value, {bool allowEmpty = false}) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : 'This field is required';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Must be zero or greater';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Payroll Record')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Consumer<EmployeeProvider>(
              builder: (context, employeeProvider, _) {
                final employees = employeeProvider.employees;

                if (employeeProvider.isLoading && employees.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // Keep selection valid if the employee list changes.
                if (_selectedEmployee != null &&
                    !employees.any((e) => e.id == _selectedEmployee!.id)) {
                  _selectedEmployee = null;
                }

                return DropdownButtonFormField<Employee>(
                  value: _selectedEmployee,
                  decoration: const InputDecoration(
                    labelText: 'Employee',
                    border: OutlineInputBorder(),
                  ),
                  items: employees
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text('${e.firstName} ${e.lastName}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedEmployee = value),
                  validator: (value) =>
                      value == null ? 'Please select an employee' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _basicSalaryController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Basic Salary',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              validator: (value) => _requiredNumberValidator(value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bonusController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Bonus (optional)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              validator: (value) =>
                  _requiredNumberValidator(value, allowEmpty: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deductionsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Deductions (optional)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              validator: (value) =>
                  _requiredNumberValidator(value, allowEmpty: true),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pay Period Start'),
              subtitle: Text(
                _payPeriodStart != null
                    ? _dateFormat.format(_payPeriodStart!)
                    : 'Tap to select a date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pay Period End'),
              subtitle: Text(
                _payPeriodEnd != null
                    ? _dateFormat.format(_payPeriodEnd!)
                    : 'Tap to select a date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Pay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currencyFormat.format(_netPayPreview),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Payroll Record'),
            ),
          ],
        ),
      ),
    );
  }
}
