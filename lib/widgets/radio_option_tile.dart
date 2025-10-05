import 'package:flutter/material.dart';

class RadioOptionTile<T> extends StatelessWidget {
  const RadioOptionTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onSelected,
    required this.title,
    this.subtitle,
    this.contentPadding,
  });

  final T value;
  final T groupValue;
  final ValueChanged<T> onSelected;
  final Widget title;
  final Widget? subtitle;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: ListTile(
        contentPadding: contentPadding,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? colorScheme.primary : colorScheme.outline,
        ),
        selectedColor: colorScheme.primary,
        title: title,
        subtitle: subtitle,
        onTap: () => onSelected(value),
        selected: selected,
      ),
    );
  }
}
