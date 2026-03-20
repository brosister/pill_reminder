# pill_reminder

Medication reminder app designed as a differentiated ad-revenue utility.

## Shipping scope
- Korean UI when system language is Korean, English otherwise
- quick medication plans for common daily schedules
- daily dose completion progress
- recent taken / skipped log
- reminder interval and start time controls
- local scheduled notifications that keep working after app close
- server-driven AdMob config
- test / release ad mode from admin
- banner + interstitial hooks
- iOS / Android baseline included
- Android KTS desugaring included for notification + timezone packages

## Ad config
```text
GET https://app-master.officialsite.kr/api/admin/pill-reminder/ad-settings
```

## Run
```bash
flutter pub get
flutter run
```

## Google Play ASO (KO)
- 앱이름: 약 알리미
- 간단설명: 하루 복약 시간을 놓치지 않도록 도와주는 심플한 복약 리마인더 앱
- 자세한설명: 약 알리미는 아침/점심/저녁 복약 루틴이나 일정한 간격의 약 복용 일정을 간단하게 관리할 수 있도록 만든 앱입니다. 빠른 복약 플랜을 고르고, 하루 복약 횟수와 시작 시간, 알림 간격을 조절해 자신의 생활 패턴에 맞는 복약 루틴을 만들 수 있습니다. 오늘 몇 번 복용했는지 진행률로 확인할 수 있고, 최근 복용 완료 또는 건너뜀 기록을 남겨 실제 생활 속에서 자주 열어보며 쓰기 쉬운 가벼운 앱으로 설계했습니다. 광고는 하단 배너와 하루 목표를 채운 뒤 같은 의미 있는 시점의 전면광고 중심으로 배치해 사용 흐름을 과하게 방해하지 않도록 구성했습니다.
- 카테고리: 건강/운동

## Google Play ASO (EN)
- App Name: Pill Reminder
- Short Description: A simple medication reminder app with daily dose goals, intervals, and adherence logs.
- Full Description: Pill Reminder is a lightweight medication routine app built for users who want a simple way to stay on top of recurring doses. It includes quick medication plans, daily dose goals, start time control, reminder intervals, completion progress, and a recent log for taken or skipped doses. Local scheduled notifications continue to work even after the app is closed, making it practical for real routine use. Monetization is designed to stay present without disrupting every interaction, using a stable banner slot and interstitial timing around meaningful completion moments.
- Category: Health & Fitness

## Apple App Store ASO (KO)
- 앱이름: 약 알리미
- 부제: 복약 시간을 놓치지 않게
- 프로모션 텍스트: 하루 복약 횟수, 시작 시간, 간격 알림, 최근 기록으로 가볍게 복약 루틴을 관리해보세요.
- 설명: 약 알리미는 반복 복용이 필요한 약 일정을 단순하고 빠르게 관리할 수 있도록 설계된 앱입니다. 아침+저녁, 하루 세 번, 식후 루틴 같은 빠른 플랜을 선택하고, 복약 횟수와 시작 시간을 조절해 자신에게 맞는 복약 흐름을 만들 수 있습니다. 오늘 복약 진행률과 최근 복용 기록을 쉽게 확인할 수 있고, 앱을 닫아도 로컬 알림이 계속 동작해 실제 생활 속에서 쓰기 편합니다.
- 키워드: 약알리미,복약알림,복약관리,약시간,알리미,medication,pill reminder,건강루틴,health,reminder
- 카테고리: 건강 및 피트니스

## Apple App Store ASO (EN)
- App Name: Pill Reminder
- Subtitle: Stay on track with every dose
- Promotional Text: Manage daily medication with quick plans, dose goals, start time controls, and reminders that keep working after app close.
- Description: Pill Reminder helps users stay consistent with recurring medication routines. It offers quick schedule presets, adjustable daily dose goals, interval-based reminders, a start time selector, completion progress, and recent taken or skipped logs. The experience is intentionally lightweight so users can open it, mark a dose, and move on in seconds.
- Keywords: pill reminder,medication reminder,medicine alarm,dose tracker,health routine,daily medication,adherence,reminder
- Category: Health & Fitness
