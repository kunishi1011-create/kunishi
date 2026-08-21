import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 真因実証テスト:
/// bottomNavigationBar の中で Center(=CenteredContent) を使うと、
/// bottom bar が画面全高まで拡張され body の高さが 0 になる。
/// その結果 ListView / SingleChildScrollView は子を 1 つも build しない。
void main() {
  const size = Size(390, 844);

  Widget wrap(Widget child) => MediaQuery(
        data: const MediaQueryData(size: size),
        child: MaterialApp(home: child),
      );

  testWidgets('再現: bottomNavigationBar 内の Center が body を高さ0にする',
      (tester) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final bodyKey = GlobalKey();
    final barKey = GlobalKey();

    await tester.pumpWidget(wrap(Scaffold(
      appBar: AppBar(title: const Text('新規経費申請')),
      body: SafeArea(
        child: ListView(
          key: bodyKey,
          children: const [Text('利用日')],
        ),
      ),
      bottomNavigationBar: Container(
        key: barKey,
        color: Colors.white,
        child: SafeArea(
          // ← 犯人: maxHeight 有界だと Center は最大まで広がる
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(children: const [Text('下書き保存'), Text('申請する')]),
            ),
          ),
        ),
      ),
    )));

    final barH = tester.getSize(find.byKey(barKey)).height;
    final bodyH = tester.getSize(find.byKey(bodyKey)).height;

    debugPrint('BUG   -> bar=$barH body=$bodyH');
    expect(barH, greaterThan(700), reason: 'bottom bar が画面全高を占有する');
    expect(bodyH, 0.0, reason: 'body の高さが 0 になる');
    // 高さ0のビューポートでは子が build されない = 白画面の正体
    expect(find.text('利用日'), findsNothing);
  });

  testWidgets('修正後: Center を外すと body が高さを取り戻し子が build される',
      (tester) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final bodyKey = GlobalKey();
    final barKey = GlobalKey();

    await tester.pumpWidget(wrap(Scaffold(
      appBar: AppBar(title: const Text('新規経費申請')),
      body: SafeArea(
        child: ListView(
          key: bodyKey,
          children: const [Text('利用日')],
        ),
      ),
      bottomNavigationBar: Container(
        key: barKey,
        color: Colors.white,
        child: SafeArea(
          // ✅ Center を使わず Align + widthFactor で横方向のみ中央寄せ
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(children: const [Text('下書き保存'), Text('申請する')]),
            ),
          ),
        ),
      ),
    )));

    final barH = tester.getSize(find.byKey(barKey)).height;
    final bodyH = tester.getSize(find.byKey(bodyKey)).height;

    debugPrint('FIXED -> bar=$barH body=$bodyH');
    expect(barH, lessThan(200), reason: 'bottom bar は中身の高さに収まる');
    expect(bodyH, greaterThan(500), reason: 'body が高さを取り戻す');
    expect(find.text('利用日'), findsOneWidget);
  });
}
