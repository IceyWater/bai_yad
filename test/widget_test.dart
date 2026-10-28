// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bai_yad/main.dart';

void main() {
  testWidgets('launch screen opens list and adds a subscription', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    expect(find.text('Vault ready. Launching...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('getStartedButton')));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL COMMITMENT'), findsOneWidget);
    expect(find.text('₱3,470'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottomNavBREAKDOWN')));
    await tester.pump();
    expect(find.text('CATEGORY BREAKDOWN'), findsOneWidget);
    expect(find.text('₱3,470'), findsOneWidget);

    await tester.tap(find.byKey(const Key('annualPeriodButton')));
    await tester.pump();
    expect(find.text('₱41,642'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
    await tester.pump();
    expect(find.byKey(const Key('subscriptionSearchField')), findsOneWidget);
    expect(find.text('Adobe Creative Cloud'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addSubscriptionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add Subscription'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('newSubscriptionNameField')),
      'Cloud Storage Plus',
    );
    await tester.enterText(
      find.byKey(const Key('newSubscriptionAmountField')),
      '299',
    );
    await tester.tap(find.byKey(const Key('saveSubscriptionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Cloud Storage Plus'), findsOneWidget);
    expect(find.text('₱299'), findsOneWidget);
  });
}
