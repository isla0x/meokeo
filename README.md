# 뭐먹어?

아침·점심·저녁 사진을 앨범 대신 방에서 나누는 앱.

- 지원 페이지: https://isla0x.github.io/meokeo/
- 개인정보 처리방침: https://isla0x.github.io/meokeo/privacy.html

`docs/`는 GitHub Pages(main /docs)로 호스팅돼요.

## 만든 방식

- Flutter(아이폰). 화면은 디자인 목업(9장)을 그대로 옮겼어요.
- 서버는 Firebase: 익명 로그인 + Firestore (사진도 글 문서 안에 들어가요, 별도 Storage 없음). 보안 규칙은 `firestore.rules`.
- 알림은 전부 기기 안에서 예약해요(식사 시각, 마감 30분 전). 서버 푸시는 쓰지 않아요.
- 글꼴(Plus Jakarta Sans, Pretendard)과 그림은 앱 안에 들어 있어요.

## 폴더

- `lib/screens/` 화면 (오늘, 캘린더, 올리기, 새 방, 코드 참여, 초대, 알림, 이름, 사진 보기)
- `lib/repo/` 서버와 이야기하는 부분 (`firebase_repo.dart`) + 화면 확인용 가짜 저장소 (`demo_repo.dart`)
- `lib/widgets.dart`, `lib/icons.dart`, `lib/theme.dart` 공통 부품·아이콘·색
- `test/` 계산 테스트 + 화면 사진 뽑기 (`screens_test.dart`)

## 검사 (GitHub Actions)

`main`/`rebuild`에 올리면 분석 + 테스트 + 화면 사진이 돌고, 결과는 `ci-output` 브랜치에 올라와요.
커밋 메시지에 `[ios]`를 넣으면 맥에서 아이폰 빌드(서명 없이)까지 확인해요.

## 내 폰에 올리기

```
git pull
flutter pub get
flutter build ipa
```

그다음 Xcode의 Organizer(또는 Transporter)로 TestFlight에 올려요. 빌드 번호는 올릴 때마다 `pubspec.yaml`의 `version: 1.0.0+N`에서 N을 올려야 해요.
