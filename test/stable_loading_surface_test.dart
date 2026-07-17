import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/widgets/stable_loading_surface.dart';

void main() {
  testWidgets('keeps child geometry mounted while loading state changes',
      (tester) async {
    const childKey = ValueKey<String>('stable-child');

    Future<void> pumpSurface({required bool loading}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StableLoadingSurface(
              isLoading: loading,
              hasData: false,
              child: const SizedBox(
                key: childKey,
                width: 240,
                height: 120,
              ),
            ),
          ),
        ),
      );
    }

    await pumpSurface(loading: true);
    final loadingSize = tester.getSize(find.byKey(childKey));

    await pumpSurface(loading: false);
    await tester.pump(const Duration(milliseconds: 300));
    final readySize = tester.getSize(find.byKey(childKey));

    expect(find.byKey(childKey), findsOneWidget);
    expect(readySize, loadingSize);
    expect(readySize, const Size(240, 120));
  });
}
