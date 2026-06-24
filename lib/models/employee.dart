// lib/models/employee.dart

import 'package:my_app/core/api_client.dart';

import 'department.dart';

class Employee {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final DateTime? hireDate;
  final String? jobTitle;
  final String? photoPath; // filename only e.g. "emp_1_abc.jpg"
  final Department? department;
  final DateTime? createdAt;

  const Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.hireDate,
    this.jobTitle,
    this.photoPath,
    this.department,
    this.createdAt,
  });

  // ─── Photo URL helper ────────────────────────────────────────────────────────
  // photoPath is just a filename stored in DB.
  // The actual image is always served via the API endpoint.
  // Returns null if employee has no id yet (not saved).
  String? get photoUrl {
    if (id == null) return null;
    return '${ApiClient.baseUrl}/employees/$id/photo';
  }

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  // ─── fromJson ────────────────────────────────────────────────────────────────
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int?,

      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      jobTitle: json['jobTitle'] as String?,
      photoPath: json['photoPath'] as String?,

      // "yyyy-MM-dd" → DateTime
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,

      hireDate: json['hireDate'] != null
          ? DateTime.tryParse(json['hireDate'] as String)
          : null,

      // "yyyy-MM-ddTHH:mm:ss" → DateTime
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,

      // Nested department object
      department: json['department'] != null
          ? Department.fromJson(json['department'] as Map<String, dynamic>)
          : null,
    );
  }

  // ─── toJson ──────────────────────────────────────────────────────────────────
  // Excluded from toJson (managed by backend):
  //   - id          (auto-generated)
  //   - createdAt   (set by @PrePersist)
  //   - photoPath   (set by /photo upload endpoint separately)
  //   - department  (passed as departmentId query param, not in body)
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (jobTitle != null && jobTitle!.isNotEmpty) 'jobTitle': jobTitle,

      // Format DateTime back to "yyyy-MM-dd" for the API
      if (dateOfBirth != null) 'dateOfBirth': _formatDate(dateOfBirth!),
      if (hireDate != null) 'hireDate': _formatDate(hireDate!),
    };
  }

  // ─── copyWith ────────────────────────────────────────────────────────────────
  Employee copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    DateTime? hireDate,
    String? jobTitle,
    String? photoPath,
    Department? department,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      hireDate: hireDate ?? this.hireDate,
      jobTitle: jobTitle ?? this.jobTitle,
      photoPath: photoPath ?? this.photoPath,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  // Full display name
  String get fullName => '$firstName $lastName';

  // Format DateTime to "yyyy-MM-dd" string for API requests
  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Public helper so screens can format dates too
  static String formatDate(DateTime date) => _formatDate(date);

  @override
  String toString() {
    return 'Employee(id: $id, name: $fullName, email: $email, '
        'jobTitle: $jobTitle, department: ${department?.name}, '
        'photoPath: $photoPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, firstName, lastName, email);
}
