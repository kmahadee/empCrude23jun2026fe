// lib/screens/employee/employee_list_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/employee.dart';
import '../../providers/department_provider.dart';
import '../../providers/employee_provider.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  Department? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchAll();
      context.read<DepartmentProvider>().fetchAll();
    });
  }

  void _onDepartmentChanged(Department? dept) {
    setState(() => _selectedDepartment = dept);
    if (dept == null) {
      context.read<EmployeeProvider>().fetchAll();
    } else {
      context.read<EmployeeProvider>().fetchByDepartment(dept.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final departmentProvider = context.watch<DepartmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _DepartmentFilterBar(
            departments: departmentProvider.departments,
            selected: _selectedDepartment,
            onChanged: _onDepartmentChanged,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
            ).then((_) {
              if (_selectedDepartment != null) {
                context.read<EmployeeProvider>().fetchByDepartment(
                  _selectedDepartment!.id!,
                );
              } else {
                context.read<EmployeeProvider>().fetchAll();
              }
            }),
        tooltip: 'Add Employee',
        child: const Icon(Icons.person_add),
      ),
      body: _buildBody(employeeProvider),
    );
  }

  Widget _buildBody(EmployeeProvider provider) {
    if (provider.isLoading && provider.employees.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<EmployeeProvider>().fetchAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _selectedDepartment != null
                  ? 'No employees in ${_selectedDepartment!.name}'
                  : 'No employees yet.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _selectedDepartment != null
          ? context.read<EmployeeProvider>().fetchByDepartment(
              _selectedDepartment!.id!,
            )
          : context.read<EmployeeProvider>().fetchAll(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: provider.employees.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _EmployeeTile(employee: provider.employees[index]);
        },
      ),
    );
  }
}

class _DepartmentFilterBar extends StatelessWidget {
  final List<Department> departments;
  final Department? selected;
  final ValueChanged<Department?> onChanged;

  const _DepartmentFilterBar({
    required this.departments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<Department>(
        value: selected,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'All Departments',
          prefixIcon: const Icon(Icons.filter_list, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        items: [
          const DropdownMenuItem<Department>(
            value: null,
            child: Text('All Departments'),
          ),
          ...departments.map(
            (d) => DropdownMenuItem<Department>(value: d, child: Text(d.name)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final Employee employee;
  const _EmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _EmployeeAvatar(employee: employee, radius: 24),
        title: Text(
          employee.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employee.jobTitle != null)
              Text(employee.jobTitle!, style: const TextStyle(fontSize: 13)),
            if (employee.department != null)
              Chip(
                label: Text(
                  employee.department!.name,
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
          ],
        ),
        isThreeLine: employee.department != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeDetailScreen(employee: employee),
          ),
        ).then((_) => context.read<EmployeeProvider>().fetchAll()),
      ),
    );
  }
}

// Reusable avatar widget used across all employee screens
class _EmployeeAvatar extends StatelessWidget {
  final Employee employee;
  final double radius;

  const _EmployeeAvatar({required this.employee, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (employee.hasPhoto && employee.id != null) {
      return CircleAvatar(
        radius: radius,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: employee.photoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initials(context),
            errorWidget: (_, __, ___) => _initials(context),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: _initials(context),
    );
  }

  Widget _initials(BuildContext context) {
    return Text(
      employee.firstName[0].toUpperCase(),
      style: TextStyle(
        fontSize: radius * 0.75,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
