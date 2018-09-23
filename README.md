# これはなにか

AWSのS3上に置かれているxlsxをRubyでパースし、CSVに変換して拡張子を付与してメタデータ(json)とともにS3上に置くというスクリプトです。
`d/x.xlsx` を変換すると `d/x.xlsx.csv ` と `d/x.xlsx.json` が作成されます。

Dockerコンテナで実行しようと考えているのでパラメータはすべて環境変数で渡します。

ログは標準出力にでます。

# 環境変数一覧

AWSの認証情報はSDKの環境変数で渡してください。

``` shell
AWS_ACCESS_KEY_ID="AAAAAAAAAAAAAAAAAAAAAAA"
AWS_REGION="ap-northeast-1"
AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

他のパラメータは以下

``` shell
AWS_BUCKET="your_bucket_name"
TARGET_S3KEY="your_xlsx_object_path"
LOG_LEVEL="Ruby_LOG_level" # 省略すると DEBUG
TMP_PATH="TMP_PATH_ON_CONTAINER" # 省略すると /tmp
```

