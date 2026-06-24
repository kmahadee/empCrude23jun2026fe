// lib/providers/employee_provider.dart

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeService _service = EmployeeService();

  // ─── State ───────────────────────────────────────────────────────────────────
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Tracks whether the current list is filtered by department
  // null = showing all employees
  int? _currentDepartmentFilter;

  // ─── Getters ─────────────────────────────────────────────────────────────────
  List<Employee> get employees => List.unmodifiable(_employees);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentDepartmentFilter => _currentDepartmentFilter;
  bool get isFiltered => _currentDepartmentFilter != null;

  // ─── Private helpers ─────────────────────────────────────────────────────────

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

  // ─── fetchAll ────────────────────────────────────────────────────────────────
  // Fetches all employees and clears any department filter
  Future<void> fetchAll() async {
    _setLoading(true);
    _clearError();
    _currentDepartmentFilter = null;

    try {
      _employees = await _service.getAll();
    } catch (e) {
      _setError('Could not load employees: ${e.toString()}');
      return;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
  }

  // ─── fetchByDepartment ───────────────────────────────────────────────────────
  // Replaces the employee list with only employees from the given department
  Future<void> fetchByDepartment(int departmentId) async {
    _setLoading(true);
    _clearError();
    _currentDepartmentFilter = departmentId;

    try {
      // Replaces list entirely — does not append
      _employees = await _service.getByDepartment(departmentId);
    } catch (e) {
      _setError(
        'Could not load employees for department $departmentId: '
        '${e.toString()}',
      );
      return;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
  }

  // ─── create ──────────────────────────────────────────────────────────────────
  // Creates a new employee and appends it to the local list
  // Returns the created Employee on success, null on failure
  Future<Employee?> create(Employee employee, {int? departmentId}) async {
    _setLoading(true);
    _clearError();

    Employee? created;

    try {
      created = await _service.create(employee, departmentId: departmentId);

      // Only add to local list if not filtered, or if it matches filter
      if (_currentDepartmentFilter == null ||
          _currentDepartmentFilter == departmentId) {
        _employees = [..._employees, created];
      }
    } catch (e) {
      _setError('Could not create employee: ${e.toString()}');
      return null;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return created;
  }

  // ─── update ──────────────────────────────────────────────────────────────────
  // Updates an employee and replaces it in the local list
  Future<bool> update(int id, Employee employee, {int? departmentId}) async {
    _setLoading(true);
    _clearError();

    try {
      final updated = await _service.update(
        id,
        employee,
        departmentId: departmentId,
      );

      // Replace only the matching employee in the list
      _employees = _employees.map((e) => e.id == id ? updated : e).toList();
    } catch (e) {
      _setError('Could not update employee: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return true;
  }

  // ─── delete ──────────────────────────────────────────────────────────────────
  // Deletes an employee and removes it from the local list
  Future<bool> delete(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _service.delete(id);

      // Remove only the matching employee — no full re-fetch
      _employees = _employees.where((e) => e.id != id).toList();
    } catch (e) {
      _setError('Could not delete employee: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return true;
  }

  // ─── uploadPhoto ─────────────────────────────────────────────────────────────
  // Uploads a photo for an employee via multipart form
  // Updates the local employee's photoPath on success
  // Returns the photo URL string on success, null on failure

  Future<String?> uploadPhoto(int employeeId, XFile photo) async {
    _setLoading(true);
    _clearError();

    String? filename;

    try {
      // This is now the real server-generated filename, e.g. "emp_1_<uuid>.jpg"
      filename = await _service.uploadPhoto(employeeId, photo);

      _employees = _employees.map((e) {
        if (e.id == employeeId) {
          return e.copyWith(photoPath: filename);
        }
        return e;
      }).toList();
    } catch (e) {
      _setError('Could not upload photo: ${e.toString()}');
      return null;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return filename != null ? _service.getPhotoUrl(employeeId) : null;
  }

  // Future<String?> uploadPhoto(int employeeId, XFile photo) async {
  //   _setLoading(true);
  //   _clearError();

  //   String? photoUrl;

  //   try {
  //     photoUrl = await _service.uploadPhoto(employeeId, photo);

  //     // Update the photoPath on the local employee object so UI refreshes
  //     // without needing a full re-fetch
  //     _employees = _employees.map((e) {
  //       if (e.id == employeeId) {
  //         // Extract filename from URL for local photoPath
  //         return e.copyWith(photoPath: photo.name);
  //       }
  //       return e;
  //     }).toList();
  //   } catch (e) {
  //     _setError('Could not upload photo: ${e.toString()}');
  //     return null;
  //   } finally {
  //     _isLoading = false;
  //   }

  //   notifyListeners();
  //   return photoUrl;
  // }

  // ─── Utility ─────────────────────────────────────────────────────────────────

  // Get a single employee from the local list by id
  // Useful for pre-filling edit forms without an extra API call
  Employee? getLocalById(int id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Clear the department filter and reload all employees
  Future<void> clearFilter() async {
    await fetchAll();
  }

  // Get photo URL for an employee without making an HTTP call
  String getPhotoUrl(int employeeId) {
    return _service.getPhotoUrl(employeeId);
  }
}
