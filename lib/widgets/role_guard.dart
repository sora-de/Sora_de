import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/state/sorade_controller.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final List<String> allowedRoles;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SoradeController>();
    final role = controller.currentUserRole?.role ?? 'staff'; // Default to staff if unknown

    if (allowedRoles.contains(role)) {
      return child;
    }
    return fallback;
  }
}
