// lib/providers/department_provider.dart

import 'package:flutter/foundation.dart';
import '../models/department.dart';
import '../services/department_service.dart';

class DepartmentProvider extends ChangeNotifier {
  final DepartmentService _service = DepartmentService();

  // State
  List<Department> _departments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Department> get departments => List.unmodifiable(_departments);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Private helpers ────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ─── Public methods ──────────────────────────────────────────────────────────

  // Fetch all departments from the API
  Future<void> fetchAll() async {
    _setLoading(true);
    _clearError();

    try {
      _departments = await _service.getAll();
    } catch (e) {
      _setError('Could not load departments: ${e.toString()}');
      return;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
  }

  // Create a new department and add it to the local list
  Future<bool> create(Department department) async {
    _setLoading(true);
    _clearError();

    try {
      final created = await _service.create(department);
      _departments = [..._departments, created];
    } catch (e) {
      _setError('Could not create department: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return true;
  }

  // Update an existing department and replace it in the local list
  Future<bool> update(int id, Department department) async {
    _setLoading(true);
    _clearError();

    try {
      final updated = await _service.update(id, department);
      _departments = _departments.map((d) => d.id == id ? updated : d).toList();
    } catch (e) {
      _setError('Could not update department: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return true;
  }

  // Delete a department and remove it from the local list
  Future<bool> delete(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _service.delete(id);
      _departments = _departments.where((d) => d.id != id).toList();
    } catch (e) {
      _setError('Could not delete department: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return true;
  }

  // Get a single department from the local list by id
  // Useful for pre-filling edit forms without an extra API call
  Department? getLocalById(int id) {
    try {
      return _departments.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
