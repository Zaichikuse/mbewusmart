import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mbewu_smart/shared/widgets/error_view.dart';

void main() {
  group('ErrorView Widget Tests', () {
    testWidgets('renders with default title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders with custom title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(title: 'Custom Error'),
          ),
        ),
      );

      expect(find.text('Custom Error'), findsOneWidget);
    });

    testWidgets('renders with message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(message: 'Error message here'),
          ),
        ),
      );

      expect(find.text('Error message here'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(onRetry: () {}),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button is tapped', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(onRetry: () => retried = true),
          ),
        ),
      );

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('does not render retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(onRetry: null),
          ),
        ),
      );

      expect(find.text('Try Again'), findsNothing);
    });
  });

  group('NetworkErrorView Widget Tests', () {
    testWidgets('renders offline message when isOffline is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkErrorView(isOffline: true),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
    });

    testWidgets('renders network error message when isOffline is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkErrorView(isOffline: false),
          ),
        ),
      );

      expect(find.text('Network Error'), findsOneWidget);
    });
  });
}
