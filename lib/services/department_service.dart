// lib/services/department_service.dart

import 'dart:convert';
import '../core/api_client.dart';
import '../models/department.dart';

class DepartmentService {
  final ApiClient _client = ApiClient();

  // GET /api/departments
  Future<List<Department>> getAll() async {
    final response = await _client.get('/departments');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Department.fromJson(e)).toList();
    }

    throw Exception(
      'Failed to load departments — status: ${response.statusCode}',
    );
  }

  // GET /api/departments/{id}
  Future<Department> getById(int id) async {
    final response = await _client.get('/departments/$id');

    if (response.statusCode == 200) {
      return Department.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 404) {
      throw Exception('Department $id not found');
    }

    throw Exception(
      'Failed to load department $id — status: ${response.statusCode}',
    );
  }

  // POST /api/departments
  // body: Department (without id)
  Future<Department> create(Department department) async {
    final response = await _client.post(
      '/departments',
      jsonEncode(department.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Department.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to create department — status: ${response.statusCode}',
    );
  }

  // PUT /api/departments/{id}
  // body: Department (without id)
  Future<Department> update(int id, Department department) async {
    final response = await _client.put(
      '/departments/$id',
      jsonEncode(department.toJson()),
    );

    if (response.statusCode == 200) {
      return Department.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 404) {
      throw Exception('Department $id not found');
    }

    throw Exception(
      'Failed to update department $id — status: ${response.statusCode}',
    );
  }

  // DELETE /api/departments/{id}
  Future<void> delete(int id) async {
    final response = await _client.delete('/departments/$id');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw Exception('Department $id not found');
    }

    throw Exception(
      'Failed to delete department $id — status: ${response.statusCode}',
    );
  }
}
