import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/state/sorade_controller.dart';

/// Pushed routes are siblings of [home] under the navigator, so they do not
/// inherit [ChangeNotifierProvider] from inside [ShellScreen]. Wrap the child
/// with the same [SoradeController] instance.
MaterialPageRoute<void> soradeMaterialPageRoute(
  BuildContext context,
  Widget child,
) {
  final c = context.read<SoradeController>();
  return MaterialPageRoute<void>(
    builder: (_) => ChangeNotifierProvider<SoradeController>.value(
      value: c,
      child: child,
    ),
  );
}
