import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'services/ad_config_service.dart';
import 'services/medication_log_service.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  String get subtitle => isKorean
      ? '놓치기 쉬운 복약 루틴을 가볍게 관리하세요.'
      : 'Keep your daily medication routine clear and repeatable.';
  String get todayChecklist => isKorean ? '오늘 복약 현황' : 'Today Checklist';
  String get quickPlans => isKorean ? '빠른 복약 플랜' : 'Quick Plans';
  String get reminderStatus => isKorean ? '백그라운드 알림' : 'Background Reminders';
  String get reminderOn => isKorean ? '앱을 닫아도 정해둔 복약 시간에 로컬 알림이 계속 울립니다.' : 'Local medication reminders keep firing even after the app is closed.';
  String get reminderOff => isKorean ? '현재 복약 알림이 꺼져 있습니다.' : 'Medication reminders are currently turned off.';
  String get reminderPermissionDenied => isKorean ? '알림 권한이 없어 복약 알림을 켤 수 없습니다.' : 'Notification permission was denied, so reminders could not be enabled.';
  String get reminderSaved => isKorean ? '복약 알림 일정이 저장되었습니다.' : 'Medication reminder schedule saved.';
  String get addDose => isKorean ? '복용 체크' : 'Mark as Taken';
  String get skipDose => isKorean ? '이번 회차 건너뛰기' : 'Skip This Dose';
  String get resetToday => isKorean ? '오늘 초기화' : 'Reset Today';
  String get doseGoal => isKorean ? '하루 복약 횟수' : 'Daily Dose Goal';
  String get reminderInterval => isKorean ? '복약 간격' : 'Reminder Interval';
  String get startHour => isKorean ? '시작 시간' : 'Start Time';
  String get recentLog => isKorean ? '최근 복약 기록' : 'Recent Medication Log';
  String get medications => isKorean ? '복약 목록' : 'Medication List';
  String get medicationHint => isKorean ? '예: 비타민 D, 감기약, 항생제' : 'e.g. Vitamin D, cold medicine, antibiotics';
  String get addMedication => isKorean ? '약 추가' : 'Add Medication';
  String get adherenceInsight => isKorean ? '복약 리듬 인사이트' : 'Adherence Insight';
  String get emptyLog => isKorean ? '아직 기록이 없습니다.' : 'No medication logs yet.';
  String get goalReached => isKorean ? '오늘 복약 목표를 채웠습니다.' : 'You completed today\'s medication goal.';
  String get bannerPlaceholder => isKorean
      ? '배너 광고 영역 · 관리자 설정에 따라 테스트 또는 릴리즈 광고가 표시됩니다.'
      : 'Banner ad area · test or release ad units are loaded from admin settings.';
  String get adHint => isKorean
      ? '배너는 하단에 고정하고, 전면광고는 하루 복약 목표를 채운 뒤처럼 의미 있는 시점에만 노출되도록 설계했습니다.'
      : 'Banner ads stay in a stable bottom slot, and interstitials appear around meaningful completion moments instead of interrupting every check-in.';
  String get doseCardTitle => isKorean ? '지금 챙길 약' : 'Current Medication Cycle';
  String get nextReminder => isKorean ? '다음 알림' : 'Next Reminder';
  String doses(int value) => isKorean ? '$value회' : '$value doses';
  String intervalLabel(int hours) => isKorean ? '$hours시간 간격' : 'Every $hours hours';
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
      : '${doses} doses · every $hours hours · starts ${hourLabel(startHour)}';

  String completionText(int taken, int total) => isKorean ? '$taken / $total회 완료' : '$taken / $total completed';
  String streakText(int value) => isKorean ? '최근 $value회 연속 체크' : '$value recent check-ins';
  String logTakenAt(String time) => isKorean ? '$time 복용 완료' : '$time marked as taken';
  String logSkippedAt(String time) => isKorean ? '$time 이번 회차 건너뜀' : '$time dose skipped';
}

