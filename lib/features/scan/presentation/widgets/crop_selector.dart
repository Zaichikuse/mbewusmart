import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../diagnosis/domain/entities/crop_type.dart';

class CropSelector extends StatefulWidget {
  final String title;
  final CropType selectedCrop;
  final ValueChanged<CropType> onCropSelected;

  const CropSelector({
    super.key,
    this.title = 'Select Crop',
    required this.selectedCrop,
    required this.onCropSelected,
  });

  @override
  State<CropSelector> createState() => _CropSelectorState();
}

class _CropSelectorState extends State<CropSelector> {
  Stream<int> _weeklyCount(String crop) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return FirebaseFirestore.instance
        .collection('reports')
        .where('crop', isEqualTo: crop)
        .orderBy('created_at', descending: true)
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: AppTextStyles.headingSmall),
        const SizedBox(height: 12),
        Row(
          children: CropType.values.map((crop) {
            final index = CropType.values.indexOf(crop);
            return Expanded(
              child: _AnimatedCropCard(
                index: index,
                crop: crop,
                isSelected: crop == widget.selectedCrop,
                onTap: () => widget.onCropSelected(crop),
                weeklyCountStream: _weeklyCount(crop.name),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AnimatedCropCard extends StatefulWidget {
  final int index;
  final CropType crop;
  final bool isSelected;
  final VoidCallback onTap;
  final Stream<int> weeklyCountStream;

  const _AnimatedCropCard({
    required this.index,
    required this.crop,
    required this.isSelected,
    required this.onTap,
    required this.weeklyCountStream,
  });

  @override
  State<_AnimatedCropCard> createState() => _AnimatedCropCardState();
}

class _AnimatedCropCardState extends State<_AnimatedCropCard> {
  late Timer _tipTimer;
  int _tipIndex = 0;

  static const maizeTips = [
    'Fall armyworm is most active at dusk — scout in the evening.',
    'Yellowing lower leaves often mean nitrogen deficiency.',
    'Scout fields every 3 days during tasseling.',
  ];
  static const cassavaTips = [
    'Mosaic virus spreads through cuttings — use clean planting material.',
    'Check the undersides of leaves for mealybugs weekly.',
    'Brown streak shows as yellow patches on older leaves.',
  ];
  static const tomatoTips = [
    'Late blight thrives in cool, humid weather — scout after rain.',
    'Yellow leaves curling upward can signal whitefly damage.',
    'Blossom-end rot is calcium deficiency, not a disease.',
  ];

  List<String> get _tips {
    switch (widget.crop) {
      case CropType.maize:
        return maizeTips;
      case CropType.cassava:
        return cassavaTips;
      case CropType.tomato:
        return tomatoTips;
    }
  }

  @override
  void initState() {
    super.initState();
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      }
    });
  }

  @override
  void dispose() {
    _tipTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFFF6B35);
    final lightGreenBg = const Color(0xFFE8F5E9);
    final darkGreen = const Color(0xFF2E7D32);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          StreamBuilder<int>(
            stream: widget.weeklyCountStream,
            initialData: 0,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              final card = Pressable(
                onTap: widget.onTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isSelected
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade300,
                          width: widget.isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.crop.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.crop.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: widget.isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: count > 0
                          ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: orange,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: orange.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '🔥 $count new this week',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) {
                                    controller.repeat(reverse: true);
                                  },
                                )
                                .scaleXY(
                                  begin: 1.0,
                                  end: 1.04,
                                  duration: 1200.ms,
                                  curve: Curves.easeInOut,
                                )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: lightGreenBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '✓ All clear',
                                style: TextStyle(
                                  color: darkGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );

              return KeyedSubtree(
                key: ValueKey('${widget.crop.name}-$count'),
                child: card
                    .animate(delay: (widget.index * 150).ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOut)
                    .then(delay: (400 + widget.index * 200).ms)
                    .shake(hz: 4, duration: 600.ms, offset: const Offset(2, 0)),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 18,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                _tips[_tipIndex],
                key: ValueKey<int>(_tipIndex),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
