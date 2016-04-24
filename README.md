# parti 수다로 정치하자, 빠띠에서 파티하자

## 업그레이드

### 0.x --> 1.0

각 빠띠마다 같은 URL의 글이 올란 경우를 찾아 봅니다. 검색이 되면 조치를 취합니다.
```
Article.all.select { |a| Article.joins(:post).where('issue_id': a.issue_id, link_source_id: a.link_source_id).count > 1 }
```

존재하지 않는 사용자가 투표한 데이터를 삭제합니다.

```
Vote.all.select {|v| v.user.nil? }.each {|v| v.destroy }
```

크롤링을 다시 합니다.

```
$ bundle exec rake crawling:reload_all
```

이미지 프로세싱을 다시 합니다

```
$ nohup bin/rake images:reprocess RAILS_ENV=staging > ~/nohup4.out 2>&1&
```

## 배포

engineyard를 사용합니다.

```
$ bin/deploy master
$ bin/deploy dev
$ bin/deploy hotfix
```

## 실환경 구축

mysql의 encoding은 utf8mb4를 사용합니다. mysql은 버전 5.6 이상을 사용합니다.

mysql my.cnf
```
[mysqld]
innodb_file_format=Barracuda
innodb_large_prefix = ON
```

database.yml
```
  encoding:  utf8mb4
  collation: utf8mb4_unicode_ci
```

## 로컬 개발 환경 구축 방법

기본적인 Rail 개발 환경에 rbenv를 이용합니다.

```
$ rbenv install 2.2.3
$ bundle install
$ bundle exec rake db:migrate
```

### 초기 데이터 추가

[mbleigh/seed-fu](https://github.com/mbleigh/seed-fu) 을 이용하여 설정된 초기 데이터를 로딩합니다.

```
$ bundle exec rake db:seed_fu
```

### 메일 확인

http://parti.dev/devel/emails 에서 메일 발송을 확인 할 수 있습니다.

### 인기글 업데이트

http://parti.dev/stat

위 주소에 접근하면 업데이트 됩니다.

### 포스트마커 연동

.powenv에 API키를 등록 합니다.

```
export POSTMARKER_API_KEY="키값"
```

### 사용자 임시 삭제

```
http://parti.dev/kill_me
```

## 데이터 관리

### 아래를 rails console에서 수행하면 지워진 글의 댓글을 삭제합니다

Comment.all.each { |c| c.destroy if c.post.blank? }

### 계정 이전

```
$ bundle exec rake transfer_user[{SOURCE_USER_NICKNAME},{TARGET_USER_NICKNAME}]
$ vi log/{SOURCE_USER_NICKNAME}_{TARGET_USER_NICKNAME}_{DATETIME}.log
```

### 크롤링

실패한 크롤링

```
$ bundle exec rake crawling:fails
```

특정 크롤링 다시 수행
```
$ bundle exec rake crawling:reload[아이디값]
```

모든 크롤링 다시 수행

```
$ bundle exec rake crawling:reload_all
```

