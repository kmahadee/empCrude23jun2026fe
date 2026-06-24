// lib/screens/employee/employee_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../providers/payroll_provider.dart';
import 'employee_form_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late Employee _employee;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayrollProvider>().fetchByEmployee(_employee.id!);
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete "${_employee.fullName}"?\n\n'
          'All payroll records for this employee will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<EmployeeProvider>().delete(
      _employee.id!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee deleted'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<EmployeeProvider>().errorMessage ?? 'Delete failed',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeFormScreen(employee: _employee),
      ),
    );

    if (!mounted) return;

    // Refresh local state from provider after edit
    final updated = context.read<EmployeeProvider>().getLocalById(
      _employee.id!,
    );
    if (updated != null) setState(() => _employee = updated);
  }

  @override
  Widget build(BuildContext context) {
    final payrollProvider = context.watch<PayrollProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsible photo header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: _navigateToEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                onPressed: _confirmDelete,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _employee.fullName,
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: _employee.hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: _employee.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) =>
                          _PhotoPlaceholder(employee: _employee),
                    )
                  : _PhotoPlaceholder(employee: _employee),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Department badge ───────────────────────────────────────
                  if (_employee.department != null) ...[
                    Chip(
                      avatar: const Icon(Icons.business, size: 16),
                      label: Text(_employee.department!.name),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Info card ──────────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _employee.email,
                          ),
                          if (_employee.phone != null)
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: _employee.phone!,
                            ),
                          if (_employee.jobTitle != null)
                            _InfoRow(
                              icon: Icons.work_outline,
                              label: 'Job Title',
                              value: _employee.jobTitle!,
                            ),
                          if (_employee.dateOfBirth != null)
                            _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'Date of Birth',
                              value: DateFormat(
                                'dd MMM yyyy',
                              ).format(_employee.dateOfBirth!),
                            ),
                          if (_employee.hireDate != null)
                            _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Hire Date',
                              value: DateFormat(
                                'dd MMM yyyy',
                              ).format(_employee.hireDate!),
                            ),
                          if (_employee.createdAt != null)
                            _InfoRow(
                              icon: Icons.access_time,
                              label: 'Record Created',
                              value: DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(_employee.createdAt!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Payroll history ────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Payroll History',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (!payrollProvider.isLoading)
                        Chip(
                          label: Text(
                            '${payrollProvider.payrolls.length} records',
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (payrollProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (payrollProvider.payrolls.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No payroll records yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    ...payrollProvider.payrolls.map(
                      (payroll) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.receipt_outlined),
                          ),
                          title: Text(
                            'Net Pay: \$${payroll.netPay?.toStringAsFixed(2) ?? "—"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (payroll.payPeriodStart != null &&
                                  payroll.payPeriodEnd != null)
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(payroll.payPeriodStart!)} '
                                  '→ ${DateFormat('dd MMM yyyy').format(payroll.payPeriodEnd!)}',
                                ),
                              Text(
                                'Basic: \$${payroll.basicSalary?.toStringAsFixed(2) ?? "—"}  '
                                'Bonus: \$${payroll.bonus?.toStringAsFixed(2) ?? "0.00"}  '
                                'Deductions: \$${payroll.deductions?.toStringAsFixed(2) ?? "0.00"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final Employee employee;
  const _PhotoPlaceholder({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Text(
          employee.firstName[0].toUpperCase(),
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
