# 민주주의 커뮤니티, 빠띠

## 배포

engineyard를 사용합니다.

## 실환경 구축

mysql의 encoding은 utf8mb4를 사용합니다. mysql은 버전 5.6 이상을 사용합니다.

mysql my.cnf
```
[mysqld]
innodb_file_format=Barracuda
innodb_large_prefix = ON
innodb_ft_min_token_size = 1
innodb_ft_enable_stopword = OFF

[mysqldump]
default-character-set = utf8mb4
```

database.yml
```
  encoding:  utf8mb4
  collation: utf8mb4_unicode_ci
```

환경변수값은 설정 [philnash/envyable](https://github.com/philnash/envyable) gem을 통해 설정합니다.

```
production:
  SECRET_KEY_BASE: xx
  GOOGLE_OAUTH2_APP_ID: xx
  GOOGLE_OAUTH2_APP_SECRET: xx
  FACEBOOK_APP_ID: xx
  FACEBOOK_APP_SECRET: xx
  TWITTER_APP_ID: xx
  TWITTER_APP_SECRET: xx
  MAILTRAP_USER_NAME: xx
  MAILTRAP_PASSWORD: xx
  POSTMARKER_API_KEY: xx
  CRAWLING_PROXY_HOST: xx
  CRAWLING_PROXY_PORT: xx
  ERROR_SLACK_WEBHOOK_URL: xx
  S3_ACCESS_KEY: xx
  S3_SECRET_KEY: xx
  S3_REGION: xx
  S3_BUCKET: xx
  PARTI_ADMIN_PASSWORD: xx
  FCM_KEY: xx
  MOBILE_APP_DOORKEEPER_APPLICATION_UID_catan_spark_android: xx
```

firebase realtime database와 연결합니다.

https://console.firebase.google.com/project/{구글 프로젝트 이름}/settings/serviceaccounts/adminsdk 에서 "새 비공개 키 생성" 버튼을 클릭하여 계정 파일을 다운로드 받습니다. 이 파일을 config아래에 복사해 둡니다

## 로컬 개발 환경 구축 방법

기본적인 Rail 개발 환경에 rbenv, puma-dev를 이용합니다.

### rbenv 설정

```
$ rbenv install 2.3.1
$ bundle install
```

### puma-dev 설정

```
$ brew install puma/puma/puma-dev
$ sudo puma-dev -setup
$ puma-dev link -n parti
```


### 소스관리 설정

반드시 https://github.com/awslabs/git-secrets를 설치하도록 합니다. 설치 후에 반드시 https://github.com/awslabs/git-secrets#installing-git-secrets 이 부분을 참고하여 로컬 레포지토리에 모두 설정 합니다.

```
$ git secrets --install
$ git secrets --register-aws
```

그리고 데이터베이스는 각 레포지토리마다 다릅니다. 아래 git hook 을 설정합니다

```
$ echo $'#!/bin/sh\nif [ "1" == "$3" ]; then spring stop && touch ./tmp/restart.txt; fi' > .git/hooks/post-checkout
$ chmod +x .git/hooks/post-checkout
```

### 데이터베이스 준비

#### mysql 설정
mysql을 구동해야합니다. mysql의 encoding은 utf8mb4를 사용합니다. mysql은 버전 5.6 이상을 사용합니다.

encoding세팅은 my.cnf에 아래 설정을 넣고 반드시 재구동합니다. 참고로 맥에선 /usr/local/Cellar/mysql/(설치하신 mysql버전 번호)/my.cnf입니다.

```
[mysqld]
innodb_file_format=Barracuda
innodb_large_prefix = ON
```

#### 연결 정보

프로젝트 최상위 폴더에 local_env.yml이라는 파일을 만듭니다. 데이터베이스 연결 정보를 아래와 예시를 보고 적당히 입력합니다.

```
development:
  database:
    username: 사용자이름
    password: 암호
```


#### 스키마

데이터베이스를 만듧니다.
```
mysql > create database catan_development_브랜치명 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```
db:setup으로 스키마를 생성합니다.

```
$ bin/rake db:setup
```

#### 초기 데이터 추가

먼저 .powenv에 원하는 관리자용 암호를 등록합니다.
```
export PARTI_ADMIN_PASSWORD="12345678"
```

[mbleigh/seed-fu](https://github.com/mbleigh/seed-fu) 을 이용하여 설정된 초기 데이터를 로딩합니다.

```
$ source .powenv
$ bundle exec rake db:seed_fu
$ bundle exec rake data:seed:group
```


### 사이드킥을 로컬에서 테스트하려면
.powenv에 아래를 추가합니다.

```
export SIDEKIQ=true
```

redis를 구동합니다

```
$ redis-server
```

사이드킥을 구동합니다

```
$ source .powenv && bundle exec sidekiq
```

puma를 재기동합니다

### 로컬에서 한글 이름의 파일을 다운로드하면 파일 이름이 깨질 때

.powenv에 아래를 추가합니다.

```
export FILENAME_ENCODING="ISO-8859-1"
```

### 메일 확인

https://parti.test/devel/emails 에서 메일 발송을 확인 할 수 있습니다.

### 인기글 업데이트

https://parti.test/score

위 주소에 접근하면 업데이트 됩니다.

### 페이스북 로그인

페이스북에 https://parti.test와 연결된 앱의 정보를 아래와 같이 .powenv에 설정합니다.
```
export FACEBOOK_APP_ID="키값"
export FACEBOOK_APP_SECRET="키값"
```
### 포스트마커 연동

.powenv에 API키를 등록 합니다.

```
export POSTMARKER_API_KEY="키값"
```

### 사용자 임시 삭제

```
https://parti.test/kill_me
```

## 빠띠 테스트서버 관리

주의 : 아래 관리 방법은 parti.xyz에서 테스트서버를 관리하는 팁입니다.

### 실서버 이미지를 테스트서버로 이관하기

omurice에서 실행합니다

```
$ rm -rf /home/deploy/test/files/uploads

$ s3cmd sync s3://catan-file/uploads /home/deploy/test/files -c ~/.s3cfg.production

$ s3cmd sync /home/deploy/test/files/uploads/ s3://catan-file-dev/uploads/
```

## 데이터 관리

### 아래를 rails console에서 수행하면 지워진 글의 수다를 삭제합니다

Comment.all.each { |c| c.destroy if c.post.blank? }

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

## oauth

아래 주소에서 oauth application 정보 관리할 수 있다.

https://parti.test/oauth/applications

로컬에서 아래 명령을 수행하면 로그인한 사용자의 최근 access token정보를 알 수 있다

https://parti.test/users/access_token?app=어플리케이션이름

## 로컬 환경에서도 사용자 프로필 사진, 빠띠 대문 이미지 등을 보이게 하는 법

.powenv 파일에 아래 변수를 추가합니다.

```
export PRIVATE_S3_ACCESS_KEY="xx"
export PRIVATE_S3_SECRET_KEY="xx"
export PRIVATE_S3_REGION="xx"
export PRIVATE_S3_BUCKET="xx"
export S3_BUCKET="xx"
```

## firebase realtime database와 연결

https://console.firebase.google.com/project/{구글 프로젝트 이름}/settings/serviceaccounts/adminsdk 에서 "새 비공개 키 생성" 버튼을 클릭하여 계정 파일을 다운로드 받습니다. 이 파일을 config아래에 복사해 둡니다

.powenv 파일에 개발자마다 유일한 키를 등록합니다
```
export FIREBASE_BUCKETNAME="dalikim"
```

개발 환경에서 firebase와 연결을 하려면 아래 설정을 해야 합니다. 아래 설정이 없으면 firebase에 연결하지 않고서도 개발이 가능합니다.
```
export FIREBASE=true
```

## 스파크 앱과 연결

doorkeeper에 등록된 어플리케이션 중에 테스트할 어플리케이션의 uid를 등록한다.

```
export MOBILE_APP_DOORKEEPER_APPLICATION_UID_catan_spark_android=키값
```

## 트러블슈팅

### 웹 주소가 바뀌고 난 뒤에 에디터가 말썽일 경우

아래 명령을 수행합니다. https://github.com/spohlenz/tinymce-rails/pull/182
```
$ rake tmp:cache:clear
```
