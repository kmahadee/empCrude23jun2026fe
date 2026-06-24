import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/payroll.dart';
import '../../providers/payroll_provider.dart';
import 'payroll_form_screen.dart';

class PayrollListScreen extends StatefulWidget {
  const PayrollListScreen({super.key});

  @override
  State<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends State<PayrollListScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayrollProvider>().fetchAll();
    });
  }

  String _employeeFullName(Payroll payroll) {
    final employee = payroll.employee;
    if (employee == null) return 'Unknown employee';
    return '${employee.firstName} ${employee.lastName}';
  }

  String _payPeriodRange(Payroll payroll) {
    final start = payroll.payPeriodStart;
    final end = payroll.payPeriodEnd;
    final startLabel = start != null ? _dateFormat.format(start) : '—';
    final endLabel = end != null ? _dateFormat.format(end) : '—';
    return '$startLabel - $endLabel';
  }

  void _showBreakdown(Payroll payroll) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employeeFullName(payroll),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _payPeriodRange(payroll),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 24),
                _breakdownRow('Basic Salary', payroll.basicSalary ?? 0),
                _breakdownRow('Bonus', payroll.bonus ?? 0),
                _breakdownRow('Deductions', -(payroll.deductions ?? 0)),
                const Divider(height: 24),
                _breakdownRow(
                  'Net Pay',
                  payroll.netPay ?? payroll.computedNetPay,
                  isTotal: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _breakdownRow(String label, double amount, {bool isTotal = false}) {
    final style = isTotal
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : const TextStyle(fontSize: 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(_currencyFormat.format(amount), style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll')),
      body: Consumer<PayrollProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.payrolls.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.payrolls.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.errorMessage!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.fetchAll(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.payrolls.isEmpty) {
            return const Center(child: Text('No payroll records yet.'));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchAll,
            child: ListView.builder(
              itemCount: provider.payrolls.length,
              itemBuilder: (context, index) {
                final payroll = provider.payrolls[index];
                final netPay = payroll.netPay ?? payroll.computedNetPay;
                final processedAt = payroll.processedAt;

                return ListTile(
                  title: Text(_employeeFullName(payroll)),
                  subtitle: Text(
                    '${_payPeriodRange(payroll)}\n'
                    'Processed ${processedAt != null ? _dateFormat.format(processedAt) : '-'}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    _currencyFormat.format(netPay),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showBreakdown(payroll),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PayrollFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
