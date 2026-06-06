import 'package:flutter/material.dart';

class ZoomControlsWidget extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const ZoomControlsWidget({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  static const Color _managerGreen = Color(0xFF2E5D2E);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(icon: Icons.add, onPressed: onZoomIn),
        const SizedBox(height: 8),
        _ZoomButton(icon: Icons.remove, onPressed: onZoomOut),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: ZoomControlsWidget._managerGreen, size: 22),
        ),
      ),
    );
  }
}
