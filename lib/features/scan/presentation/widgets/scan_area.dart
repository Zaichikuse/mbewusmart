import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ScanArea extends StatelessWidget {
  final String? imagePath;
  final bool isAnalyzing;
  final String cropName;
  final String cropIcon;
  final VoidCallback onTap;

  const ScanArea({
    super.key,
    this.imagePath,
    this.isAnalyzing = false,
    required this.cropName,
    required this.cropIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAnalyzing ? null : onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: isAnalyzing
              ? _buildAnalyzingState()
              : imagePath != null
                  ? _buildImagePreview()
                  : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt,
            size: 48,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          cropIcon,
          style: const TextStyle(fontSize: 40),
        ),
        const SizedBox(height: 8),
        Text(
          cropName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to scan your crop',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Center(
          child: Icon(
            Icons.image,
            size: 64,
            color: AppTheme.textMuted,
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
        const SizedBox(height: 24),
        Text(
          cropIcon,
          style: const TextStyle(fontSize: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Analyzing...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please wait while we check your crop',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
