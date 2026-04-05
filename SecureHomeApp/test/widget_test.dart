import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securehome_app/visitor_card.dart';

void main() {
  group('VisitorCard Widget Tests', () {
    testWidgets('displays visitor name', (WidgetTester tester) async {
      final testVisitor = {
        'nom_du_visiteur': 'John Doe',
        'status': 'pending',
        'id': 1,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitorCard(
              visiteur: testVisitor,
              supabaseClient: Object() as dynamic,
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays pending status', (WidgetTester tester) async {
      final testVisitor = {
        'nom_du_visiteur': 'Jane Doe',
        'status': 'pending',
        'id': 2,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitorCard(
              visiteur: testVisitor,
              supabaseClient: Object() as dynamic,
            ),
          ),
        ),
      );

      expect(find.text('pending'), findsOneWidget);
    });

    testWidgets('displays accepted status with green icon', (
      WidgetTester tester,
    ) async {
      final testVisitor = {
        'nom_du_visiteur': 'Alice',
        'status': 'Accepter',
        'id': 3,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitorCard(
              visiteur: testVisitor,
              supabaseClient: Object() as dynamic,
            ),
          ),
        ),
      );

      expect(find.text('Accepter'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays unknown when no name provided', (
      WidgetTester tester,
    ) async {
      final testVisitor = {'status': 'pending', 'id': 4};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitorCard(
              visiteur: testVisitor,
              supabaseClient: Object() as dynamic,
            ),
          ),
        ),
      );

      expect(find.text('Inconnu'), findsOneWidget);
    });

    testWidgets('displays placeholder icon when no image', (
      WidgetTester tester,
    ) async {
      final testVisitor = {
        'nom_du_visiteur': 'Test User',
        'status': 'pending',
        'id': 5,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitorCard(
              visiteur: testVisitor,
              supabaseClient: Object() as dynamic,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays delete close button', (WidgetTester tester) async {
      final testVisitor = {
        'nom_du_visiteur': 'Test User',
        'status': 'pending',
        'id': 6,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitorCard(
              visiteur: testVisitor,
              supabaseClient: Object() as dynamic,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
