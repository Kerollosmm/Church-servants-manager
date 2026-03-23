import 'package:cached_network_image/cached_network_image.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Displays a circular avatar with a cached image or initials fallback.
class AppAvatar extends StatelessWidget {
  /// Creates an [AppAvatar].
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 22,
  });

  /// Source name used to build fallback initials.
  final String name;

  /// Optional network image URL.
  final String? imageUrl;

  /// Radius of the circular avatar.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final content = _hasImage
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) =>
                  _FallbackAvatar(initials: _initials, radius: radius),
            ),
          )
        : _FallbackAvatar(initials: _initials, radius: radius);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    final letters = parts.map((part) => part.substring(0, 1));
    return letters.join().toUpperCase();
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initials, required this.radius});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryContainer,
      foregroundColor: AppColors.onBackground,
      child: Text(initials),
    );
  }
}
