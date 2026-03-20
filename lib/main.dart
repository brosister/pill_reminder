import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'services/ad_config_service.dart';
import 'services/medication_log_service.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: const Color(0xFFF8F5FF),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await ReminderService.instance.initialize();
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  runApp(const PillReminderApp());
}

class AppCopy {
  const AppCopy._(this.isKorean);

  factory AppCopy.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return AppCopy._(code == 'ko');
  }

  final bool isKorean;

  String get title => isKorean ? '약 알리미' : 'Pill Reminder';
  String get subtitle => isKorean ? '복약 알림, 기록, 통계를 한 번에 관리하세요.' : 'Manage medication reminders, logs, and stats in one place.';
  String get homeTab => isKorean ? '홈' : 'Home';
  String get historyTab => isKorean ? '기록' : 'History';
  String get settingsTab => isKorean ? '설정' : 'Settings';
  String get todayChecklist => isKorean ? '오늘 복약 현황' : 'Today Checklist';
  String get medications => isKorean ? '약별 체크' : 'Medication Checklist';
  String get quickPlans => isKorean ? '빠른 복약 플랜' : 'Quick Plans';
  String get settingsTitle => isKorean ? '복약 설정' : 'Medication Settings';
  String get reminderStatus => isKorean ? '백그라운드 알림' : 'Background Reminders';
  String get reminderOn => isKorean ? '앱을 닫아도 정해둔 복약 시간에 로컬 알림이 계속 울립니다.' : 'Local medication reminders keep firing even after the app is closed.';
  String get reminderOff => isKorean ? '현재 복약 알림이 꺼져 있습니다.' : 'Medication reminders are currently turned off.';
  String get reminderPermissionDenied => isKorean ? '알림 권한이 없어 복약 알림을 켤 수 없습니다.' : 'Notification permission was denied, so reminders could not be enabled.';
  String get reminderSaved => isKorean ? '복약 알림 일정이 저장되었습니다.' : 'Medication reminder schedule saved.';
  String get addDose => isKorean ? '전체 복용 체크' : 'Mark Cycle as Taken';
  String get skipDose => isKorean ? '이번 회차 건너뛰기' : 'Skip This Cycle';
  String get resetToday => isKorean ? '오늘 초기화' : 'Reset Today';
  String get doseGoal => isKorean ? '하루 복약 횟수' : 'Daily Dose Goal';
  String get reminderInterval => isKorean ? '복약 간격' : 'Reminder Interval';
  String get startHour => isKorean ? '시작 시간' : 'Start Time';
  String get recentLog => isKorean ? '오늘 복약 히스토리' : 'Today Medication History';
  String get medicationHint => isKorean ? '예: 비타민 D, 감기약, 항생제' : 'e.g. Vitamin D, cold medicine, antibiotics';
  String get addMedication => isKorean ? '약 추가' : 'Add Medication';
  String get adherenceStats => isKorean ? '복약 통계' : 'Adherence Stats';
  String get emptyLog => isKorean ? '아직 기록이 없습니다.' : 'No medication logs yet.';
  String get goalReached => isKorean ? '오늘 복약 목표를 채웠습니다.' : 'You completed today\'s medication goal.';
  String get bannerPlaceholder => isKorean
      ? ''
      : '';
  String get adHint => isKorean
      ? ''
      : '';
  String get currentCycle => isKorean ? '현재 복약 사이클' : 'Current Medication Cycle';
  String get nextReminder => isKorean ? '다음 알림' : 'Next Reminder';
  String get takenLabel => isKorean ? '복용 완료' : 'Taken';
  String get skippedLabel => isKorean ? '건너뜀' : 'Skipped';
  String get sevenDaySuccess => isKorean ? '최근 7일 성공률' : '7-day success rate';
  String get missedCount => isKorean ? '최근 7일 건너뜀' : '7-day skipped';
  String get checkedToday => isKorean ? '오늘 체크한 약' : 'Checked today';
  String get medsCountSetting => isKorean ? '등록된 약 개수' : 'Saved medications';
  String get notificationGuide => isKorean ? '리마인더는 설정값 기준으로 다시 예약됩니다.' : 'Reminders are rescheduled based on your current settings.';
  String doses(int value) => isKorean ? '$value회' : '$value doses';
  String intervalLabel(int hours) => isKorean ? '$hours시간 간격' : 'Every $hours hours';
  String countLabel(int value) => isKorean ? '$value개' : '$value items';
  String hourLabel(int hour) {
    final period = hour < 12 ? (isKorean ? '오전' : 'AM') : (isKorean ? '오후' : 'PM');
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
      ? '${doses}회 · ${hours}시간 간격 · ${hourLabel(startHour)} 시작'
      : '$doses doses · every $hours hours · starts ${hourLabel(startHour)}';

  String completionText(int taken, int total) => isKorean ? '$taken / $total회 완료' : '$taken / $total completed';
  String rateText(int rate) => isKorean ? '$rate% 달성' : '$rate% completed';
  String logTakenAt(String time, List<String> names) => isKorean ? '$time · ${names.join(', ')} 복용 완료' : '$time · ${names.join(', ')} taken';
  String logSkippedAt(String time, List<String> names) => isKorean ? '$time · ${names.join(', ')} 건너뜀' : '$time · ${names.join(', ')} skipped';
}

