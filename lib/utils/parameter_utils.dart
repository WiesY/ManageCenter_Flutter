import 'package:flutter/material.dart';
import 'package:manage_center/constants/app_colors.dart';

class ParameterUtils {
  static String formatValue(String displayValue, String valueType) {
    final type = valueType.toLowerCase();
    if (type == 'int' ||
        type == 'integer' ||
        type == 'long' ||
        type == 'short' ||
        type == 'byte') {
      final parsed = double.tryParse(displayValue);
      if (parsed != null) return parsed.toInt().toString();
    }
    return displayValue;
  }

  static String translateParameterType(String valueType) {
    return switch (valueType.toLowerCase()) {
      'float' || 'double' => 'дробное',
      'int' || 'integer' => 'целое',
      'bool' || 'boolean' => 'логическое',
      'string' || 'text' => 'текстовое',
      'byte' => 'байт',
      'decimal' => 'десятичное',
      'long' => 'длинное целое',
      'short' => 'короткое целое',
      _ => valueType,
    };
  }

  static Color parseGroupColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        final hexColor = colorString.substring(1, 7);
        return Color(int.parse(hexColor, radix: 16) + 0xFF000000);
      }
      return AppColors.textSecondary;
    } catch (e) {
      return AppColors.textSecondary;
    }
  }
}