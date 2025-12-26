# FP予約システム

ファイナンシャルプランナー（FP）との相談予約を管理するWebアプリケーションです。

## 機能

- **ユーザー管理**: 一般ユーザーとFPユーザーの2種類のロール
- **予約枠管理**: FPが予約可能な時間枠を設定
- **予約機能**: 一般ユーザーがFPの空き枠を予約
- **予約承認**: FPが予約リクエストを承認/拒否

## 必要な環境

- Ruby 3.4.5
- Rails 8.1.1
- MySQL 8.0以上
- Node.js（アセットコンパイル用）

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/hirano-kazuma/fptask.git
cd fptask
```

### 2. Rubyのインストール

rbenvを使用している場合：

```bash
rbenv install 3.4.5
rbenv local 3.4.5
```

### 3. 依存パッケージのインストール

```bash
bundle install
```

### 4. データベースの設定

`config/database.yml`を環境に合わせて編集するか、環境変数を設定してください。

```bash
# データベースの作成とマイグレーション
rails db:create
rails db:migrate
```

### 5. シードデータの投入（任意）

```bash
rails db:seed
```

## アプリケーションの起動

```bash
rails server
```

ブラウザで http://localhost:3000 にアクセス

## テストの実行

```bash
# 全テストを実行
bundle exec rspec

# 特定のテストファイルを実行
bundle exec rspec spec/models/booking_spec.rb
bundle exec rspec spec/requests/bookings_spec.rb
```

## コード品質チェック

```bash
# Rubocopによるコードスタイルチェック
bundle exec rubocop

# Brakemanによるセキュリティチェック
bin/brakeman --no-pager
```

## 主要なディレクトリ構成

```
app/
├── controllers/
│   ├── bookings_controller.rb      # 予約管理
│   ├── time_slots_controller.rb    # 予約枠管理
│   └── bookings/
│       ├── confirms_controller.rb  # 予約承認
│       └── rejects_controller.rb   # 予約拒否
├── models/
│   ├── booking.rb                  # 予約モデル
│   ├── time_slot.rb                # 予約枠モデル
│   └── user.rb                     # ユーザーモデル
├── decorators/
│   ├── booking_decorator.rb        # 予約の表示ロジック
│   └── time_slot_decorator.rb      # 予約枠の表示ロジック
└── validators/
    └── time_range_validator.rb     # 営業時間バリデーション
```

## 営業時間

| 曜日 | 営業時間 |
|------|----------|
| 月〜金 | 10:00〜18:00 |
| 土曜日 | 11:00〜15:00 |
| 日曜日 | 休業 |

## ライセンス

このプロジェクトはプライベートリポジトリです。
