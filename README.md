# LINE MSG

## required

ruby: 2.6.6

mv `.env.exmple` to `.env`

set up below setting

```yml
LINE_CHANNEL_ID=
LINE_CHANNEL_SECRET=
LINE_CHANNEL_TOKEN=
GOOGLE_SHEET_ID=
```

Get `google-api-key.json` from Google API

## install

```shell
bundle install
```

## run

```shell
ruby app.rb
```

## build image

```shell
docker build -t line-msg . --no-cache
```

## run app via docker run

```shell
docker run --name webhook-api -p 8080:8080 line-msg
```
