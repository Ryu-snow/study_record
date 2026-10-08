# iPhone で実行する手順

## 確認済みのプロジェクト設定

| 対象 | Bundle Identifier | 署名 | Team |
| --- | --- | --- | --- |
| FORMStudy（Debug / Release） | jp.ryukawasaki.formstudy | Automatic | D9K33N34XD |
| FORMStudyWidget（Debug / Release） | jp.ryukawasaki.formstudy.widget | Automatic | D9K33N34XD |

Team ID は添付プロジェクトの値を保持しています。あなたの Apple Account がこの Team を利用できるか、証明書やプロビジョニングプロファイルが有効かは、Mac での署名時に確認が必要です。

アプリの `NSSupportsLiveActivities` は有効です。`StudyTimerAttributes.swift` は両ターゲットの Sources に登録され、アプリはウィジェットへの依存と Embed App Extensions を持っています。共有 FORMStudy スキームで両方をビルドします。最低対応 OS は iOS 17.0 です。

このクラウド環境は Linux で、Xcode・iOS SDK がありません。実際のコンパイル、署名、端末での動作は未検証です。添付ファイルの再構成と plist / scheme XML の解析を実施しました。

## Mac で必要な操作

1. Xcode 16 以降と iOS プラットフォームをインストールし、Xcode を一度起動して初期設定を完了します。`xcodebuild -version` が失敗する場合は、Xcode の Settings → Locations → Command Line Tools で使用する Xcode を選択してください。
2. Xcode の Settings → Accounts から Apple Account にログインします。パスワード、証明書の秘密鍵などをチャットに送る必要はありません。
3. `FORMStudy.xcodeproj` を開き、両ターゲットの Signing & Capabilities で Automatically manage signing と Team を確認します。`D9K33N34XD` が自分の Team でない場合は、両ターゲットを同じ自分の Team に変更してください。Bundle Identifier は上記の値を維持します。
4. iOS 17 以降の iPhone を Mac に接続し、ロックを解除して「このコンピュータを信頼」を許可します。iPhone の 設定 → プライバシーとセキュリティ → デベロッパモードを有効化し、要求された再起動と確認を行います。

## xcodebuild と署名検証

展開したプロジェクトのルートで実行します。

```sh
# アプリと Live Activity ウィジェットをコンパイル（署名不要）
bash scripts/build-ios.sh simulator

# 接続端末と destination ID を確認
xcodebuild -project FORMStudy.xcodeproj -scheme FORMStudy -showdestinations

# 自分の Team ID と接続 iPhone の ID を指定して署名付きビルド
DEVELOPMENT_TEAM=自分のTeamID DEVICE_UDID=iPhoneのID bash scripts/build-ios.sh device
```

Team が `D9K33N34XD` の場合、`DEVELOPMENT_TEAM` の指定は省略できます。`DEVICE_UDID` を省略すると generic iOS 向けビルドになります。初回の実機プロビジョニングには接続端末の指定を推奨します。

ログは `build/logs/simulator.log` と `build/logs/device.log` に保存されます。パイプの途中で xcodebuild が失敗しても、スクリプトは失敗を返します。実機ビルド後は埋め込みウィジェットの存在と両方のコード署名を検証します。CLI のビルドは端末へのインストール・起動は行いません。

エラーが発生したら、該当ログを共有してください。Apple Account の認証情報や秘密鍵は含めないでください。Bundle ID の登録権限エラーは、その ID を使用できる Team の選択が必要です。署名を無効化して実機ビルドの成功として扱わないでください。

## インストールと Live Activity の実機確認

1. Xcode で FORMStudy スキームと接続 iPhone を選択し、Run（⌘R）します。端末に開発元の信頼確認が表示された場合のみ、設定 → 一般 → VPN とデバイス管理から対応する開発元を信頼します。
2. アプリで学習サイトにログインし、タイマーを開始します。iPhone をロックし、ロック画面で科目と経過時間が表示されるか確認します。Dynamic Island 搭載機種ではそこでも確認します。
3. タイマーを停止し、Live Activity が終了するか確認します。表示されない場合は、アプリの設定で Live Activities が許可されているか確認します。

アプリはサイト側からの `window.webkit.messageHandlers.studyTimer.postMessage` を受信して開始・停止します。開始データは `action: "start"`、`subject`（english / math / chemistry / physics）、`startedAt`（Unix epoch のミリ秒）、停止データは `action: "stop"` です。ユーザーの説明によれば状態変更時の送信は実装済みです。サイトのソースは添付されておらず、こちらからの取得も HTTP 403 だったため、読み込み時の現在状態送信は確認できていません。この応答だけでは iPhone からもアクセスできないとは判断できません。

