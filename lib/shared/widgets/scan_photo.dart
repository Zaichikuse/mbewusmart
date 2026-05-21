import 'package:flutter/material.dart';

import '../utils/image_encoder.dart';

class ScanPhoto extends StatelessWidget {
  final String? base64Photo;
  final String? legacyUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const ScanPhoto({
    super.key,
    this.base64Photo,
    this.legacyUrl,
    this.width = double.infinity,
    this.height = 240,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final base64 = base64Photo?.replaceAll(RegExp(r'\s+'), '').trim() ?? '';
    final legacy = legacyUrl?.trim() ?? '';

    Widget child;
    if (base64.isNotEmpty) {
      final bytes = ImageEncoder.decodeFromFirestore(base64);
      child = bytes == null
          ? _buildPlaceholder(context, message: 'Image unavailable')
          : Image.memory(
              bytes,
              width: width,
              height: height,
              fit: fit,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(context, message: 'Image unavailable'),
            );
    } else if (legacy.isNotEmpty) {
      child = Image.network(
        legacy,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder(context, loading: true);
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(context, message: 'Image unavailable'),
      );
    } else {
      child = _buildPlaceholder(context);
    }

    return ClipRRect(borderRadius: borderRadius, child: child);
  }

  Widget _buildPlaceholder(
    BuildContext context, {
    bool loading = false,
    String message = 'No image',
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.green.shade50,
      child: Center(
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco_outlined, size: 40, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