class PillPlan {
  const PillPlan({required this.label, required this.dailyDoses, required this.intervalHours, required this.startHour, required this.icon});
  final String label;
  final int dailyDoses;
  final int intervalHours;
  final int startHour;
  final IconData icon;
}

class DoseLog {
  const DoseLog({required this.title, required this.time, required this.skipped, required this.medicationNames});
  final String title;
  final String time;
  final bool skipped;
  final List<String> medicationNames;
}

class PillReminderApp extends StatelessWidget {
  const PillReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pill Reminder',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: const Color(0xFFF8F5FF),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F5FF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7A5AF8), brightness: Brightness.light),
      ),
      home: const PillReminderHomePage(),
    );
  }
}

class PillReminderHomePage extends StatefulWidget {
  const PillReminderHomePage({super.key});

  @override
  State<PillReminderHomePage> createState() => _PillReminderHomePageState();
}

class _PillReminderHomePageState extends State<PillReminderHomePage> {
  static const plans = [
    PillPlan(label: 'Morning + Night', dailyDoses: 2, intervalHours: 12, startHour: 8, icon: Icons.wb_sunny_outlined),
    PillPlan(label: 'Three Times', dailyDoses: 3, intervalHours: 8, startHour: 8, icon: Icons.schedule_rounded),
    PillPlan(label: 'After Meals', dailyDoses: 3, intervalHours: 6, startHour: 9, icon: Icons.restaurant_outlined),
    PillPlan(label: 'Antibiotics', dailyDoses: 4, intervalHours: 6, startHour: 7, icon: Icons.medication_outlined),
  ];

  final AdConfigService _adConfig = AdConfigService();
  final ReminderService _reminderService = ReminderService.instance;
  final TextEditingController _medicationController = TextEditingController();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _bannerLoaded = false;

  int _selectedPlan = 1;
  int _selectedTab = 0;
  int _takenDoses = 0;
  int _dailyDoseGoal = 3;
  int _intervalHours = 8;
  int _startHourValue = 8;
  bool _remindersEnabled = false;
  final List<DoseLog> _logs = [];
  final List<MedicationItemState> _medications = [];
  final List<DailyMedicationSummary> _history = [];

  List<int> get _doseOptions => ({1, 2, 3, 4, 5, 6, ...plans.map((p) => p.dailyDoses), _dailyDoseGoal}.toList()..sort());
  List<int> get _intervalOptions => ({4, 6, 8, 12, ...plans.map((p) => p.intervalHours), _intervalHours}.toList()..sort());
  List<int> get _startHourOptions => ({6, 7, 8, 9, 10, 12, ...plans.map((p) => p.startHour), _startHourValue}.toList()..sort());

  @override
  void initState() {
    super.initState();
    _initAds();
    _loadMedicationState();
    _loadReminderSettings();
  }

  Future<void> _loadMedicationState() async {
    final snapshot = await MedicationLogService.instance.load();
    if (!mounted) return;
    setState(() {
      _selectedPlan = snapshot.selectedPlan;
      _takenDoses = snapshot.takenDoses;
      _dailyDoseGoal = snapshot.dailyDoseGoal;
      _intervalHours = snapshot.intervalHours;
      _startHourValue = snapshot.startHour;
      _medications
        ..clear()
        ..addAll(snapshot.medications);
      _logs
        ..clear()
        ..addAll(snapshot.logs.map((log) => DoseLog(title: log.title, time: log.time, skipped: log.skipped, medicationNames: log.medicationNames)));
      _history
        ..clear()
        ..addAll(snapshot.history);
    });
  }

