// lib/services/employee_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/api_client.dart';
import '../models/employee.dart';

class EmployeeService {
  final ApiClient _client = ApiClient();

  // ─── GET /api/employees ──────────────────────────────────────────────────────
  Future<List<Employee>> getAll() async {
    final response = await _client.get('/employees');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Employee.fromJson(e)).toList();
    }

    throw Exception(
      'Failed to load employees — status: ${response.statusCode}',
    );
  }

  // ─── GET /api/employees/{id} ─────────────────────────────────────────────────
  Future<Employee> getById(int id) async {
    final response = await _client.get('/employees/$id');

    if (response.statusCode == 200) {
      return Employee.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 404) {
      throw Exception('Employee $id not found');
    }

    throw Exception(
      'Failed to load employee $id — status: ${response.statusCode}',
    );
  }

  // ─── GET /api/employees/department/{departmentId} ────────────────────────────
  Future<List<Employee>> getByDepartment(int departmentId) async {
    final response = await _client.get('/employees/department/$departmentId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Employee.fromJson(e)).toList();
    }

    throw Exception(
      'Failed to load employees for department $departmentId '
      '— status: ${response.statusCode}',
    );
  }

  // ─── POST /api/employees?departmentId={id} ───────────────────────────────────
  // departmentId is optional — pass null if no department assigned
  Future<Employee> create(Employee employee, {int? departmentId}) async {
    final queryParams = departmentId != null
        ? {'departmentId': departmentId.toString()}
        : null;

    final response = await _client.post(
      '/employees',
      jsonEncode(employee.toJson()),
      queryParams,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Employee.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to create employee — status: ${response.statusCode}',
    );
  }

  // ─── PUT /api/employees/{id}?departmentId={id} ───────────────────────────────
  // departmentId is optional — pass null to leave department unchanged
  Future<Employee> update(
    int id,
    Employee employee, {
    int? departmentId,
  }) async {
    final queryParams = departmentId != null
        ? {'departmentId': departmentId.toString()}
        : null;

    final response = await _client.put(
      '/employees/$id',
      jsonEncode(employee.toJson()),
      queryParams,
    );

    if (response.statusCode == 200) {
      return Employee.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 404) {
      throw Exception('Employee $id not found');
    }

    throw Exception(
      'Failed to update employee $id — status: ${response.statusCode}',
    );
  }

  // ─── DELETE /api/employees/{id} ──────────────────────────────────────────────
  Future<void> delete(int id) async {
    final response = await _client.delete('/employees/$id');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw Exception('Employee $id not found');
    }

    throw Exception(
      'Failed to delete employee $id — status: ${response.statusCode}',
    );
  }

  // ─── POST /api/employees/{id}/photo ─────────────────────────────────────────
  // Uploads photo as multipart/form-data with field name "file"
  // Returns the photo URL string on success

  Future<String> uploadPhoto(int employeeId, XFile photo) async {
    final uri = ApiClient.buildUri('/employees/$employeeId/photo');

    final bytes = await photo.readAsBytes(); // works on web, mobile, desktop

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Accept': 'application/json'})
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: photo.name),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body.trim();
    }

    throw Exception(
      'Failed to upload photo for employee $employeeId '
      '— status: ${response.statusCode}',
    );
  }

  // Future<String> uploadPhoto(int employeeId, XFile photo) async {
  //   final uri = ApiClient.buildUri('/employees/$employeeId/photo');

  //   final request = http.MultipartRequest('POST', uri)
  //     ..headers.addAll({'Accept': 'application/json'})
  //     ..files.add(
  //       await http.MultipartFile.fromPath(
  //         'file',
  //         photo.path,
  //         filename: photo.name,
  //       ),
  //     );

  //   final streamedResponse = await request.send();
  //   final response = await http.Response.fromStream(streamedResponse);

  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     // Backend returns the saved filename as a plain-text body — use it
  //     // directly instead of reconstructing a generic URL.
  //     return response.body.trim();
  //   }

  //   throw Exception(
  //     'Failed to upload photo for employee $employeeId '
  //     '— status: ${response.statusCode}',
  //   );
  // }

  // Future<String> uploadPhoto(int employeeId, XFile photo) async {
  //   final uri = ApiClient.buildUri('/employees/$employeeId/photo');

  //   final request = http.MultipartRequest('POST', uri)
  //     ..headers.addAll({'Accept': 'application/json'})
  //     ..files.add(
  //       await http.MultipartFile.fromPath(
  //         'file', // must match @RequestParam("file") in Spring
  //         photo.path,
  //         filename: photo.name,
  //       ),
  //     );

  //   final streamedResponse = await request.send();
  //   final response = await http.Response.fromStream(streamedResponse);

  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     // Return the URL to fetch the photo — never return raw bytes
  //     return getPhotoUrl(employeeId);
  //   }

  //   throw Exception(
  //     'Failed to upload photo for employee $employeeId '
  //     '— status: ${response.statusCode}',
  //   );
  // }

  // ─── GET /api/employees/{id}/photo (URL only) ────────────────────────────────
  // Does NOT make an HTTP call — just constructs and returns the URL string.
  // Use this URL directly in CachedNetworkImage or Image.network in the UI.
  String getPhotoUrl(int employeeId) {
    return '${ApiClient.baseUrl}/employees/$employeeId/photo';
  }
}
