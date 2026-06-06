import 'package:flutter/material.dart';

class MapMarkerWidget extends StatefulWidget {
  final String severity;
  final VoidCallback? onTap;

  const MapMarkerWidget({super.key, required this.severity, this.onTap});

  static Color dotColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFC62828);
      case 'medium':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  static double dotSize(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return 16;
      case 'medium':
        return 14;
      default:
        return 12;
    }
  }

  static double pulseSize(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return 32;
      case 'medium':
        return 28;
      default:
        return 24;
    }
  }

  @override
  State<MapMarkerWidget> createState() => _MapMarkerWidgetState();
}

class _MapMarkerWidgetState extends State<MapMarkerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = MapMarkerWidget.dotColor(widget.severity);
    final dotSize = MapMarkerWidget.dotSize(widget.severity);
    final pulseSize = MapMarkerWidget.pulseSize(widget.severity);

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: pulseSize,
        height: pulseSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 0.85 + (_pulseController.value * 0.35);
                final opacity = 0.4 * (1 - _pulseController.value);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: pulseSize,
                    height: pulseSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: opacity),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.grass,
                size: dotSize * 0.55,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
