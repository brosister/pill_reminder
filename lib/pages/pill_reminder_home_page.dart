import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/app_copy.dart';
import '../models/pill_models.dart';
import '../services/ad_config_service.dart';
import '../services/medication_log_service.dart';
import '../services/reminder_service.dart';
import '../services/toast_service.dart';
import '../widgets/pill_shared_widgets.dart';
import 'history_page.dart';
import 'pill_tracker_page.dart';
import 'settings_page.dart';
import 'stats_dashboard_page.dart';

class PillReminderHomePage extends StatefulWidget {
  const PillReminderHomePage({super.key});

  @override
  State<PillReminderHomePage> createState() => _PillReminderHomePageState();
}

class _PillReminderHomePageState extends State<PillReminderHomePage> {
  static const double _baseBottomOverlayPadding = 118;

  final AdConfigService _adConfig = AdConfigService();
  final ReminderService _reminderService = ReminderService.instance;
  final TextEditingController _medicationController = TextEditingController();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _bannerLoaded = false;
  int? _loadedBannerWidth;

  int _selectedPlan = 1;
  int _selectedTab = 0;
  int _takenDoses = 0;
  final List<String> _cycleStatuses = [];
  int _dailyDoseGoal = 3;
  int _intervalHours = 8;
  int _startHourValue = 8;
  List<String> _doseMoments = const ['morning', 'lunch', 'evening'];
  Map<String, int> _reminderTimes = const {};
  bool _remindersEnabled = false;
  final List<DoseLog> _logs = [];
  final List<MedicationItemState> _medications = [];
  final List<DailyMedicationSummary> _history = [];

  void _normalizeCycleProgress() {
    if (_cycleStatuses.length > _dailyDoseGoal) {
      _cycleStatuses.removeRange(_dailyDoseGoal, _cycleStatuses.length);
    }
    _takenDoses = _cycleStatuses.where((status) => status == 'taken').length;
  }

