import 'package:flutter/material.dart';

class RemoteThemeModel {
  final String? primaryColor;
  final String? secondaryColor;
  final String? accentColor;
  final String? backgroundColor;
  final String? cardColor;
  final String? textColor;

  const RemoteThemeModel({
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.backgroundColor,
    this.cardColor,
    this.textColor,
  });

  static const defaults = RemoteThemeModel(
    primaryColor: '#E50914',
    secondaryColor: '#141414',
    accentColor: '#FFFFFF',
    backgroundColor: '#0A0A0A',
    cardColor: '#1A1A1A',
    textColor: '#FFFFFF',
  );

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'backgroundColor': backgroundColor,
      'cardColor': cardColor,
      'textColor': textColor,
    };
  }

  factory RemoteThemeModel.fromJson(Map<String, dynamic> json) {
    return RemoteThemeModel(
      primaryColor: _validHex(json['primaryColor']),
      secondaryColor: _validHex(json['secondaryColor']),
      accentColor: _validHex(json['accentColor']),
      backgroundColor: _validHex(json['backgroundColor']),
      cardColor: _validHex(json['cardColor']),
      textColor: _validHex(json['textColor']),
    );
  }

  ThemeData applyTo(ThemeData base) {
    final primary = parseColor(primaryColor) ?? base.colorScheme.primary;
    final background = parseColor(backgroundColor);
    final card = parseColor(cardColor);
    final text = parseColor(textColor);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: parseColor(secondaryColor) ?? base.colorScheme.secondary,
        tertiary: parseColor(accentColor) ?? base.colorScheme.tertiary,
      ),
      scaffoldBackgroundColor: background,
      cardColor: card,
      textTheme: text == null
          ? base.textTheme
          : base.textTheme.apply(bodyColor: text, displayColor: text),
    );
  }

  static Color? parseColor(String? value) {
    final valid = _validHex(value);
    if (valid == null) return null;
    return Color(int.parse('FF${valid.substring(1)}', radix: 16));
  }

  static String? _validHex(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    final regex = RegExp(r'^#[0-9a-fA-F]{6}$');
    return regex.hasMatch(trimmed) ? trimmed : null;
  }
}
