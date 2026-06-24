// lib/models/payroll.dart

import 'employee.dart';

class Payroll {
  final int? id;
  final Employee? employee;
  final double? basicSalary;
  final double? bonus;
  final double? deductions;
  final double? netPay; // computed by backend — never sent in toJson
  final DateTime? payPeriodStart;
  final DateTime? payPeriodEnd;
  final DateTime? processedAt; // set by @PrePersist — never sent in toJson

  const Payroll({
    this.id,
    this.employee,
    this.basicSalary,
    this.bonus,
    this.deductions,
    this.netPay,
    this.payPeriodStart,
    this.payPeriodEnd,
    this.processedAt,
  });

  // ─── fromJson ────────────────────────────────────────────────────────────────
  factory Payroll.fromJson(Map<String, dynamic> json) {
    return Payroll(
      id: json['id'] as int?,

      // Nested employee object — may be null in some list responses
      employee: json['employee'] != null
          ? Employee.fromJson(json['employee'] as Map<String, dynamic>)
          : null,

      // Salary fields come as num from JSON — cast to double safely
      basicSalary: (json['basicSalary'] as num?)?.toDouble(),
      bonus: (json['bonus'] as num?)?.toDouble(),
      deductions: (json['deductions'] as num?)?.toDouble(),

      // Backend-computed — read only, never written back
      netPay: (json['netPay'] as num?)?.toDouble(),

      // "yyyy-MM-dd" → DateTime
      payPeriodStart: json['payPeriodStart'] != null
          ? DateTime.tryParse(json['payPeriodStart'] as String)
          : null,
      payPeriodEnd: json['payPeriodEnd'] != null
          ? DateTime.tryParse(json['payPeriodEnd'] as String)
          : null,

      // "yyyy-MM-ddTHH:mm:ss" → DateTime — backend-set, read only
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'] as String)
          : null,
    );
  }

  // ─── toJson ──────────────────────────────────────────────────────────────────
  // Only fields the backend expects in the request body:
  //   basicSalary, bonus, deductions, payPeriodStart, payPeriodEnd
  //
  // Excluded (all backend-managed):
  //   id          → auto-generated
  //   employee    → passed as employeeId query param, not in body
  //   netPay      → computed by @PrePersist / @PreUpdate
  //   processedAt → set by @PrePersist
  Map<String, dynamic> toJson() {
    return {
      // basicSalary is required by the backend (@Column nullable = false)
      'basicSalary': basicSalary ?? 0.0,

      // bonus and deductions default to 0 if not provided
      'bonus': bonus ?? 0.0,
      'deductions': deductions ?? 0.0,

      // Dates formatted as "yyyy-MM-dd"
      if (payPeriodStart != null)
        'payPeriodStart': _formatDate(payPeriodStart!),
      if (payPeriodEnd != null) 'payPeriodEnd': _formatDate(payPeriodEnd!),
    };
  }

  // ─── copyWith ────────────────────────────────────────────────────────────────
  Payroll copyWith({
    int? id,
    Employee? employee,
    double? basicSalary,
    double? bonus,
    double? deductions,
    double? netPay,
    DateTime? payPeriodStart,
    DateTime? payPeriodEnd,
    DateTime? processedAt,
  }) {
    return Payroll(
      id: id ?? this.id,
      employee: employee ?? this.employee,
      basicSalary: basicSalary ?? this.basicSalary,
      bonus: bonus ?? this.bonus,
      deductions: deductions ?? this.deductions,
      netPay: netPay ?? this.netPay,
      payPeriodStart: payPeriodStart ?? this.payPeriodStart,
      payPeriodEnd: payPeriodEnd ?? this.payPeriodEnd,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  // Format DateTime to "yyyy-MM-dd" for API requests
  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Public helper so screens can format payroll dates
  static String formatDate(DateTime date) => _formatDate(date);

  // Local net pay preview for the form screen
  // Mirrors the backend formula: basicSalary + bonus - deductions
  double get computedNetPay {
    return (basicSalary ?? 0.0) + (bonus ?? 0.0) - (deductions ?? 0.0);
  }

  // Formatted pay period range for display e.g. "01 Jan 2026 → 31 Jan 2026"
  String get payPeriodLabel {
    if (payPeriodStart == null || payPeriodEnd == null) return 'No period set';
    return '${_formatDate(payPeriodStart!)} → ${_formatDate(payPeriodEnd!)}';
  }

  @override
  String toString() {
    return 'Payroll(id: $id, employee: ${employee?.fullName}, '
        'basicSalary: $basicSalary, bonus: $bonus, '
        'deductions: $deductions, netPay: $netPay, '
        'period: $payPeriodLabel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payroll &&
        other.id == id &&
        other.basicSalary == basicSalary &&
        other.payPeriodStart == payPeriodStart &&
        other.payPeriodEnd == payPeriodEnd;
  }

  @override
  int get hashCode =>
      Object.hash(id, basicSalary, payPeriodStart, payPeriodEnd);
}
