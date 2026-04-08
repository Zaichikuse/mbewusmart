import 'package:flutter/material.dart';

class ScanActionButtons extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final bool isChichewa;

  const ScanActionButtons({
    super.key,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    this.isChichewa = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCameraPressed,
            icon: const Icon(Icons.camera_alt),
            label: Text(isChichewa ? 'Kamera' : 'Camera'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGalleryPressed,
            icon: const Icon(Icons.photo_library),
            label: Text(isChichewa ? 'Galasi' : 'Gallery'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