## アプリ再起動・復帰時の状態同期（サイト側の対応が必要）

ネイティブ側はページ読み込み完了とアプリ復帰時に `window` 上で `FORMStudyTimerStateRequested` イベントを発行します。サイト側はこのイベントを受けて、現在の正しい状態を既存の `studyTimer` ハンドラへ送信してください。ログインとタイマー状態の読み込みが完了した時点でも同じ送信を行う必要があります。SPA の初期化よりイベントが早かった場合も、その完了時の送信で同期できます。

開始中なら元の開始時刻を使った `start`、停止中なら `stop` を送ります。ネイティブ側は既存の一致する Activity を再利用し、余分な Activity を終了します。前回の Activity だけからサイトの現在状態を推測することはしません。サイトが別端末で停止された場合などに、誤った復元を避けるためです。

サイト側の購読例（関数はサイトの実際の状態管理に接続する必要があります）:

```javascript
// publishCurrentStudyTimerState はサイト側で実装する関数です。
// 状態が未取得なら送信を待ち、取得後に start または stop を送信します。
window.addEventListener('FORMStudyTimerStateRequested', publishCurrentStudyTimerState);
// ログイン・保存済みタイマーの読込完了時にも呼び出します。
// publishCurrentStudyTimerState();
```

このサイト側の状態同期が未実装なら、アプリ起動時の復元は未完成です。ネイティブ側の変更だけで復元済みとは扱えません。

## Live Activity の操作ボタンとサイト保存連携

ロック画面と Dynamic Island の展開表示には一時停止／再開ボタンと記録ボタンがあります。一時停止は Activity の経過時間を固定し、再開は一時停止後の時間を加算します。ボタン操作は `studymoney://timer/pause`、`resume`、`save` の URL でアプリを開き、WebView上に次のイベントを発行します。

- `FORMStudyTimerPauseRequested`
- `FORMStudyTimerResumeRequested`
- `FORMStudyTimerSaveRequested`

イベントの `detail` には `subject` と `startedAt`（Unix epoch のミリ秒）が入り、保存時には `elapsedSeconds`（一時停止分を除いた秒数）も入ります。サイトは pause／resume に応じて自身のタイマーも止め／再開し、必要に応じて `studyTimer` ハンドラへ `pause`／`resume` を通知してください。保存イベントでは `elapsedSeconds` を用いて学習記録を保存し、保存後に `studyTimer` へ `{ action: "stop" }` を送ってサイト側タイマーも終了させてください。

このリポジトリにはサイトのフロントエンド／保存APIのソースが含まれていません。そのため、アプリは保存要求を渡せますが、データベースへの実保存とサイト側カウンターの同期はサイト側リスナーを追加して検証する必要があります。現在サイトはこの環境から HTTP 403 で取得できず、保存の成否は未確認です。

## 実機の受け入れ確認

- ログイン後にアプリを終了・再起動し、セッションが維持される。
- 4 科目それぞれで開始し、ロック画面と Dynamic Island の展開／コンパクト表示に日本語の科目と経過時間が出る。
- 同じ start メッセージを繰り返しても Activity が増えない。
- 素早く開始→停止、開始→別科目開始を行い、最後の操作と表示が一致する。
- 停止後にロック画面から Activity が消える。
- タイマー実行中にアプリを終了・再起動し、現在状態の送信後も元の開始時刻から計時する。
- アプリを閉じている間にサイトで停止し、再起動後の stop 送信で古い Activity が終了する。
- Live Activity の一時停止／再開でActivityとWebサイト両方の経過時間が止まり、続きから再開する。
- 記録ボタンからサイトに科目、開始時刻、一時停止を除いた経過秒数が保存され、保存後にActivityとサイトのタイマーが終了する。
- Live Activities を無効にしても、サイトのタイマーが使える。再度有効にして復帰した際、状態送信後に開始する。

Dynamic Island は対応機種のみです。ActivityKit のシステム制限により Live Activity は無期限に表示し続けられません。通常、アクティブ表示は最大 8 時間です。

コンパイル前の構成検証は `python3 scripts/check-project.py` で実施できます。このチェックは Swift のコンパイルや署名検証の代わりにはなりません。
