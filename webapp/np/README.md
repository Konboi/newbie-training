Sinatra を使用した NoPaste アプリケーションの実装実習
------------------------------------------------

課題
-----
アプリケーションのリファレンス実装から所々省いたものが `app.rb` として配置されています。

1. `app.rb` の内部を参考に、`spec/webapp_spec.rb` のテストが通る状態まで実装してください。
2. テストは signup, signin, toppage については実装してあるので、残りの `get "/post/:id"`, `get "/star/:id"`, `post "/post"` についてテストを記述してください


準備と実行
-----

```
$ bundle install --path=vendor/bundle 
$ mysql -uroot test < sql/nopaste.sql
$ bundle exec rackup 
```

テスト実行
----------

```
$ bundle exec rspec spec/webapp_spec.rb
```

unicornでのアプリ実行・再起動について
-------------------

```
# 実行
bundle exec unicorn -c unicorn_config.rb -D

# 再起動
kill -USR2 `cat tmp/pids/unicorn.pid`
```

ISUCON計測用初期データ投入
---------------------------

```
$ gzip -dc sql/initial.sql.gz | mysql -uroot test
```

本番計測前に一旦初期データにリセットします。
Schema変更を行う場合は、この後に実行してください。
