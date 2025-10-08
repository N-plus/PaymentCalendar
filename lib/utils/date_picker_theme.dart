import 'package:flutter/material.dart';

Widget whiteDatePickerBuilder(BuildContext context, Widget? child) {
  if (child == null) {
    return const SizedBox.shrink();
  }

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final whiteColorScheme = colorScheme.copyWith(
    surface: Colors.white,
    background: Colors.white,
  );

  final datePickerTheme = theme.datePickerTheme.copyWith(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
  );

  return Theme(
    data: theme.copyWith(
      colorScheme: whiteColorScheme,
      datePickerTheme: datePickerTheme,
      dialogBackgroundColor: Colors.white,
    ),
    child: child,
  );
}
