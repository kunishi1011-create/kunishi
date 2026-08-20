import 'package:flutter/material.dart';

import 'app.dart';
import 'data/expense_repository.dart';
import 'data/hive_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★差し替え点：ここを変えるだけで保存先を切り替えられる。
  //   STEP2 = HiveRepository（端末内に永続化）
  final ExpenseRepository repository = HiveRepository();

  // 初回起動時のみテストデータを投入する。
  // 失敗しても画面は起動させ、ログイン時に再初期化を試みる。
  try {
    await repository.init();
  } catch (e) {
    debugPrint('リポジトリ初期化に失敗しました: $e');
  }

  runApp(KunishiExpenseApp(repository: repository));
}
