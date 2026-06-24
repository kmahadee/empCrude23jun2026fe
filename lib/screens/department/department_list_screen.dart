// lib/screens/department/department_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/department_provider.dart';
import '../../models/department.dart';
import 'department_form_screen.dart';
import 'department_detail_screen.dart';

class DepartmentListScreen extends StatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch on first load without rebuilding during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepartmentProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DepartmentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Departments'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DepartmentFormScreen()),
        ).then((_) => context.read<DepartmentProvider>().fetchAll()),
        tooltip: 'Add Department',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(DepartmentProvider provider) {
    // Loading state
    if (provider.isLoading && provider.departments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state with no data
    if (provider.errorMessage != null && provider.departments.isEmpty) {
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
              onPressed: () => context.read<DepartmentProvider>().fetchAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (provider.departments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No departments yet.\nTap + to create one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Department list
    return RefreshIndicator(
      onRefresh: () => context.read<DepartmentProvider>().fetchAll(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: provider.departments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final department = provider.departments[index];
          return _DepartmentTile(department: department);
        },
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  final Department department;
  const _DepartmentTile({required this.department});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            department.name[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          department.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: department.description != null
            ? Text(
                department.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const Text(
                'No description',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DepartmentDetailScreen(department: department),
          ),
        ).then((_) => context.read<DepartmentProvider>().fetchAll()),
      ),
    );
  }
}
