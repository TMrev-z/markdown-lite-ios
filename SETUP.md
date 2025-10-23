# Google Drive API セットアップガイド

## 1. Google Cloud Consoleでの設定

### 1.1 プロジェクトを作成（既存のプロジェクトを使用してもOK）

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. 新しいプロジェクトを作成するか、既存のプロジェクトを選択

### 1.2 Google Drive APIを有効化

1. 左メニューから **APIs & Services** → **Library** を選択
2. 「Google Drive API」を検索
3. **ENABLE** をクリック

### 1.3 OAuth同意画面を設定

1. **APIs & Services** → **OAuth consent screen**
2. User Type: **External** を選択（個人利用の場合）
3. 以下を入力：
   - **App name**: `Markdown Lite iOS`
   - **User support email**: あなたのメールアドレス
   - **Developer contact information**: あなたのメールアドレス
4. **SAVE AND CONTINUE**
5. Scopes画面：**ADD OR REMOVE SCOPES**
   - `.../auth/drive.file` を選択
   - **UPDATE** → **SAVE AND CONTINUE**
6. Test users: 自分のGoogleアカウントを追加
7. **SAVE AND CONTINUE** → **BACK TO DASHBOARD**

### 1.4 OAuth Client IDを作成

1. **APIs & Services** → **Credentials**
2. **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Application type: **iOS**
4. 以下を入力：
   - **Name**: `Markdown Lite iOS App`
   - **Bundle ID**: `com.cocoroai.MarkdownLite`
5. **CREATE**
6. 作成されたClient IDをコピー（`xxxxx.apps.googleusercontent.com` の形式）

## 2. Xcodeでの設定

### 2.1 Config.xcconfigファイルを作成

```bash
cd ~/markdown-lite-ios
cp Config.xcconfig.template Config.xcconfig
```

### 2.2 Config.xcconfigを編集

取得したClient IDを使って設定：

```
GOOGLE_CLIENT_ID = 123456789-abcdef.apps.googleusercontent.com
GOOGLE_URL_SCHEME = com.googleusercontent.apps.123456789-abcdef
```

**URL Schemeの作り方：**
Client ID `123456789-abcdef.apps.googleusercontent.com` の場合
→ `com.googleusercontent.apps.123456789-abcdef`

### 2.3 Xcodeプロジェクトに設定を適用

1. Xcodeでプロジェクトを開く
2. 左ペインでプロジェクト（一番上の青いアイコン）を選択
3. **Info** タブを選択
4. **Custom iOS Target Properties** セクションで右クリック → **Add Row**
5. 以下を追加：

   **Key**: `GIDClientID`
   **Type**: String
   **Value**: `$(GOOGLE_CLIENT_ID)`

6. さらに追加：

   **Key**: `CFBundleURLTypes`
   **Type**: Array

7. `CFBundleURLTypes` を展開 → **Item 0** を追加
8. **Item 0** 配下に以下を追加：

   **Key**: `CFBundleURLSchemes`
   **Type**: Array

9. `CFBundleURLSchemes` を展開 → **Item 0** を追加
10. **Item 0** の値を `$(GOOGLE_URL_SCHEME)` に設定

### 2.4 Build Settingsに設定を適用

1. プロジェクト設定の **Build Settings** タブを選択
2. 検索ボックスに「config」と入力
3. **User-Defined** セクションで「+」ボタンをクリック
4. `GOOGLE_CLIENT_ID` を追加し、値を設定
5. 同様に `GOOGLE_URL_SCHEME` を追加

または、**Configurations** セクションで：
1. Debug/Release両方に `Config.xcconfig` を設定

## 3. GoogleDriveService.swiftを更新

`Services/GoogleDriveService.swift` の25行目を以下に変更：

```swift
let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String ?? ""
let signInConfig = GIDConfiguration(clientID: clientID)
```

## 4. ビルド＆実行

1. Xcode で **⌘+B** (ビルド)
2. シミュレーターまたは実機を選択
3. **⌘+R** (実行)

## トラブルシューティング

### 「Client ID not found」エラー
- `Config.xcconfig` が正しく設定されているか確認
- Xcode を再起動してビルド

### 認証画面が表示されない
- URL Schemeが正しく設定されているか確認
- Bundle IDが一致しているか確認

### 「This app is blocked」エラー
- OAuth同意画面でTest usersに自分のアカウントを追加
- アプリが「Testing」状態であることを確認
