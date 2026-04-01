import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.errorRed.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorView extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool isOffline;

  const NetworkErrorView({
    super.key,
    this.onRetry,
    this.isOffline = true,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      title: isOffline ? 'No Internet Connection' : 'Network Error',
      message: isOffline
          ? 'Please check your internet connection and try again.'
          : 'Unable to connect to the server. Please try again.',
      icon: isOffline ? Icons.wifi_off : Icons.signal_cellular_connected_no_internet_4_bar,
      onRetry: onRetry,
    );
  }
}

class ServerErrorView extends StatelessWidget {
  final VoidCallback? onRetry;
  final int? statusCode;

  const ServerErrorView({
    super.key,
    this.onRetry,
    this.statusCode,
  });

  @override
  Widget build(BuildContext context) {
    String message = 'Server is busy. Please try again later.';
    if (statusCode == 500) {
      message = 'Server maintenance in progress. Please try again later.';
    } else if (statusCode == 404) {
      message = 'Resource not found.';
    } else if (statusCode != null) {
      message = 'Error code: $statusCode. Please try again.';
    }

    return ErrorView(
      title: 'Server Error',
      message: message,
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }
}
