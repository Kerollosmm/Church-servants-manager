import 'dart:ui';

import 'package:flutter/material.dart';

/// Provides custom Ochre Sanctuary design tokens not covered by [ThemeData].
@immutable
class OchreTheme extends ThemeExtension<OchreTheme> {
  /// Creates an [OchreTheme].
  const OchreTheme({
    required this.cardShadow,
    required this.buttonShadow,
    required this.blobOpacity,
    required this.headerTint,
  });

  /// Default light-mode Ochre tokens.
  static const OchreTheme light = OchreTheme(
    cardShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 32,
        offset: Offset(0, 16),
      ),
      BoxShadow(color: Color(0x0FA58255), blurRadius: 18, offset: Offset(0, 8)),
    ],
    buttonShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x33A58255),
        blurRadius: 22,
        offset: Offset(0, 10),
      ),
      BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    blobOpacity: 0.20,
    headerTint: Color(0x0DA58255),
  );

  /// Shadows used by elevated cards.
  final List<BoxShadow> cardShadow;

  /// Shadows used by emphasized buttons.
  final List<BoxShadow> buttonShadow;

  /// Opacity applied to ambient background blobs.
  final double blobOpacity;

  /// Header tint color used for nested strips.
  final Color headerTint;

  @override
  OchreTheme copyWith({
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? buttonShadow,
    double? blobOpacity,
    Color? headerTint,
  }) {
    return OchreTheme(
      cardShadow: cardShadow ?? this.cardShadow,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      blobOpacity: blobOpacity ?? this.blobOpacity,
      headerTint: headerTint ?? this.headerTint,
    );
  }

  @override
  OchreTheme lerp(ThemeExtension<OchreTheme>? other, double t) {
    if (other is! OchreTheme) {
      return this;
    }

    return OchreTheme(
      cardShadow: _lerpShadowList(cardShadow, other.cardShadow, t),
      buttonShadow: _lerpShadowList(buttonShadow, other.buttonShadow, t),
      blobOpacity: lerpDouble(blobOpacity, other.blobOpacity, t) ?? blobOpacity,
      headerTint: Color.lerp(headerTint, other.headerTint, t) ?? headerTint,
    );
  }

  static List<BoxShadow> _lerpShadowList(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    final maxLength = a.length > b.length ? a.length : b.length;

    return List<BoxShadow>.generate(maxLength, (index) {
      final start = index < a.length ? a[index] : const BoxShadow();
      final end = index < b.length ? b[index] : const BoxShadow();
      return BoxShadow.lerp(start, end, t) ?? start;
    });
  }
}
