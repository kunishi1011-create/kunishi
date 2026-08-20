# KUNISHI経費精算（プロトタイプ）

社内向け経費精算アプリのプロトタイプです。社員が経費を申請し、管理者が承認・差し戻し・精算処理を行えます。

## 開発ステータス

| STEP | 内容 | 状態 |
|---|---|---|
| STEP1 | 画面・画面遷移（ダミーデータ） | ✅ 完了 |
| STEP2 | DB接続（永続化・認証・権限） | 未着手 |
| STEP3 | 承認・差し戻し・精算・月次集計 | ✅ STEP1で先行実装 |
| STEP4 | スマートフォン表示調整 | ✅ STEP1で先行対応 |

## 技術構成

- Flutter 3.35.4 / Dart 3.9.2（Web + Android）
- 状態管理：provider
- 日付・数値整形：intl
- ローカル永続化：hive / shared_preferences（STEP2で使用）

## テストユーザー

パスワードは全員 `password`

| メールアドレス | 氏名 | 権限 | 部門 |
|---|---|---|---|
| admin@example.com | 田中 誠 | 管理者 | 経理部 |
| employee@example.com | 山田 太郎 | 一般社員 | 営業部 |
| sato@example.com | 佐藤 花子 | 一般社員 | 営業部 |
| suzuki@example.com | 鈴木 一郎 | 一般社員 | 技術部 |
| takahashi@example.com | 高橋 美咲 | 一般社員 | 総務部 |
| ito@example.com | 伊藤 健太 | 一般社員 | 技術部 |

ダミーデータ：経費申請 26件（下書き/申請中/承認済み/差し戻し/精算済み を網羅、当月・前月にまたがる）

## 権限設計

| 操作 | 一般社員 | 管理者 |
|---|---|---|
| 自分の申請 参照 | ✔ | ✔ |
| 他人の申請 参照 | ✘ | ✔（全社） |
| 新規申請 | ✔ | ✔ |
| 編集・削除 | ✔（下書き / 差し戻し のみ） | ✘ |
| 承認・差し戻し | ✘ | ✔（申請中のみ） |
| 精算済みにする | ✘ | ✔（承認済みのみ） |
| 月次集計 | ✘ | ✔ |

差し戻し時は管理者コメントが必須です。

## ステータス遷移

```
下書き ──申請──▶ 申請中 ──承認──▶ 承認済み ──精算──▶ 精算済み
                   │  ▲
                差し戻し└──再申請──┐
                   ▼               │
                 差し戻し ──────────┘
```

## ディレクトリ構成

```
lib/
├── main.dart
├── app.dart                     # MaterialApp / ルート / テーマ / DI
├── core/
│   ├── theme.dart               # 業務用テーマ
│   ├── formatters.dart          # 金額・日付フォーマット
│   └── responsive.dart          # ブレークポイント判定
├── models/
│   ├── enums.dart               # Role / Status / Category / PaymentMethod
│   ├── app_user.dart            # users テーブル相当
│   └── expense.dart             # expenses テーブル相当
├── data/
│   ├── expense_repository.dart  # 抽象インターフェース ★差し替え点
│   ├── mock_repository.dart     # STEP1: メモリ上のダミーデータ
│   └── seed_data.dart           # 社員6名 + 申請26件
├── providers/
│   ├── auth_provider.dart
│   └── expense_provider.dart    # 一覧・絞り込み・集計
├── services/
│   └── approval_service.dart    # 承認ルール（多段階承認へ拡張可）
├── screens/
│   ├── login_screen.dart
│   ├── shell_screen.dart        # ナビゲーション枠（モバイル下部 / PC左側）
│   ├── employee/
│   │   ├── employee_dashboard.dart
│   │   ├── expense_list_screen.dart
│   │   └── expense_form_screen.dart
│   ├── admin/
│   │   ├── admin_dashboard.dart
│   │   ├── admin_list_screen.dart
│   │   └── monthly_report_screen.dart
│   ├── expense_detail_screen.dart
│   └── profile_screen.dart
└── widgets/
    ├── status_chip.dart         # 色＋文字＋アイコンで状態表示
    ├── stat_card.dart
    ├── expense_list_tile.dart
    └── filter_bar.dart
```

## 将来機能の拡張ポイント

| 将来機能 | 拡張箇所 |
|---|---|
| 領収書OCR | `expense_form_screen.dart` の `_ReceiptPicker` |
| スマホ撮影による領収書登録 | 同上（`image_picker` を追加） |
| 会計ソフト連携 / 銀行振込データ | `services/` に Export サービスを追加 |
| インボイス制度対応 | `Expense.taxRate` / `invoiceNumber` を利用 |
| 多段階承認 | `services/approval_service.dart` に承認ステップを追加 |
| 部門別予算管理 | `Expense.department` を基準に集計を追加 |
| DB差し替え（Supabase等） | `data/expense_repository.dart` の実装クラスを追加 |

## 実行方法

```bash
flutter pub get
flutter run -d chrome     # Web
flutter build web --release
```

## 注意事項

- APIキー・パスワードはソースコードに直接記載せず、環境変数を使用します（`.env` は `.gitignore` 済み）
- STEP1 のデータはメモリ上のみのため、リロードで初期状態に戻ります
