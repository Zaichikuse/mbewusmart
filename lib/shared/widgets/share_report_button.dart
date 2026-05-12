import 'package:flutter/material.dart';

/// Reusable WhatsApp-green share button used across all role screens.
/// Shows a spinner while the PDF is being generated, then disables itself
/// until the share sheet returns.
class ShareReportButton extends StatefulWidget {
  final Future<void> Function() onShare;
  final String label;
  final IconData icon;
  final bool fullWidth;

  const ShareReportButton({
    super.key,
    required this.onShare,
    this.label = 'Share Report',
    this.icon = Icons.share,
    this.fullWidth = true,
  });

  @override
  State<ShareReportButton> createState() => _ShareReportButtonState();
}

class _ShareReportButtonState extends State<ShareReportButton> {
  bool _busy = false;

  Future<void> _handlePress() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onShare();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share report: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton.icon(
      onPressed: _busy ? null : _handlePress,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(widget.icon),
      label: Text(_busy ? 'Preparing…' : widget.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