  @override
  void initState() {
    super.initState();
    _loadMedicationState();
    _loadReminderSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || _loadedBannerWidth == width) return;
    _loadedBannerWidth = width;
    _initAds(width);
  }

  Future<void> _loadMedicationState() async {
    final snapshot = await MedicationLogService.instance.load();
    if (!mounted) return;
    setState(() {
      _selectedPlan = snapshot.selectedPlan;
      _cycleStatuses
        ..clear()
        ..addAll(snapshot.cycleStatuses);
      _dailyDoseGoal = snapshot.dailyDoseGoal;
      _intervalHours = snapshot.intervalHours;
      _startHourValue = snapshot.startHour;
      _doseMoments = _normalizeDoseMoments(
        snapshot.doseMoments,
        snapshot.dailyDoseGoal,
      );
      _takenDoses = snapshot.takenDoses;
      _normalizeCycleProgress();
      _medications
        ..clear()
        ..addAll(snapshot.medications);
      _logs
        ..clear()
        ..addAll(
          snapshot.logs.map(
            (log) => DoseLog(
              title: log.title,
              time: log.time,
              skipped: log.skipped,
              medicationNames: log.medicationNames,
              dateKey: log.dateKey,
            ),
          ),
        );
      _history
        ..clear()
        ..addAll(snapshot.history);
    });
  }

  Future<void> _persistMedicationState() async {
    await MedicationLogService.instance.saveState(
      takenDoses: _takenDoses,
      cycleStatuses: List<String>.from(_cycleStatuses),
      dailyDoseGoal: _dailyDoseGoal,
      intervalHours: _intervalHours,
      startHour: _startHourValue,
      doseMoments: List<String>.from(_doseMoments),
      selectedPlan: _selectedPlan,
      medications: List<MedicationItemState>.from(_medications),
      logs: _logs
          .map(
            (log) => MedicationLogEntry(
              title: log.title,
              time: log.time,
              skipped: log.skipped,
              medicationNames: log.medicationNames,
              dateKey: log.dateKey,
            ),
          )
          .toList(),
      history: List<DailyMedicationSummary>.from(_history),
    );
  }

  Future<void> _loadReminderSettings() async {
    final settings = await _reminderService.loadSettings();
    if (!mounted) return;
    setState(() {
      _remindersEnabled = settings.enabled;
      _reminderTimes = Map<String, int>.from(settings.slotTimes);
    });
    if (_remindersEnabled) {
      await _syncReminderSchedule(silent: true);
    }
  }

  Future<void> _initAds(int width) async {
    if (kIsWeb) return;
    await _adConfig.loadConfig();
    final adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || adaptiveSize == null) return;
    await _bannerAd?.dispose();
    final banner = BannerAd(
      adUnitId: _adConfig.bannerAdId,
      size: adaptiveSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            if (identical(_bannerAd, ad)) {
              _bannerAd = null;
            }
            _bannerLoaded = false;
          });
        },
      ),
    );
    _bannerAd = banner;
    _bannerLoaded = false;
    await banner.load();
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

  Future<bool> _syncReminderSchedule({bool silent = false}) async {
    final copy = AppCopy.of(context);
    final slotKeys = _currentReminderSlots();
    final settings = ReminderSettings(
      enabled: _remindersEnabled,
      slotTimes: _resolvedReminderTimes(slotKeys),
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
        if (!silent) {
          await ToastService.show(copy.reminderPermissionDenied);
        }
        return false;
      }
    }
    await _reminderService.syncMedicationReminders(
      settings: settings,
      slotKeys: slotKeys,
      isKorean: copy.isKorean,
    );
    if (!silent) {
      await ToastService.show(copy.reminderSaved);
    }
    return _remindersEnabled;
  }

  List<String> _defaultDoseMoments(int dailyDoseGoal) {
    return MedicationLogService.instance.defaultDoseMoments(dailyDoseGoal);
  }

  List<String> _normalizeDoseMoments(List<String> source, int dailyDoseGoal) {
    if (dailyDoseGoal >= 4) {
      return _defaultDoseMoments(dailyDoseGoal);
    }
    const allowed = {'morning', 'lunch', 'evening'};
    final filtered = <String>[];
    for (final item in source) {
      if (!allowed.contains(item)) continue;
      if (filtered.contains(item)) continue;
      filtered.add(item);
      if (filtered.length >= dailyDoseGoal) break;
    }
    return filtered;
  }

  Future<void> _setDoseMoments(List<String> value) async {
    setState(() {
      _doseMoments = _normalizeDoseMoments(value, _dailyDoseGoal);
    });
    await _persistMedicationState();
    if (_remindersEnabled) await _syncReminderSchedule();
  }

  List<String> _currentReminderSlots() {
    if (_dailyDoseGoal >= 4) {
      return _defaultDoseMoments(_dailyDoseGoal);
    }
    final normalized = _normalizeDoseMoments(_doseMoments, _dailyDoseGoal);
    if (normalized.isEmpty) {
      return _defaultDoseMoments(_dailyDoseGoal).take(1).toList();
    }
    return normalized;
  }

  Map<String, int> _resolvedReminderTimes(List<String> slotKeys) {
    final next = <String, int>{};
    for (var index = 0; index < slotKeys.length; index++) {
      final key = slotKeys[index];
      next[key] = _reminderTimes[key] ??
          _reminderService.defaultReminderMinutes(key, index);
    }
    return next;
  }

  Future<void> _setReminderTime(String slotKey, int minutes) async {
    setState(() {
      _reminderTimes = {
        ..._reminderTimes,
        slotKey: minutes,
      };
    });
    if (_remindersEnabled) {
      await _syncReminderSchedule();
    } else {
      await _reminderService.saveSettings(
        ReminderSettings(
          enabled: _remindersEnabled,
          slotTimes: _resolvedReminderTimes(_currentReminderSlots()),
        ),
      );
    }
  }

  Future<void> _addMedicationName() async {
    final value = _medicationController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (_medications.every((m) => m.name != value)) {
        _medications.add(
          MedicationItemState(
            name: value,
            takenToday: false,
            skippedToday: false,
          ),
        );
      }
      _medicationController.clear();
    });
    await _persistMedicationState();
  }

  Future<void> _removeMedicationName(String name) async {
    setState(() => _medications.removeWhere((m) => m.name == name));
    await _persistMedicationState();
  }

  Future<void> _markWholeCycle(bool skipped, [int? slotIndex]) async {
    final copy = AppCopy.of(context);
    final now = TimeOfDay.now();
    final todayKey = MedicationLogService.instance.todayKey();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final names = _medications.map((m) => m.name).toList();
    setState(() {
      final targetIndex = slotIndex ?? _cycleStatuses.length;
      if (targetIndex < _dailyDoseGoal) {
        while (_cycleStatuses.length <= targetIndex) {
          _cycleStatuses.add('pending');
        }
        _cycleStatuses[targetIndex] = skipped ? 'skipped' : 'taken';
      }
      _takenDoses =
          _cycleStatuses.where((status) => status == 'taken').length;
      _logs.insert(
        0,
        DoseLog(
          title: skipped
              ? copy.logSkippedAt(time, names)
              : copy.logTakenAt(time, names),
          time: time,
          skipped: skipped,
          medicationNames: names,
          dateKey: todayKey,
        ),
      );
      if (_logs.length > 20) _logs.removeLast();
    });
    await _persistMedicationState();
    if (!skipped && _takenDoses >= _dailyDoseGoal) {
      _interstitialAd?.show();
      _interstitialAd = null;
      _loadInterstitial();
    }
  }

  Future<void> _resetToday() async {
    final copy = AppCopy.of(context);
    final todayKey = MedicationLogService.instance.todayKey();
    setState(() {
      _takenDoses = 0;
      _cycleStatuses.clear();
      _logs.removeWhere((log) => log.dateKey == todayKey);
      for (var i = 0; i < _medications.length; i++) {
        _medications[i] = _medications[i].copyWith(
          takenToday: false,
          skippedToday: false,
        );
      }
    });
    await _persistMedicationState();
    await ToastService.show(copy.todayResetDone);
  }

  DailyMedicationSummary get _todaySummary => DailyMedicationSummary(
        dateKey: MedicationLogService.instance.todayKey(),
        takenCount: _takenDoses,
        skippedCount:
            _cycleStatuses.where((status) => status == 'skipped').length,
        goalCount: _dailyDoseGoal,
      );

  List<DailyMedicationSummary> get _sevenDaySummaries {
    final weekStartDate = MedicationLogService.instance.weekStart();
    final todayKey = _todaySummary.dateKey;
    final recentHistory = _history
        .where((item) {
          final date = DateTime.tryParse(item.dateKey);
          return date != null &&
              !date.isBefore(weekStartDate) &&
              item.dateKey != todayKey;
        })
        .toList();
    return [...recentHistory, _todaySummary];
  }

  int get _sevenDayTaken =>
      _sevenDaySummaries.fold(0, (sum, item) => sum + item.takenCount);
  int get _sevenDayGoal =>
      _sevenDaySummaries.fold(0, (sum, item) => sum + item.goalCount);
  int get _sevenDaySkipped =>
      _sevenDaySummaries.fold(0, (sum, item) => sum + item.skippedCount);
  int get _sevenDayRate =>
      _sevenDayGoal == 0 ? 0 : ((_sevenDayTaken / _sevenDayGoal) * 100).round();

  List<DailyPillCount> get _weeklyCounts {
    final start = MedicationLogService.instance.weekStart();
    final byDate = {for (final item in _sevenDaySummaries) item.dateKey: item};

    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final key = MedicationLogService.instance.todayKey(day);
      final entry = byDate[key];
      return DailyPillCount(
        day: day,
        takenCount: entry?.takenCount ?? 0,
        goalCount: entry?.goalCount ?? 0,
      );
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PillSettingsPage(
          copy: AppCopy.of(context),
          remindersEnabled: _remindersEnabled,
          dailyDoseGoal: _dailyDoseGoal,
          doseMoments: _doseMoments,
          reminderTimes: _resolvedReminderTimes(_currentReminderSlots()),
          medications: _medications,
          medicationController: _medicationController,
          onReminderChanged: (value) async {
            setState(() => _remindersEnabled = value);
            return _syncReminderSchedule();
          },
          onReminderTimeChanged: _setReminderTime,
          onAddMedication: _addMedicationName,
          onRemoveMedication: _removeMedicationName,
          onResetToday: _resetToday,
        ),
      ),
    );
  }

  Future<void> _setDailyDoseGoal(int value) async {
    setState(() {
      _dailyDoseGoal = value;
      _doseMoments = _defaultDoseMoments(value);
      _normalizeCycleProgress();
    });
    await _persistMedicationState();
    if (_remindersEnabled) await _syncReminderSchedule();
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PillHistoryPage(
          copy: AppCopy.of(context),
          logs: _logs,
        ),
      ),
    );
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final hasVisibleBanner = _bannerLoaded && _bannerAd != null;
    final bannerHeight = hasVisibleBanner ? _bannerAd!.size.height.toDouble() : 0;
    final bottomOverlayPadding =
        _baseBottomOverlayPadding + bottomInset + bannerHeight;
    final pages = [
      PillTrackerPage(
        copy: copy,
        dailyDoseGoal: _dailyDoseGoal,
        doseMoments: _doseMoments,
        cycleStatuses: _cycleStatuses,
        sevenDaySummaries: _sevenDaySummaries,
        onDoseChanged: _setDailyDoseGoal,
        onDoseMomentsChanged: _setDoseMoments,
        onMarkTaken: (slotIndex) => _markWholeCycle(false, slotIndex),
        onMarkSkipped: (slotIndex) => _markWholeCycle(true, slotIndex),
        onOpenHistory: _openHistory,
        onOpenSettings: _openSettings,
        bottomPadding: bottomOverlayPadding,
      ),
      StatsDashboardPage(
        copy: copy,
        weeklyCounts: _weeklyCounts,
        rate: _sevenDayRate,
        skipped: _sevenDaySkipped,
        checkedToday:
            _medications.where((m) => m.takenToday || m.skippedToday).length,
        bottomPadding: bottomOverlayPadding,
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: _selectedTab == 0
          ? _HomeTrackerAppBar(
              copy: copy,
              date: DateTime.now(),
              title: copy.trackerTitle,
              onOpenHistory: _openHistory,
              onOpenSettings: _openSettings,
            )
          : _HomeTrackerAppBar(
              copy: copy,
              date: DateTime.now(),
              title: copy.statsTitle,
              onOpenHistory: _openHistory,
              onOpenSettings: _openSettings,
            ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _selectedTab, children: pages),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PillBottomNav(
                  items: [
                    PillNavItemData(
                      label: copy.homeTab,
                      icon: Icons.home_rounded,
                      color: const Color(0xFF7A5AF8),
                    ),
                    PillNavItemData(
                      label: copy.statsTab,
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF7A5AF8),
                    ),
                  ],
                  selectedIndex: _selectedTab,
                  onSelected: (value) => setState(() => _selectedTab = value),
                  extraBottomPadding: hasVisibleBanner ? 0 : bottomInset,
                ),
                if (hasVisibleBanner)
                  Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: SizedBox(
                      width: double.infinity,
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTrackerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _HomeTrackerAppBar({
    required this.copy,
    required this.date,
    required this.title,
    required this.onOpenHistory,
    required this.onOpenSettings,
  });

  final AppCopy copy;
  final DateTime date;
  final String title;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 96,
      titleSpacing: 24,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E2274),
                  letterSpacing: -1.0,
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            copy.fullDate(date),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF5B5890),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
          ),
        ],
      ),
      actions: [
        _HeaderActionButton(
          icon: Icons.history,
          onTap: onOpenHistory,
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          icon: Icons.settings,
          onTap: onOpenSettings,
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(210),
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0AA594E8),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF5B5890), size: 22),
      ),
    );
  }
}