  Future<void> _persistMedicationState() async {
    await MedicationLogService.instance.saveState(
      takenDoses: _takenDoses,
      dailyDoseGoal: _dailyDoseGoal,
      intervalHours: _intervalHours,
      startHour: _startHourValue,
      selectedPlan: _selectedPlan,
      medications: List<MedicationItemState>.from(_medications),
      logs: _logs
          .map((log) => MedicationLogEntry(
                title: log.title,
                time: log.time,
                skipped: log.skipped,
                medicationNames: log.medicationNames,
                dateKey: MedicationLogService.instance.todayKey(),
              ))
          .toList(),
      history: List<DailyMedicationSummary>.from(_history),
    );
  }

  Future<void> _loadReminderSettings() async {
    final settings = await _reminderService.loadSettings();
    if (!mounted) return;
    setState(() {
      _remindersEnabled = settings.enabled;
      _intervalHours = settings.intervalHours;
      _startHourValue = settings.startHour;
    });
    if (_remindersEnabled) {
      await _syncReminderSchedule(silent: true);
    }
  }

  Future<void> _initAds() async {
    if (kIsWeb) return;
    await _adConfig.loadConfig();
    _bannerAd = BannerAd(
      adUnitId: _adConfig.bannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerLoaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: _adConfig.interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> _syncReminderSchedule({bool silent = false}) async {
    final copy = AppCopy.of(context);
    final settings = ReminderSettings(
      enabled: _remindersEnabled,
      intervalHours: _intervalHours,
      startHour: _startHourValue,
      endHour: math.min(23, _startHourValue + ((_dailyDoseGoal - 1) * _intervalHours)),
    );
    await _reminderService.saveSettings(settings);
    if (_remindersEnabled) {
      final granted = await _reminderService.requestPermissions();
      if (!granted) {
        if (mounted) setState(() => _remindersEnabled = false);
        await _reminderService.saveSettings(settings.copyWith(enabled: false));
        await _reminderService.cancelMedicationReminders();
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.reminderPermissionDenied)));
        }
        return;
      }
    }
    await _reminderService.syncMedicationReminders(settings: settings, dailyDoses: _dailyDoseGoal, isKorean: copy.isKorean);
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.reminderSaved)));
    }
  }

  void _applyPlan(int index) {
    final plan = plans[index];
    setState(() {
      _selectedPlan = index;
      _dailyDoseGoal = plan.dailyDoses;
      _intervalHours = plan.intervalHours;
      _startHourValue = plan.startHour;
    });
    _persistMedicationState();
    if (_remindersEnabled) {
      _syncReminderSchedule();
    }
  }

  Future<void> _addMedicationName() async {
    final value = _medicationController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (_medications.every((m) => m.name != value)) {
        _medications.add(MedicationItemState(name: value, takenToday: false, skippedToday: false));
      }
      _medicationController.clear();
    });
    await _persistMedicationState();
  }

  Future<void> _removeMedicationName(String name) async {
    setState(() => _medications.removeWhere((m) => m.name == name));
    await _persistMedicationState();
  }

  Future<void> _toggleMedication(MedicationItemState medication, bool taken) async {
    final copy = AppCopy.of(context);
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      final index = _medications.indexWhere((m) => m.name == medication.name);
      if (index >= 0) {
        _medications[index] = _medications[index].copyWith(takenToday: taken, skippedToday: !taken);
      }
      _takenDoses = _medications.where((m) => m.takenToday).length;
      _logs.insert(
        0,
        DoseLog(
          title: taken ? copy.logTakenAt(time, [medication.name]) : copy.logSkippedAt(time, [medication.name]),
          time: time,
          skipped: !taken,
          medicationNames: [medication.name],
        ),
      );
      if (_logs.length > 20) _logs.removeLast();
    });
    await _persistMedicationState();
    if (taken && _takenDoses >= _dailyDoseGoal) {
      _interstitialAd?.show();
      _interstitialAd = null;
      _loadInterstitial();
    }
  }

  Future<void> _markWholeCycle(bool skipped) async {
    final copy = AppCopy.of(context);
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final pending = _medications.where((m) => !m.takenToday && !m.skippedToday).toList();
    if (pending.isEmpty) return;
    final names = pending.map((m) => m.name).toList();
    setState(() {
      for (var i = 0; i < _medications.length; i++) {
        if (!_medications[i].takenToday && !_medications[i].skippedToday) {
          _medications[i] = _medications[i].copyWith(takenToday: !skipped, skippedToday: skipped);
        }
      }
      _takenDoses = _medications.where((m) => m.takenToday).length;
      _logs.insert(
        0,
        DoseLog(
          title: skipped ? copy.logSkippedAt(time, names) : copy.logTakenAt(time, names),
          time: time,
          skipped: skipped,
          medicationNames: names,
        ),
      );
      if (_logs.length > 20) _logs.removeLast();
    });
    await _persistMedicationState();
  }

  Future<void> _resetToday() async {
    setState(() {
      _takenDoses = 0;
      _logs.clear();
      for (var i = 0; i < _medications.length; i++) {
        _medications[i] = _medications[i].copyWith(takenToday: false, skippedToday: false);
      }
    });
    await _persistMedicationState();
  }

  double get _progress => (_takenDoses / (_dailyDoseGoal == 0 ? 1 : _dailyDoseGoal)).clamp(0.0, 1.0);
  String _nextReminderLabel(AppCopy copy) => copy.hourLabel(math.min(23, _startHourValue + (_takenDoses * _intervalHours)));
  int get _sevenDayTaken => _history.fold(0, (sum, item) => sum + item.takenCount);
  int get _sevenDayGoal => _history.fold(0, (sum, item) => sum + item.goalCount);
  int get _sevenDaySkipped => _history.fold(0, (sum, item) => sum + item.skippedCount);
  int get _sevenDayRate => _sevenDayGoal == 0 ? 0 : ((_sevenDayTaken / _sevenDayGoal) * 100).round();

  @override
  void dispose() {
    _medicationController.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    final selected = plans[_selectedPlan];
    final pages = [
      _HomeTab(
        copy: copy,
        plans: plans,
        selectedPlan: _selectedPlan,
        selected: selected,
        takenDoses: _takenDoses,
        dailyDoseGoal: _dailyDoseGoal,
        progress: _progress,
        nextReminder: _nextReminderLabel(copy),
        medications: _medications,
        onApplyPlan: _applyPlan,
        onMarkCycleTaken: () => _markWholeCycle(false),
        onMarkCycleSkipped: () => _markWholeCycle(true),
        onToggleMedication: _toggleMedication,
      ),
      _HistoryTab(copy: copy, logs: _logs, rate: _sevenDayRate, skipped: _sevenDaySkipped, checkedToday: _medications.where((m) => m.takenToday || m.skippedToday).length),
      _SettingsTab(
        copy: copy,
        remindersEnabled: _remindersEnabled,
        intervalHours: _intervalHours,
        startHourValue: _startHourValue,
        dailyDoseGoal: _dailyDoseGoal,
        medications: _medications,
        medicationController: _medicationController,
        doseOptions: _doseOptions,
        intervalOptions: _intervalOptions,
        startHourOptions: _startHourOptions,
        onReminderChanged: (value) async {
          setState(() => _remindersEnabled = value);
          await _syncReminderSchedule();
        },
        onDoseChanged: (value) async {
          setState(() => _dailyDoseGoal = value);
          await _persistMedicationState();
          if (_remindersEnabled) await _syncReminderSchedule();
        },
        onIntervalChanged: (value) async {
          setState(() => _intervalHours = value);
          await _persistMedicationState();
          if (_remindersEnabled) await _syncReminderSchedule();
        },
        onStartHourChanged: (value) async {
          setState(() => _startHourValue = value);
          await _persistMedicationState();
          if (_remindersEnabled) await _syncReminderSchedule();
        },
        onAddMedication: _addMedicationName,
        onRemoveMedication: _removeMedicationName,
        onResetToday: _resetToday,
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(copy.title),
        centerTitle: false,
        backgroundColor: const Color(0xFFF8F5FF),
        foregroundColor: const Color(0xFF25164D),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: pages[_selectedTab],
              ),
            ),
            _AdSlotPreview(copy: copy, bannerLoaded: _bannerLoaded, bannerAd: _bannerAd),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_rounded), label: copy.homeTab),
          NavigationDestination(icon: const Icon(Icons.receipt_long_rounded), label: copy.historyTab),
          NavigationDestination(icon: const Icon(Icons.settings_rounded), label: copy.settingsTab),
        ],
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.copy,
    required this.plans,
    required this.selectedPlan,
    required this.selected,
    required this.takenDoses,
    required this.dailyDoseGoal,
    required this.progress,
    required this.nextReminder,
    required this.medications,
    required this.onApplyPlan,
    required this.onMarkCycleTaken,
    required this.onMarkCycleSkipped,
    required this.onToggleMedication,
  });

  final AppCopy copy;
  final List<PillPlan> plans;
  final int selectedPlan;
  final PillPlan selected;
  final int takenDoses;
  final int dailyDoseGoal;
  final double progress;
  final String nextReminder;
  final List<MedicationItemState> medications;
  final ValueChanged<int> onApplyPlan;
  final VoidCallback onMarkCycleTaken;
  final VoidCallback onMarkCycleSkipped;
  final Future<void> Function(MedicationItemState, bool) onToggleMedication;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.subtitle, style: const TextStyle(color: Color(0xFF6C6192))),
          const SizedBox(height: 18),
          _HeroCard(copy: copy, takenDoses: takenDoses, dailyDoseGoal: dailyDoseGoal, progress: progress, nextReminder: nextReminder),
          const SizedBox(height: 18),
          _ActionCard(copy: copy, onAddDose: onMarkCycleTaken, onSkipDose: onMarkCycleSkipped),
          const SizedBox(height: 18),
          _MedicationChecklistCard(copy: copy, medications: medications, onToggleMedication: onToggleMedication),
          const SizedBox(height: 18),
          Text(copy.quickPlans, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = plans[index];
                return _PlanCard(
                  label: copy.planName(item.label),
                  detail: copy.planDetail(item.dailyDoses, item.intervalHours, item.startHour),
                  icon: item.icon,
                  selected: index == selectedPlan,
                  onTap: () => onApplyPlan(index),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: plans.length,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _MiniStatCard(title: copy.doseGoal, value: copy.doses(dailyDoseGoal), subtitle: copy.planName(selected.label), color: const Color(0xFF7A5AF8), icon: Icons.medication_liquid_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStatCard(title: copy.reminderInterval, value: copy.intervalLabel(selected.intervalHours), subtitle: copy.hourLabel(selected.startHour), color: const Color(0xFF5B3CD0), icon: Icons.alarm_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.copy, required this.logs, required this.rate, required this.skipped, required this.checkedToday});

  final AppCopy copy;
  final List<DoseLog> logs;
  final int rate;
  final int skipped;
  final int checkedToday;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _StatsCard(copy: copy, rate: rate, skipped: skipped, checkedToday: checkedToday),
          const SizedBox(height: 18),
          _LogCard(copy: copy, logs: logs),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.copy,
    required this.remindersEnabled,
    required this.intervalHours,
    required this.startHourValue,
    required this.dailyDoseGoal,
    required this.medications,
    required this.medicationController,
    required this.doseOptions,
    required this.intervalOptions,
    required this.startHourOptions,
    required this.onReminderChanged,
    required this.onDoseChanged,
    required this.onIntervalChanged,
    required this.onStartHourChanged,
    required this.onAddMedication,
    required this.onRemoveMedication,
    required this.onResetToday,
  });

  final AppCopy copy;
  final bool remindersEnabled;
  final int intervalHours;
  final int startHourValue;
  final int dailyDoseGoal;
  final List<MedicationItemState> medications;
  final TextEditingController medicationController;
  final List<int> doseOptions;
  final List<int> intervalOptions;
  final List<int> startHourOptions;
  final ValueChanged<bool> onReminderChanged;
  final ValueChanged<int> onDoseChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onStartHourChanged;
  final Future<void> Function() onAddMedication;
  final Future<void> Function(String) onRemoveMedication;
  final Future<void> Function() onResetToday;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.settingsTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF25164D))),
          const SizedBox(height: 8),
          Text(copy.notificationGuide, style: const TextStyle(color: Color(0xFF6C6192))),
          const SizedBox(height: 18),
          _ReminderStatusCard(copy: copy, enabled: remindersEnabled, intervalHours: intervalHours, onChanged: onReminderChanged),
          const SizedBox(height: 18),
          _SettingsCard(copy: copy, dailyDoseGoal: dailyDoseGoal, intervalHours: intervalHours, startHourValue: startHourValue, doseOptions: doseOptions, intervalOptions: intervalOptions, startHourOptions: startHourOptions, onDoseChanged: onDoseChanged, onIntervalChanged: onIntervalChanged, onStartHourChanged: onStartHourChanged),
          const SizedBox(height: 18),
          _MedicationManagerCard(copy: copy, medications: medications, controller: medicationController, onAddMedication: onAddMedication, onRemoveMedication: onRemoveMedication),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onResetToday,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(copy.resetToday),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.copy, required this.takenDoses, required this.dailyDoseGoal, required this.progress, required this.nextReminder});

  final AppCopy copy;
  final int takenDoses;
  final int dailyDoseGoal;
  final double progress;
  final String nextReminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7A5AF8), Color(0xFFB18FFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Color(0x337A5AF8), blurRadius: 28, offset: Offset(0, 14))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassBadge(text: copy.todayChecklist),
              _GlassBadge(text: '${copy.nextReminder} · $nextReminder'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size(250, 250), painter: _RingPainter(progress: progress)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(copy.completionText(takenDoses, dailyDoseGoal), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Text(copy.rateText((progress * 100).round()), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (takenDoses >= dailyDoseGoal) Text(copy.goalReached, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.copy, required this.onAddDose, required this.onSkipDose});

  final AppCopy copy;
  final VoidCallback onAddDose;
  final VoidCallback onSkipDose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddDose,
              icon: const Icon(Icons.check_rounded),
              label: Text(copy.addDose),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSkipDose,
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(copy.skipDose),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationChecklistCard extends StatelessWidget {
  const _MedicationChecklistCard({required this.copy, required this.medications, required this.onToggleMedication});

  final AppCopy copy;
  final List<MedicationItemState> medications;
  final Future<void> Function(MedicationItemState, bool) onToggleMedication;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.medications, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF25164D))),
          const SizedBox(height: 14),
          if (medications.isEmpty)
            Text(copy.emptyLog, style: const TextStyle(color: Color(0xFF7B74A3)))
          else
            ...medications.map((med) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF7F2FF), borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF25164D))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: FilledButton.tonal(onPressed: () => onToggleMedication(med, true), child: Text(copy.takenLabel))),
                          const SizedBox(width: 10),
                          Expanded(child: FilledButton.tonal(onPressed: () => onToggleMedication(med, false), child: Text(copy.skippedLabel))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(med.takenToday ? copy.takenLabel : med.skippedToday ? copy.skippedLabel : '-', style: const TextStyle(color: Color(0xFF7B74A3))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _MedicationManagerCard extends StatelessWidget {
  const _MedicationManagerCard({required this.copy, required this.medications, required this.controller, required this.onAddMedication, required this.onRemoveMedication});

  final AppCopy copy;
  final List<MedicationItemState> medications;
  final TextEditingController controller;
  final Future<void> Function() onAddMedication;
  final Future<void> Function(String) onRemoveMedication;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.medications, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF25164D))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: copy.medicationHint,
                    filled: true,
                    fillColor: const Color(0xFFF7F2FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => onAddMedication(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: onAddMedication, child: Text(copy.addMedication)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: medications
                .map((med) => Chip(
                      label: Text(med.name),
                      onDeleted: () => onRemoveMedication(med.name),
                      deleteIconColor: const Color(0xFF6C6192),
                      backgroundColor: const Color(0xFFF2ECFF),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text('${copy.medsCountSetting}: ${copy.countLabel(medications.length)}', style: const TextStyle(color: Color(0xFF7B74A3))),
        ],
      ),
    );
  }
}

