// lib/services/payroll_service.dart

import 'dart:convert';
import '../core/api_client.dart';
import '../models/payroll.dart';

class PayrollService {
  final ApiClient _client = ApiClient();

  // ─── GET /api/payrolls ───────────────────────────────────────────────────────
  Future<List<Payroll>> getAll() async {
    final response = await _client.get('/payrolls');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Payroll.fromJson(e)).toList();
    }

    throw Exception('Failed to load payrolls — status: ${response.statusCode}');
  }

  // ─── GET /api/payrolls/{id} ──────────────────────────────────────────────────
  Future<Payroll> getById(int id) async {
    final response = await _client.get('/payrolls/$id');

    if (response.statusCode == 200) {
      return Payroll.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 404) {
      throw Exception('Payroll record $id not found');
    }

    throw Exception(
      'Failed to load payroll $id — status: ${response.statusCode}',
    );
  }

  // ─── GET /api/payrolls/employee/{employeeId} ─────────────────────────────────
  Future<List<Payroll>> getByEmployee(int employeeId) async {
    final response = await _client.get('/payrolls/employee/$employeeId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Payroll.fromJson(e)).toList();
    }

    throw Exception(
      'Failed to load payrolls for employee $employeeId '
      '— status: ${response.statusCode}',
    );
  }

  // ─── POST /api/payrolls?employeeId={id} ──────────────────────────────────────
  // employeeId is REQUIRED as a query param — not in the request body
  // body contains: basicSalary, bonus, deductions, payPeriodStart, payPeriodEnd
  Future<Payroll> create(Payroll payroll, int employeeId) async {
    final response = await _client.post(
      '/payrolls',
      jsonEncode(payroll.toJson()),
      {'employeeId': employeeId.toString()}, // required query param
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Payroll.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to create payroll for employee $employeeId '
      '— status: ${response.statusCode}',
    );
  }

  // ─── DELETE /api/payrolls/{id} ───────────────────────────────────────────────
  Future<void> delete(int id) async {
    final response = await _client.delete('/payrolls/$id');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw Exception('Payroll record $id not found');
    }

    throw Exception(
      'Failed to delete payroll $id — status: ${response.statusCode}',
    );
  }
}