class PillPlan {
  const PillPlan({
    required this.label,
    required this.dailyDoses,
    required this.intervalHours,
    required this.startHour,
    required this.icon,
  });

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
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F5FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A5AF8),
          brightness: Brightness.light,
        ),
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
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _bannerLoaded = false;

  int _selectedPlan = 1;
  int _takenDoses = 0;
  int _dailyDoseGoal = 3;
  int _intervalHours = 8;
  int _startHourValue = 8;
  bool _remindersEnabled = false;
  final List<DoseLog> _logs = [];
  final List<String> _medicationNames = [];
  final TextEditingController _medicationController = TextEditingController();

  List<int> get _doseOptions {
    final values = {1, 2, 3, 4, 5, 6, ...plans.map((plan) => plan.dailyDoses), _dailyDoseGoal}.toList()..sort();
    return values;
  }

  List<int> get _intervalOptions {
    final values = {4, 6, 8, 12, ...plans.map((plan) => plan.intervalHours), _intervalHours}.toList()..sort();
    return values;
  }

  List<int> get _startHourOptions {
    final values = {6, 7, 8, 9, 10, 12, ...plans.map((plan) => plan.startHour), _startHourValue}.toList()..sort();
    return values;
  }

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
      _medicationNames
        ..clear()
        ..addAll(snapshot.medicationNames);
      _logs
        ..clear()
        ..addAll(snapshot.logs.map((log) => DoseLog(title: log.title, time: log.time, skipped: log.skipped, medicationNames: log.medicationNames)));
    });
  }

  Future<void> _persistMedicationState() async {
    await MedicationLogService.instance.saveState(
      takenDoses: _takenDoses,
      dailyDoseGoal: _dailyDoseGoal,
      intervalHours: _intervalHours,
      startHour: _startHourValue,
      selectedPlan: _selectedPlan,
      medicationNames: List<String>.from(_medicationNames),
      logs: _logs
          .map((log) => MedicationLogEntry(
                title: log.title,
                time: log.time,
                skipped: log.skipped,
                medicationNames: log.medicationNames,
                dateKey: MedicationLogService.instance.todayKey(),
              ))
          .toList(),
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
        if (mounted) {
          setState(() => _remindersEnabled = false);
        }
        await _reminderService.saveSettings(settings.copyWith(enabled: false));
        await _reminderService.cancelMedicationReminders();
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.reminderPermissionDenied)));
        }
        return;
      }
    }
    await _reminderService.syncMedicationReminders(
      settings: settings,
      dailyDoses: _dailyDoseGoal,
      isKorean: copy.isKorean,
    );
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
      if (!_medicationNames.contains(value)) {
        _medicationNames.add(value);
      }
      _medicationController.clear();
    });
    await _persistMedicationState();
  }

  Future<void> _removeMedicationName(String name) async {
    setState(() => _medicationNames.remove(name));
    await _persistMedicationState();
  }

  void _addDose(AppCopy copy, {required bool skipped}) {
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final next = skipped ? _takenDoses : (_takenDoses + 1);
    setState(() {
      _takenDoses = next;
      _logs.insert(0, DoseLog(
        title: skipped ? copy.logSkippedAt(time) : copy.logTakenAt(time),
        time: time,
        skipped: skipped,
        medicationNames: List<String>.from(_medicationNames),
      ));
      if (_logs.length > 8) _logs.removeLast();
    });
    _persistMedicationState();
    if (!skipped && next >= _dailyDoseGoal) {
      _interstitialAd?.show();
      _interstitialAd = null;
      _loadInterstitial();
    }
  }

  void _resetToday() {
    setState(() {
      _takenDoses = 0;
      _logs.clear();
    });
    _persistMedicationState();
  }

  double get _progress => (_takenDoses / _dailyDoseGoal).clamp(0.0, 1.0);

  String _nextReminderLabel(AppCopy copy) {
    final nextHour = math.min(23, _startHourValue + (_takenDoses * _intervalHours));
    return copy.hourLabel(nextHour);
  }

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(copy: copy, takenDoses: _takenDoses),
                    const SizedBox(height: 20),
                    _HeroCard(
                      copy: copy,
                      takenDoses: _takenDoses,
                      dailyDoseGoal: _dailyDoseGoal,
                      progress: _progress,
                      nextReminder: _nextReminderLabel(copy),
                    ),
                    const SizedBox(height: 18),
                    _ActionCard(
                      copy: copy,
                      onAddDose: () => _addDose(copy, skipped: false),
                      onSkipDose: () => _addDose(copy, skipped: true),
                      onResetToday: _resetToday,
                    ),
                    const SizedBox(height: 18),
                    _MedicationNamesCard(
                      copy: copy,
                      medicationNames: _medicationNames,
                      controller: _medicationController,
                      onAdd: _addMedicationName,
                      onRemove: _removeMedicationName,
                    ),
                    const SizedBox(height: 18),
                    _ReminderStatusCard(
                      copy: copy,
                      enabled: _remindersEnabled,
                      intervalHours: _intervalHours,
                      onChanged: (value) async {
                        setState(() => _remindersEnabled = value);
                        await _syncReminderSchedule();
                      },
                    ),
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
                            selected: index == _selectedPlan,
                            onTap: () => _applyPlan(index),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: plans.length,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 340;
                        final cards = [
                          _MiniStatCard(
                            title: copy.doseGoal,
                            value: copy.doses(_dailyDoseGoal),
                            subtitle: copy.planName(selected.label),
                            color: const Color(0xFF7A5AF8),
                            icon: Icons.medication_liquid_rounded,
                          ),
                          _MiniStatCard(
                            title: copy.reminderInterval,
                            value: copy.intervalLabel(_intervalHours),
                            subtitle: copy.hourLabel(_startHourValue),
                            color: const Color(0xFF5B3CD0),
                            icon: Icons.alarm_rounded,
                          ),
                        ];
                        if (isCompact) {
                          return Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
                        }
                        return Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]);
                      },
                    ),
                    const SizedBox(height: 18),
                    _SettingsCard(
                      copy: copy,
                      dailyDoseGoal: _dailyDoseGoal,
                      intervalHours: _intervalHours,
                      startHourValue: _startHourValue,
                      doseOptions: _doseOptions,
                      intervalOptions: _intervalOptions,
                      startHourOptions: _startHourOptions,
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
                    ),
                    const SizedBox(height: 18),
                    _InsightCard(copy: copy),
                    const SizedBox(height: 18),
                    _LogCard(copy: copy, logs: _logs),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: _AdSlotPreview(copy: copy, bannerLoaded: _bannerLoaded, bannerAd: _bannerAd),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.copy, required this.takenDoses});
  final AppCopy copy;
  final int takenDoses;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF25164D))),
              const SizedBox(height: 6),
              Text(copy.subtitle, style: const TextStyle(color: Color(0xFF6C6192))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              const Icon(Icons.medication_rounded, color: Color(0xFF7A5AF8)),
              const SizedBox(height: 4),
              Text('$takenDoses', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ),
      ],
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
              _GlassBadge(text: copy.nextReminder + ' · ' + nextReminder),
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
                    Text(copy.streakText(takenDoses), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (takenDoses >= dailyDoseGoal)
                      Text(copy.goalReached, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
          boxShadow: [BoxShadow(color: selected ? const Color(0x2625164D) : const Color(0x10000000), blurRadius: 18, offset: const Offset(0, 8))],
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.copy, required this.onAddDose, required this.onSkipDose, required this.onResetToday});
  final AppCopy copy;
  final VoidCallback onAddDose;
  final VoidCallback onSkipDose;
  final VoidCallback onResetToday;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final mainButton = FilledButton.icon(
          onPressed: onAddDose,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7A5AF8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: const Icon(Icons.check_rounded),
          label: Text(copy.addDose),
        );
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            children: [
              if (isCompact)
                SizedBox(width: double.infinity, child: mainButton)
              else
                Row(children: [Expanded(flex: 2, child: mainButton), const SizedBox(width: 12), Expanded(child: OutlinedButton(onPressed: onSkipDose, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text(copy.skipDose)))]),
              if (isCompact) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onSkipDose, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text(copy.skipDose))),
              ],
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: TextButton(onPressed: onResetToday, child: Text(copy.resetToday))),
            ],
          ),
        );
      },
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
          Text(copy.doseCardTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF25164D))),
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
          Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.insights_rounded, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(child: Text(copy.adHint, style: const TextStyle(color: Colors.white, height: 1.5, fontWeight: FontWeight.w600))),
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
            ...logs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: log.skipped ? const Color(0xFFB8AECF) : const Color(0xFF7A5AF8), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(log.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF25164D)))),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE5DAFF))),
      child: hasRealBanner
          ? SizedBox(height: bannerAd!.size.height.toDouble(), width: bannerAd!.size.width.toDouble(), child: AdWidget(ad: bannerAd!))
          : Row(children: [const Icon(Icons.campaign_outlined, color: Color(0xFF8F80BF)), const SizedBox(width: 10), Expanded(child: Text(copy.bannerPlaceholder, style: const TextStyle(color: Color(0xFF6C6192), fontWeight: FontWeight.w600)))]),
    );
  }
}

class _MedicationNamesCard extends StatelessWidget {
  const _MedicationNamesCard({
    required this.copy,
    required this.medicationNames,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  final AppCopy copy;
  final List<String> medicationNames;
  final TextEditingController controller;
  final Future<void> Function() onAdd;
  final Future<void> Function(String) onRemove;

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
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: onAdd, child: Text(copy.addMedication)),
            ],
          ),
          const SizedBox(height: 14),
          if (medicationNames.isEmpty)
            Text(copy.emptyLog, style: const TextStyle(color: Color(0xFF7B74A3)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medicationNames
                  .map((name) => Chip(
                        label: Text(name),
                        onDeleted: () => onRemove(name),
                        deleteIconColor: const Color(0xFF6C6192),
                        backgroundColor: const Color(0xFFF2ECFF),
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
