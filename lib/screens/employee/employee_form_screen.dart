// lib/screens/employee/employee_form_screen.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/employee.dart';
import '../../providers/department_provider.dart';
import '../../providers/employee_provider.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;
  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _jobTitleController;

  // State
  DateTime? _dateOfBirth;
  DateTime? _hireDate;
  Department? _selectedDepartment;
  XFile? _selectedPhoto;

  bool get _isEditMode => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _firstNameController = TextEditingController(text: e?.firstName ?? '');
    _lastNameController = TextEditingController(text: e?.lastName ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _jobTitleController = TextEditingController(text: e?.jobTitle ?? '');
    _dateOfBirth = e?.dateOfBirth;
    _hireDate = e?.hireDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deptProvider = context.read<DepartmentProvider>();
      if (deptProvider.departments.isEmpty) deptProvider.fetchAll();

      // Pre-select department in edit mode after departments are loaded
      if (_isEditMode && e?.department != null) {
        setState(() {
          _selectedDepartment = deptProvider.departments.firstWhere(
            (d) => d.id == e!.department!.id,
            orElse: () => e!.department!,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (photo != null) setState(() => _selectedPhoto = photo);
  }

  Future<void> _pickDate({required bool isBirthDate}) async {
    final now = DateTime.now();
    final initial = isBirthDate
        ? (_dateOfBirth ?? DateTime(1990))
        : (_hireDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isBirthDate ? DateTime(1940) : DateTime(2000),
      lastDate: isBirthDate ? now : DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _dateOfBirth = picked;
        } else {
          _hireDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final employeeProvider = context.read<EmployeeProvider>();

    final employee = Employee(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      jobTitle: _jobTitleController.text.trim().isEmpty
          ? null
          : _jobTitleController.text.trim(),
      dateOfBirth: _dateOfBirth,
      hireDate: _hireDate,
    );

    Employee? saved;

    if (_isEditMode) {
      final success = await employeeProvider.update(
        widget.employee!.id!,
        employee,
        departmentId: _selectedDepartment?.id,
      );
      if (success) {
        saved = employeeProvider.getLocalById(widget.employee!.id!);
      }
    } else {
      saved = await employeeProvider.create(
        employee,
        departmentId: _selectedDepartment?.id,
      );
    }

    if (!mounted) return;

    if (saved != null ||
        (_isEditMode && employeeProvider.errorMessage == null)) {
      // Upload photo after employee is saved (need the id)
      if (_selectedPhoto != null && saved?.id != null) {
        await employeeProvider.uploadPhoto(saved!.id!, _selectedPhoto!);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Employee updated successfully'
                : 'Employee created successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(employeeProvider.errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final deptProvider = context.watch<DepartmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Employee' : 'New Employee'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo picker ─────────────────────────────────────────────────
              _PhotoPickerSection(
                selectedPhoto: _selectedPhoto,
                existingPhotoUrl: _isEditMode
                    ? widget.employee?.photoUrl
                    : null,
                onPickPhoto: _pickPhoto,
              ),
              const SizedBox(height: 20),

              // ── Name row ─────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name *',
                      icon: Icons.person,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name *',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Email ────────────────────────────────────────────────────────
              _buildTextField(
                controller: _emailController,
                label: 'Email *',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Phone ────────────────────────────────────────────────────────
              _buildTextField(
                controller: _phoneController,
                label: 'Phone (optional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // ── Job title ────────────────────────────────────────────────────
              _buildTextField(
                controller: _jobTitleController,
                label: 'Job Title (optional)',
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 14),

              // ── Department dropdown ──────────────────────────────────────────
              DropdownButtonFormField<Department>(
                value: _selectedDepartment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<Department>(
                    value: null,
                    child: Text('No Department'),
                  ),
                  ...deptProvider.departments.map(
                    (d) => DropdownMenuItem<Department>(
                      value: d,
                      child: Text(d.name),
                    ),
                  ),
                ],
                onChanged: (d) => setState(() => _selectedDepartment = d),
              ),
              const SizedBox(height: 14),

              // ── Date of birth ────────────────────────────────────────────────
              _DatePickerField(
                label: 'Date of Birth',
                icon: Icons.cake_outlined,
                date: _dateOfBirth,
                onTap: () => _pickDate(isBirthDate: true),
              ),
              const SizedBox(height: 14),

              // ── Hire date ────────────────────────────────────────────────────
              _DatePickerField(
                label: 'Hire Date',
                icon: Icons.calendar_today_outlined,
                date: _hireDate,
                onTap: () => _pickDate(isBirthDate: false),
              ),
              const SizedBox(height: 28),

              // ── Submit button ────────────────────────────────────────────────
              FilledButton.icon(
                onPressed: provider.isLoading ? null : _submit,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isEditMode ? Icons.save : Icons.person_add),
                label: Text(
                  _isEditMode ? 'Save Changes' : 'Create Employee',
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

class _PhotoPickerSection extends StatelessWidget {
  final XFile? selectedPhoto;
  final String? existingPhotoUrl;
  final VoidCallback onPickPhoto;

  const _PhotoPickerSection({
    required this.selectedPhoto,
    required this.existingPhotoUrl,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          // Photo preview
          CircleAvatar(
            radius: 56,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: selectedPhoto != null
                ? FileImage(File(selectedPhoto!.path))
                : null,
            child: selectedPhoto == null
                ? (existingPhotoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: existingPhotoUrl!,
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(Icons.person, size: 48, color: Colors.grey))
                : null,
          ),
          // Edit badge
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onPickPhoto,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.icon,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          date != null ? Employee.formatDate(date!) : 'Not set',
          style: TextStyle(
            color: date != null
                ? Theme.of(context).colorScheme.onSurface
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}
