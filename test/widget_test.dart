import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibok/pages/landing_page.dart';
import 'package:tibok/pages/login_page.dart';
import 'package:tibok/pages/register_page.dart';

void main() {
  group('Tibok UI & Navigation Tests', () {
    testWidgets('LandingPage renders title and actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingPage()));

      expect(find.text('Tibok'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('LoginPage renders input fields and Log In button',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
    });

    testWidgets('LoginPage shows error when submitting empty fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Enter email'), findsOneWidget);
      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('RegisterPage renders form elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
