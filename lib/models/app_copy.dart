import 'package:flutter/material.dart';

class AppCopy {
  const AppCopy._(this.isKorean);

  factory AppCopy.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return AppCopy._(code == 'ko');
  }

  final bool isKorean;

  String get title => isKorean ? '약 알리미' : 'Pill Reminder';
  String get subtitle => isKorean
      ? '복약 알림, 기록, 통계를 한 번에 관리하세요.'
      : 'Manage medication reminders, logs, and stats in one place.';
  String get headerSummary => isKorean
      ? '오늘 복약 체크는 홈에서, 흐름 확인은 통계에서 관리하세요.'
      : 'Track today on Home and review your flow from Stats.';
  String get homeTab => isKorean ? '홈' : 'Home';
  String get statsTab => isKorean ? '통계' : 'Stats';
  String get historyTab => isKorean ? '기록' : 'History';
  String get settingsTab => isKorean ? '설정' : 'Settings';
  String get historyTitle => isKorean ? '히스토리' : 'History';
  String get settingsTitle => isKorean ? '복약 설정' : 'Medication Settings';
  String get statsTitle => isKorean ? '복약 통계' : 'Medication Stats';
  String get todayChecklist => isKorean ? '오늘 복약 현황' : 'Today Checklist';
  String get medications => isKorean ? '내가 먹는 약' : 'My Medications';
  String get quickPlans => isKorean ? '빠른 복약 플랜' : 'Quick Plans';
  String get reminderStatus =>
      isKorean ? '백그라운드 알림' : 'Background Reminders';
  String get reminderOn => isKorean
      ? '앱을 닫아도 정해둔 복약 시간에 알림이 계속 울립니다.'
      : 'Medication reminders will continue to alert you even after the app is closed.';
  String get reminderOff => isKorean
      ? '현재 복약 알림이 꺼져 있습니다.'
      : 'Medication reminders are currently turned off.';
  String get reminderPermissionDenied => isKorean
      ? '알림 권한이 없어 복약 알림을 켤 수 없습니다.'
      : 'Notification permission was denied, so reminders could not be enabled.';
  String get reminderSaved =>
      isKorean ? '복약 알림 일정이 저장되었습니다.' : 'Your medication reminder schedule has been saved.';
  String get todayResetDone =>
      isKorean ? '오늘 기록이 초기화되었습니다.' : 'Today\'s records have been reset.';
  String get resetTodayConfirmTitle =>
      isKorean ? '오늘 기록 초기화' : 'Reset today\'s records';
  String get resetTodayConfirmBody => isKorean
      ? '오늘 복약 기록과 체크 상태를 모두 초기화할까요?'
      : 'Reset today\'s medication records and check states?';
  String get cancel => isKorean ? '취소' : 'Cancel';
  String get confirm => isKorean ? '확인' : 'Confirm';
  String get noMedicationWarningTitle => isKorean
      ? '아직 내가 먹는 약이 추가되지 않았어요!'
      : 'You have not added any medications yet.';
  String get noMedicationWarningBody => isKorean
      ? '이대로 이번 회차를 기록할까요?'
      : 'Do you want to record this dose cycle as is?';
  String get proceedAnyway => isKorean ? '네, 진행할게요' : 'Yes, continue';
  String get dontAskAgain => isKorean
      ? '다시는 묻지 말아주세요'
      : 'Do not ask again';
  String get addDose => isKorean ? '이번 회차 복용 완료' : 'Complete This Dose Cycle';
  String get skipDose => isKorean ? '이번 회차 건너뛰기' : 'Skip This Dose Cycle';
  String get resetToday => isKorean ? '오늘 초기화' : 'Reset Today';
  String get doseGoal => isKorean ? '하루 복약 횟수' : 'Daily Dose Goal';
  String get reminderInterval => isKorean ? '복약 간격' : 'Reminder Interval';
  String get startHour => isKorean ? '시작 시간' : 'Start Time';
  String get recentLog => isKorean ? '오늘 복약 히스토리' : 'Today Medication History';
  String get latestActivity => isKorean ? '최근 활동' : 'Latest activity';
  String get allActivity => isKorean ? '전체 복약 기록' : 'All activity';
  String get medicationHint => isKorean
      ? '예: 비타민 D, 감기약, 항생제'
      : 'e.g. Vitamin D, cold medicine, antibiotics';
  String get addMedication => isKorean ? '약 추가' : 'Add Medication';
  String get adherenceStats => isKorean ? '복약 통계' : 'Adherence Stats';
  String get emptyLog => isKorean ? '아직 기록이 없습니다.' : 'No medication logs yet.';
  String get noMoreHistory =>
      isKorean ? '아직 표시할 기록이 없습니다.' : 'There is no activity to show yet.';
  String get goalReached =>
      isKorean ? '오늘 복약 목표를 채웠습니다.' : 'You completed today\'s medication goal.';
  String get scheduleFinished =>
      isKorean ? '일정 종료' : 'Done';
  String get currentCycle => isKorean ? '복약 회차 설정' : 'Dose Cycle Settings';
  String get nextReminder => isKorean ? '다음 회차' : 'Next Dose';
  String get doseTimeline => isKorean ? '오늘 복약 일정' : 'Today\'s Medication Schedule';
  String get completedState => isKorean ? '완료' : 'Done';
  String get pendingState => isKorean ? '예정' : 'Pending';
  String get skippedState => isKorean ? '건너뜀' : 'Skipped';
  String get takenLabel => isKorean ? '복용 완료' : 'Taken';
  String get skippedLabel => isKorean ? '건너뜀' : 'Skipped';
  String get sevenDaySuccess => isKorean ? '최근 7일 성공률' : '7-day success rate';
  String get missedCount => isKorean ? '최근 7일 건너뜀' : '7-day skipped';
  String get checkedToday => isKorean ? '오늘 체크한 약 종류' : 'Checked medications';
  String get medsCountSetting => isKorean ? '등록된 약 개수' : 'Saved medications';
  String get notificationGuide => isKorean
      ? '리마인더는 설정값 기준으로 다시 예약됩니다.'
      : 'Reminders are rescheduled based on your current settings.';
  String get statsHint => isKorean
      ? '최근 7일 복약 흐름과 오늘 기록을 한 번에 확인하세요.'
      : 'Review your last 7 days and today\'s medication flow in one place.';
  String get settingsHint => isKorean
      ? '홈에는 체크 흐름만 두고, 세부 조정은 설정 화면으로 분리했습니다.'
      : 'The Home tab keeps the checklist focused while detailed controls live in Settings.';
  String get historyHint => isKorean
      ? '복약 완료와 건너뜀 기록을 시간순으로 확인할 수 있습니다.'
      : 'See all completed and skipped medication records in chronological order.';
  String get weeklyFlow => isKorean ? '주간 흐름' : 'Weekly flow';
  String get weeklyFlowHint => isKorean
      ? '최근 7일간 목표 대비 복약 완료 횟수입니다.'
      : 'Taken doses versus goals over the last 7 days.';
  String get todaySummary => isKorean ? '오늘 요약' : 'Today summary';
  String get progressTitle => isKorean ? '복약 진행' : 'Medication progress';
  String get medicationChecklistHint => isKorean
      ? '추가한 약마다 복용 완료 또는 건너뜀을 눌러 기록하세요.'
      : 'For each added medication, tap Taken or Skipped to record it.';
  String get cycleActionHint => isKorean
      ? '등록한 약이 없을 때만 회차 단위로 빠르게 기록하세요.'
      : 'Use cycle-level actions only when you have not added medications.';
  String get completeDoseHint => isKorean
      ? '복용한 약을 선택한 뒤 아래 버튼으로 기록을 완료하세요.'
      : 'Choose the medications you took, then confirm below.';
  String get completeSelectionTitle =>
      isKorean ? '복용 완료 체크' : 'Complete medications';
  String get completeSelectedButton =>
      isKorean ? '선택한 약 복용 완료' : 'Mark selected as taken';
  String get completeAllOption =>
      isKorean ? '모두 복용 완료' : 'Mark all as taken';
  String get completeCurrentCycleButton =>
      isKorean ? '이대로 완료 처리하기' : 'Complete this cycle as is';

  String doses(int value) => isKorean ? '$value회' : '$value doses';
  String intervalLabel(int hours) =>
      isKorean ? '$hours시간 간격' : 'Every $hours hours';
  String countLabel(int value) => isKorean ? '$value개' : '$value items';

  String hourLabel(int hour) {
    final period =
        hour < 12 ? (isKorean ? '오전' : 'AM') : (isKorean ? '오후' : 'PM');
    final normalized = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return isKorean ? '$period $normalized시' : '$normalized $period';
  }

  String planName(String key) {
    if (!isKorean) return key;
    switch (key) {
      case 'Morning + Night':
        return '아침 + 저녁';
      case 'Three Times':
        return '하루 세 번';
      case 'After Meals':
        return '식후 루틴';
      case 'Antibiotics':
        return '항생제 집중';
      default:
        return key;
    }
  }

  String planDetail(int doses, int hours, int startHour) => isKorean
      ? '$doses회 · $hours시간 간격 · ${hourLabel(startHour)} 시작'
      : '$doses doses · every $hours hours · starts ${hourLabel(startHour)}';

  String completionText(int taken, int total) =>
      isKorean ? '$taken / $total회 완료' : '$taken / $total completed';

  String doseSlotLabel(int index) {
    if (isKorean) {
      switch (index) {
        case 0:
          return '1회차';
        case 1:
          return '2회차';
        case 2:
          return '3회차';
        case 3:
          return '4회차';
        default:
          return '${index + 1}회차';
      }
    }
    return 'Dose ${index + 1}';
  }

  String rateText(int rate) => isKorean ? '$rate% 달성' : '$rate% completed';

  String logTakenAt(String time, List<String> names) => isKorean
      ? '$time · ${names.join(', ')} 복용 완료'
      : '$time · ${names.join(', ')} taken';

  String logSkippedAt(String time, List<String> names) => isKorean
      ? '$time · ${names.join(', ')} 건너뜀'
      : '$time · ${names.join(', ')} skipped';

  String weekdayShort(DateTime value) {
    const ko = ['월', '화', '수', '목', '금', '토', '일'];
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return (isKorean ? ko : en)[value.weekday - 1];
  }
}
