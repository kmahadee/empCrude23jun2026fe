// lib/providers/payroll_provider.dart

import 'package:flutter/foundation.dart';
import '../models/payroll.dart';
import '../services/payroll_service.dart';

class PayrollProvider extends ChangeNotifier {
  final PayrollService _service = PayrollService();

  // ─── State ───────────────────────────────────────────────────────────────────
  List<Payroll> _payrolls = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Tracks whether the current list is filtered by employee
  // null = showing all payrolls
  int? _currentEmployeeFilter;

  // ─── Getters ─────────────────────────────────────────────────────────────────
  List<Payroll> get payrolls => List.unmodifiable(_payrolls);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentEmployeeFilter => _currentEmployeeFilter;
  bool get isFiltered => _currentEmployeeFilter != null;

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
  // Fetches all payroll records and clears any employee filter
  Future<void> fetchAll() async {
    _setLoading(true);
    _clearError();
    _currentEmployeeFilter = null;

    try {
      _payrolls = await _service.getAll();
    } catch (e) {
      _setError('Could not load payrolls: ${e.toString()}');
      return;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
  }

  // ─── fetchByEmployee ─────────────────────────────────────────────────────────
  // Replaces the payroll list with only records for the given employee
  Future<void> fetchByEmployee(int employeeId) async {
    _setLoading(true);
    _clearError();
    _currentEmployeeFilter = employeeId;

    try {
      // Replaces list entirely — does not append
      _payrolls = await _service.getByEmployee(employeeId);
    } catch (e) {
      _setError(
        'Could not load payrolls for employee $employeeId: '
        '${e.toString()}',
      );
      return;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
  }

  // ─── create ──────────────────────────────────────────────────────────────────
  // Creates a new payroll record and appends it to the local list
  // Returns the created Payroll on success, null on failure
  Future<Payroll?> create(Payroll payroll, int employeeId) async {
    _setLoading(true);
    _clearError();

    Payroll? created;

    try {
      created = await _service.create(payroll, employeeId);

      // Only add to local list if not filtered, or if it matches the filter
      if (_currentEmployeeFilter == null ||
          _currentEmployeeFilter == employeeId) {
        _payrolls = [..._payrolls, created];
      }
    } catch (e) {
      _setError('Could not create payroll: ${e.toString()}');
      return null;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return created;
  }

  // ─── delete ──────────────────────────────────────────────────────────────────
  // Deletes a payroll record and removes it from the local list
  Future<bool> delete(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _service.delete(id);

      // Remove only the matching record — no full re-fetch
      _payrolls = _payrolls.where((p) => p.id != id).toList();
    } catch (e) {
      _setError('Could not delete payroll: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
    }

    notifyListeners();
    return true;
  }

  // ─── Utility ─────────────────────────────────────────────────────────────────

  // Get a single payroll from the local list by id
  Payroll? getLocalById(int id) {
    try {
      return _payrolls.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Total net pay across all payrolls currently in the list
  // Useful for summary cards on the payroll list screen
  double get totalNetPay {
    return _payrolls.fold(0.0, (sum, p) => sum + (p.netPay ?? 0.0));
  }

  // Clear the employee filter and reload all payrolls
  Future<void> clearFilter() async {
    await fetchAll();
  }
}
