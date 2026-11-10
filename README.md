# IDLE ORBIT

宇宙の未開拓惑星に採掘基地を建設し、施設とロボットを強化しながら資源を自動生産する、スマートフォン向け放置型シミュレーションゲームです。

- **プラットフォーム**: Android / iOS
- **技術**: Flutter (Dart) + Flame + Material 3
- **ターゲット**: 日本市場（UIは日本語）
- **状態**: MVP 開発中（Phase 1〜3 実装済み、Phase 4 はテスト用広告ID・ストアサンドボックスで実装済み）

設計の詳細は [docs/DESIGN.md](docs/DESIGN.md) を参照してください。

## 主な機能

| 分類 | 内容 |
|---|---|
| 資源 | 鉱石 / エネルギー / 合金 / 研究ポイント |
| 施設 | 採掘・発電・精錬・研究・保管の5種類。レベル制、コストは指数的に増加、Lv10/25/50/100/200 でマイルストーン倍率 |
| ロボット | 6種類＋特典ロボット。雇用・レベルアップ、特殊能力（放置効率UP・全生産UP） |
| 惑星 | 5惑星。開拓で恒久倍率、滞在惑星ごとのボーナス、開拓演出 |
| 研究 | 生産強化・コスト削減・保管上限・放置上限延長 |
| 放置報酬 | 最大8時間（研究・課金で延長）、内訳表示、広告で2倍、時刻改ざん対策 |
| 転生 | 「星系ワープ」。永久強化（生産・放置効率・ロボット性能・初期資源） |
| 継続 | 7日周期ログインボーナス、デイリーミッション（日替わり3件）、実績（報酬は恒久生産ボーナス） |
| 収益化 | リワード広告（任意）、インタースティシャル（頻度制限付き）、アプリ内課金4商品・購入復元 |
| 演出・通知 | 効果音4種（設定でOFF可）、アプリアイコン・スプラッシュ、ローカル通知（保管庫満杯・放置上限到達、オプトイン制） |

## 開発環境

```bash
flutter pub get
```

```bash
flutter run
```

```bash
flutter analyze
```

```bash
flutter test
```

Android リリースビルド（APK / Play 提出用 AAB）:

```bash
flutter build apk --release
```

```bash
flutter build appbundle --release
```

Play に提出するには `android/key.properties` にアップロード鍵を設定してください（[android/key.properties.example](android/key.properties.example)）。未設定の場合はデバッグ鍵で署名され、端末テスト専用になります。

ブラウザ版（広告・課金・通知なし。iPhone / Android のブラウザで動作確認用）:

```bash
tool/build_web.sh
```

`build/web_publish/` に公開用のファイル一式ができます。外部サイトへの通信なしで動くよう、描画エンジン（CanvasKit）と日本語フォント（Noto Sans JP のサブセット、[tool/make_web_font.py](tool/make_web_font.py)）を同梱しています。

アイコン・効果音の再生成（Python標準ライブラリ + Pillow。素材は自作のためライセンス問題なし）:

```bash
python3 tool/make_icon.py && dart run flutter_launcher_icons && dart run flutter_native_splash:create
```

```bash
python3 tool/make_sounds.py
```

バランス調整用シミュレーター（貪欲プレイの惑星解放タイミングを出力）:

```bash
dart run tool/balance_sim.dart 24
```

## ディレクトリ構成

```
assets/config/balance.json   ゲームバランスの全数値（コードに直書きしない）
lib/
  main.dart                  起動・サービス生成
  app/                       アプリ設定（テーマ、環境、ライフサイクル）
  core/                      共通（ロガー、時計、数値フォーマット）
  game/
    config/                  balance.json の型付きモデル
    model/                   GameState・資源などのデータ構造
    engine/                  純粋なゲームロジック（Flutter非依存・テスト可能）
    game_controller.dart     実行時の状態管理（tick・保存・広告/課金の連携）
  data/                      セーブ（バージョン管理・マイグレーション・バックアップ）
  services/
    ads/                     広告の抽象化・AdMob実装・表示頻度ポリシー
    iap/                     課金の抽象化・ストア実装
    analytics/               分析の抽象化（初期版はローカルログのみ）
  flame/                     メイン画面の2Dシーン（Flame）
  features/                  各画面（基地・施設・ロボット・研究・ミッション・惑星・転生・ショップ・設定・放置報酬）
  ui/                        共通ウィジェット
test/                        ユニット・ウィジェットテスト
tool/                        バランスシミュレーター
```

## 環境設定（テスト / 本番）

| 項目 | dev（デフォルト） | prod |
|---|---|---|
| 広告ユニットID | Google公式のテストID | `--dart-define` で指定。未指定なら広告無効（テストIDへのフォールバックはしない） |
| AdMob アプリID | Google公式のテストID | Android: `-P ADMOB_APP_ID=...` / iOS: `ios/Flutter/Secrets.xcconfig` |
| 課金 | Play ライセンステスター / App Store Sandbox | 本番ストア |

設定例は [.env.example](.env.example) を参照してください。本番用のIDやキーは**コミットしないでください**（`.gitignore` 済み）。

本番ビルド例:

```bash
flutter build appbundle --dart-define-from-file=.env.prod -P ADMOB_APP_ID=ca-app-pub-xxxxxxxx~yyyyyyyy
```

## ストア商品ID

`assets/config/balance.json` の `shop.products[].storeIds` で管理しています。Play Console / App Store Connect に同じIDで商品を登録してください。表示価格は常にストアから取得し、ストアに接続できない場合は購入ボタンを無効化します（購入成功を偽装しません）。

| 商品 | Android | iOS | 仮価格 |
|---|---|---|---|
| 広告削除 | `remove_ads` | `com.idleorbit.remove_ads` | ¥480 |
| 初心者パック | `starter_pack` | `com.idleorbit.starter_pack` | ¥160 |
| 生産ブースト24時間 | `boost_24h` | `com.idleorbit.boost_24h` | ¥250 |
| プレミアムパック | `premium_pack` | `com.idleorbit.premium_pack` | ¥1,200 |

## 仮実装・未実装の明示

- **サーバー側レシート検証**: 未実装。MVPは端末内で付与（トランザクションIDで二重付与防止）。有料UA開始前に導入予定。
- **分析**: `LocalAnalyticsService`（端末ログ出力のみ・通信なし）。Firebase Analytics は `AnalyticsService` を実装して差し替える。
- **BGM**: 未作成（効果音のみ）。
- **プライバシーポリシー**: ストア公開前に作成・設定画面にリンク追加が必要。
- **Android**: リリースAPKのビルドは確認済み。実機での動作確認は未実施。
- **iOS**: ビルド未検証（macOS + Xcode が必要）。
