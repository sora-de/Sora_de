import 'package:flutter/foundation.dart';

@immutable
class UserRole {
  const UserRole({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String role; // "admin" or "staff"
  final DateTime createdAt;
  final bool isActive;

  UserRole copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserRole(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
}
