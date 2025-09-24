import 'package:flutter/material.dart';

/// A simple value holder used by [MultiSelectDropDown].
class ValueItem<T> {
  const ValueItem({required this.value, required this.label});

  final T value;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is ValueItem<T> && other.value == value && other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// Controller for [MultiSelectDropDown] that notifies listeners when the
/// selection changes.
class MultiSelectController<T> extends ChangeNotifier {
  MultiSelectController({List<ValueItem<T>>? initialValues})
      : _selectedValues = List<ValueItem<T>>.from(initialValues ?? const []);

  List<ValueItem<T>> _selectedValues;

  /// Currently selected items.
  List<ValueItem<T>> get selectedValues => List.unmodifiable(_selectedValues);

  /// Replaces the current selection and notifies listeners.
  void setSelectedValues(List<ValueItem<T>> values) {
    _selectedValues = List<ValueItem<T>>.from(values);
    notifyListeners();
  }

  /// Adds [value] to the current selection if it is not already selected.
  void addSelectedValue(ValueItem<T> value) {
    if (_selectedValues.any((item) => item.value == value.value)) {
      return;
    }
    _selectedValues = [..._selectedValues, value];
    notifyListeners();
  }

  /// Removes [value] from the current selection if present.
  void removeSelectedValue(ValueItem<T> value) {
    final updated = _selectedValues
        .where((item) => item.value != value.value)
        .toList(growable: false);
    if (updated.length == _selectedValues.length) {
      return;
    }
    _selectedValues = updated;
    notifyListeners();
  }

  /// Clears the current selection.
  void clear() {
    if (_selectedValues.isEmpty) {
      return;
    }
    _selectedValues = const [];
    notifyListeners();
  }
}

/// A lightweight multi-select dropdown that displays the current selection as
/// chips and allows choosing items from the provided [options].
class MultiSelectDropDown<T> extends StatefulWidget {
  const MultiSelectDropDown({
    super.key,
    required this.options,
    this.controller,
    this.onOptionSelected,
    this.hint,
    this.emptyStateText,
  });

  final List<ValueItem<T>> options;
  final MultiSelectController<T>? controller;
  final ValueChanged<List<ValueItem<T>>>? onOptionSelected;
  final String? hint;
  final String? emptyStateText;

  @override
  State<MultiSelectDropDown<T>> createState() =>
      _MultiSelectDropDownState<T>();
}

class _MultiSelectDropDownState<T> extends State<MultiSelectDropDown<T>> {
  late MultiSelectController<T> _controller;
  late bool _ownsController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? MultiSelectController<T>();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(MultiSelectDropDown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final previousValues = _controller.selectedValues;
      if (_ownsController) {
        _controller.removeListener(_handleControllerChanged);
        _controller.dispose();
      } else {
        oldWidget.controller?.removeListener(_handleControllerChanged);
      }

      _ownsController = widget.controller == null;
      _controller = widget.controller ??
          MultiSelectController<T>(initialValues: previousValues);
      _controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleSelection(ValueItem<T> value) {
    final selections = _controller.selectedValues.toList(growable: true);
    final existingIndex =
        selections.indexWhere((element) => element.value == value.value);
    if (existingIndex >= 0) {
      selections.removeAt(existingIndex);
    } else {
      selections.add(value);
    }
    _controller.setSelectedValues(selections);
    widget.onOptionSelected?.call(_controller.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    final selectedValues = _controller.selectedValues;
    final hintText = widget.hint ?? '選択してください';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: hintText,
              suffixIcon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              ),
            ),
            child: selectedValues.isEmpty
                ? Text(widget.emptyStateText ?? '未選択')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedValues
                        .map(
                          (item) => Chip(
                            label: Text(item.label),
                            onDeleted: () => _toggleSelection(item),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.options
                .map(
                  (item) => FilterChip(
                    label: Text(item.label),
                    selected: selectedValues
                        .any((selected) => selected.value == item.value),
                    onSelected: (_) => _toggleSelection(item),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
