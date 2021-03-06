# isucon5-qualify-on-spkills
~~isucon5予選をフレームワークに載せ替えてみるヤツ~~
紆余曲折あってただの素振り。

### 実行環境作成

#### 過去問のvagrantで環境構築
```
git clone git@github.com:matsuu/vagrant-isucon.git
cd isucon5-qualifier
# vagrantのportを変更
# config.vm.network "forwarded_port", guest: 3306, host: 23306, auto_correct: true
vagrant up
```

#### 実装の切り替え
```
sudo systemctl stop isuxi.ruby
sudo systemctl disable isuxi.ruby
sudo systemctl enable isuxi.go
sudo systemctl start isuxi.go
```

#### macからmysql接続できるようにする
```sql
GRANT ALL ON *.* to isucon@"10.0.%" identified by '' with grant option;
FLUSH PRIVILEGES;
```

#### mysqldで接続許可
/etc/mysql/mysql.conf.d/mysqld.cnfの`bind-address`を`0.0.0.0`にする

#### 最後にmysqlを再起動
```
sudo systemctl restart mysql
```

#### copy from isucon5-qualify
```sh
cp ../../isucon5-qualify/webapp/go/app.go .
cp -pr ../../isucon5-qualify/webapp/go/templates
```

### build
```sh
GOOS=linux GOARCH=amd64 go build app.go
```

### restart
```sh
sudo systemctl restart isuxi.go
sudo systemctl status isuxi.go
```

### access logメモ
https://github.com/tkuchiki/alp
```
cat access.log | ./alp --max -r
```

### slow logメモ
基本slow_logをONにしといて、最後にOFF
```
mysql> show variables like 'long_query%';
mysql> show variables like 'slow_query%';
mysql> set global slow_query_log=1;
# 実行時間が遅い順
$ mysqldumpslow -s at /var/lib/mysql/vagrant-slow.log > /home/isucon/slow.log
# 実行回数が多い順
$ mysqldumpslow -s c /var/lib/mysql/vagrant-slow.log > /home/isucon/slow.log
```

### スコアの更新具合
#### 初回
```
504.3
{"success"=>488, "redirect"=>163, "failure"=>1, "error"=>0, "exception"=>0}
```

#### nginxのconf変更とdomain sockert対応
```
558.5
{"success"=>541, "redirect"=>175, "failure"=>1, "error"=>0, "exception"=>0}
```

nginxのrestart
```sh
sudo systemctl restart nginx.service
```

#### mysqlのconf変更とdomain sockert対応
```
636.9
{"success"=>617, "redirect"=>199, "failure"=>1, "error"=>0, "exception"=>0}
```

mysqlのrestart
```sh
sudo systemctl restart mysql
```

`mysql_config --socket`でsocketの場所確認。引数で`/var/run/mysqld/mysqld.sock`を指定してて接続できない罠があった


#### redis起動まで
```
wget http://download.redis.io/releases/redis-4.0.2.tar.gz
tar xzf redis-4.0.2.tar.gz
cd redis-4.0.2
make
sudo make install

sudo groupadd redis
sudo useradd -s /sbin/nologin -M -g redis redis

sudo mkdir /var/run/redis
sudo chmod 755 /var/run/redis
sudo chown redis:redis /var/run/redis

sudo mkdir /var/log/redis
sudo chmod 755 /var/log/redis
sudo chown redis:redis /var/log/redis

sudo mkdir /etc/redis
sudo chown redis:redis /etc/redis
mkdir /home/isucon/webapp/go/etc/redis;
cp -pr redis.conf /home/isucon/webapp/go/etc/redis/.

redis-server.serviceを/etc/systemd/system/に置く
sudo ln -s /home/isucon/webapp/go/etc/redis/redis.conf /etc/redis/.

sudo systemctl start redis-server
```
`/usr/local/bin/redis-cli`で接続できたらOK

#### sysctlの設定変更
sudo /sbin/sysctl -p
```
632.1
{"success"=>613, "redirect"=>191, "failure"=>1, "error"=>0, "exception"=>0}
```
誤差。
リクエストをさばけるようになったら生きてくるでしょう。

#### getCurrentUser呼びすぎなんじゃぁ
```
654.5
{"success"=>634, "redirect"=>205, "failure"=>1, "error"=>0, "exception"=>0}
```
ごみの修正

#### 足跡のテンプレからgetUser潰す
```
845.9
{"success"=>821, "redirect"=>249, "failure"=>1, "error"=>0, "exception"=>0}
```

#### relationにindex追加してSQL改善
```
816.3
{"success"=>792, "redirect"=>243, "failure"=>1, "error"=>0, "exception"=>0}
```

#### isFriendを呼ばないんじゃ
```
1394.3
{"success"=>1355, "redirect"=>393, "failure"=>1, "error"=>0, "exception"=>0}
```

#### GetFriendのSQLも改善
```
1729.3
{"success"=>1681, "redirect"=>483, "failure"=>1, "error"=>0, "exception"=>0}
```

#### 友達のエントリを1000件ひかない
```
1884.1
{"success"=>1833, "redirect"=>511, "failure"=>1, "error"=>0, "exception"=>0}
```

#### 足跡にindex貼った
```
7428.5
{"success"=>7230, "redirect"=>1985, "failure"=>1, "error"=>0, "exception"=>0}
```

#### topはbodyもってこない
```
7428.5
{"success"=>7230, "redirect"=>1985, "failure"=>1, "error"=>0, "exception"=>0}
```

#### topのcommentからget_userを廃止
```
7285.4
{"success"=>7092, "redirect"=>1934, "failure"=>1, "error"=>0, "exception"=>0}
```

#### entryからget_userを廃止
```
7730.7
{"success"=>7524, "redirect"=>2067, "failure"=>1, "error"=>0, "exception"=>0}
```

#### friendsからget_userを廃止
```
8756.3
{"success"=>8523, "redirect"=>2333, "failure"=>1, "error"=>0, "exception"=>0}
```

#### userをinitでredisにいれて、redisから引く
なんか、redisから取れてないケースがある。。
1件取得するだけなら、redisもmysqlもそこまで変わらないのかも。
```
8920.1
{"success"=>8682, "redirect"=>2381, "failure"=>1, "error"=>0, "exception"=>0}
```

