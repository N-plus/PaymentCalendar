import 'package:flutter/material.dart';

double _clampOpacity(double opacity) {
  if (opacity < 0) {
    return 0;
  }
  if (opacity > 1) {
    return 1;
  }
  return opacity;
}

extension ColorOpacityUtils on Color {
  /// Returns a copy of this color with the provided [opacity] value.
  ///
  /// This mirrors the behaviour of the deprecated [Color.withOpacity]
  /// method while avoiding the deprecation warning introduced in newer
  /// Flutter versions.
  Color withOpacityValue(double opacity) {
    final normalized = _clampOpacity(opacity);
    return Color.fromRGBO(red, green, blue, normalized);
  }
}