class _HistoryTabPlaceholder extends StatelessWidget {
  const _HistoryTabPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ReminderStatusCard extends StatelessWidget {
  const _ReminderStatusCard({required this.copy, required this.enabled, required this.intervalHours, required this.onChanged});

  final AppCopy copy;
  final bool enabled;
  final int intervalHours;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFF7A5AF8).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF7A5AF8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copy.reminderStatus, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF25164D))),
                    const SizedBox(height: 4),
                    Text(enabled ? copy.reminderOn : copy.reminderOff, style: const TextStyle(color: Color(0xFF6C6192), height: 1.35)),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 12),
          Text(copy.intervalLabel(intervalHours), style: const TextStyle(color: Color(0xFF5B3CD0), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.label, required this.detail, required this.icon, required this.selected, required this.onTap});

  final String label;
  final String detail;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width < 380 ? 152.0 : 168.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: cardWidth,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF25164D) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: selected ? const Color(0x2625164D) : const Color(0x10000000), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? Colors.white : const Color(0xFF7A5AF8)),
            const SizedBox(height: 14),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? Colors.white : const Color(0xFF25164D), fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(detail, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? Colors.white70 : const Color(0xFF6C6192), height: 1.25)),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({required this.title, required this.value, required this.subtitle, required this.color, required this.icon});

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color),
              ),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6C6192))),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF25164D))),
          const SizedBox(height: 6),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7B74A3))),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.copy, required this.rate, required this.skipped, required this.checkedToday});

  final AppCopy copy;
  final int rate;
  final int skipped;
  final int checkedToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          Expanded(child: _MiniStatCard(title: copy.sevenDaySuccess, value: copy.rateText(rate), subtitle: copy.adherenceStats, color: const Color(0xFF7A5AF8), icon: Icons.query_stats_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _MiniStatCard(title: copy.missedCount, value: '$skipped', subtitle: '${copy.checkedToday} $checkedToday', color: const Color(0xFFB45AF8), icon: Icons.history_toggle_off_rounded)),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.copy, required this.dailyDoseGoal, required this.intervalHours, required this.startHourValue, required this.doseOptions, required this.intervalOptions, required this.startHourOptions, required this.onDoseChanged, required this.onIntervalChanged, required this.onStartHourChanged});

  final AppCopy copy;
  final int dailyDoseGoal;
  final int intervalHours;
  final int startHourValue;
  final List<int> doseOptions;
  final List<int> intervalOptions;
  final List<int> startHourOptions;
  final ValueChanged<int> onDoseChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onStartHourChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.currentCycle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF25164D))),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 500;
              final children = [
                _PickerTile(label: copy.doseGoal, value: dailyDoseGoal, textForValue: copy.doses, icon: Icons.medication_rounded, onChanged: onDoseChanged, values: doseOptions),
                _PickerTile(label: copy.reminderInterval, value: intervalHours, textForValue: copy.intervalLabel, icon: Icons.av_timer_rounded, onChanged: onIntervalChanged, values: intervalOptions),
                _PickerTile(label: copy.startHour, value: startHourValue, textForValue: copy.hourLabel, icon: Icons.access_time_rounded, onChanged: onStartHourChanged, values: startHourOptions),
              ];
              if (isCompact) {
                return Column(children: [for (var i = 0; i < children.length; i++) ...[children[i], if (i != children.length - 1) const SizedBox(height: 12)]]);
              }
              return Row(children: [Expanded(child: children[0]), const SizedBox(width: 12), Expanded(child: children[1]), const SizedBox(width: 12), Expanded(child: children[2])]);
            },
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.label, required this.value, required this.textForValue, required this.icon, required this.onChanged, required this.values});

  final String label;
  final int value;
  final String Function(int) textForValue;
  final IconData icon;
  final ValueChanged<int> onChanged;
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF7F2FF), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7A5AF8)),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF25164D))),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            items: values.map((v) => DropdownMenuItem(value: v, child: Text(textForValue(v)))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.copy});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF25164D), borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(copy.notificationGuide, style: const TextStyle(color: Colors.white, height: 1.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.copy, required this.logs});

  final AppCopy copy;
  final List<DoseLog> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.recentLog, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF25164D))),
          const SizedBox(height: 14),
          if (logs.isEmpty)
            Text(copy.emptyLog, style: const TextStyle(color: Color(0xFF7B74A3)))
          else
            ...logs.map((log) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF7F2FF), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: log.skipped ? const Color(0xFFB8AECF) : const Color(0xFF7A5AF8), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF25164D))),
                            const SizedBox(height: 4),
                            Text(log.medicationNames.join(', '), style: const TextStyle(color: Color(0xFF7B74A3))),
                          ],
                        ),
                      ),
                      Text(log.time, style: const TextStyle(color: Color(0xFF7B74A3))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _AdSlotPreview extends StatelessWidget {
  const _AdSlotPreview({required this.copy, required this.bannerLoaded, required this.bannerAd});

  final AppCopy copy;
  final bool bannerLoaded;
  final BannerAd? bannerAd;

  @override
  Widget build(BuildContext context) {
    final hasRealBanner = !kIsWeb && bannerLoaded && bannerAd != null;
    if (!hasRealBanner) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: bannerAd!),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const start = -math.pi / 2;
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..shader = const LinearGradient(colors: [Colors.white, Color(0xFFF0E7FF)]).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(18), 0, math.pi * 2, false, bgPaint);
    canvas.drawArc(rect.deflate(18), start, math.pi * 2 * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}
