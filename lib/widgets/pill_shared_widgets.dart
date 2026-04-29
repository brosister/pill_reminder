import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/app_copy.dart';
import '../models/pill_models.dart';
import '../services/ad_config_service.dart';

const double kPageBottomContentPadding = 24;
const double kPageBannerContentGap = 16;

class SectionIntro extends StatelessWidget {
  const SectionIntro({
    super.key,
    this.title,
    required this.description,
    required this.icon,
    this.accentColor = const Color(0xFF7A5AF8),
  });

  final String? title;
  final String description;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title!.isNotEmpty) ...[
                Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF25164D),
                      ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF6C6192),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CardShell extends StatelessWidget {
  const CardShell({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class BottomBannerPageScaffold extends StatefulWidget {
  const BottomBannerPageScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  State<BottomBannerPageScaffold> createState() =>
      _BottomBannerPageScaffoldState();
}

class _BottomBannerPageScaffoldState extends State<BottomBannerPageScaffold> {
  final AdConfigService _adConfig = AdConfigService();
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;
  int? _loadedBannerWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || _loadedBannerWidth == width) return;
    _loadedBannerWidth = width;
    unawaited(_initBanner(width));
  }

  Future<void> _initBanner(int width) async {
    await _adConfig.loadConfig();
    if (!mounted) return;
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
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final hasVisibleBanner = _bannerLoaded && _bannerAd != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF25164D),
              ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: hasVisibleBanner ? kPageBannerContentGap : 0,
          ),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: hasVisibleBanner
          ? Container(
              width: double.infinity,
              color: Colors.transparent,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                width: double.infinity,
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
    );
  }
}

class PillBottomNav extends StatelessWidget {
  const PillBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.extraBottomPadding,
  });

  final List<PillNavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 8, 14, 8 + extraBottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                return Expanded(
                  child: _PillBottomNavItem(
                    data: items[index],
                    isSelected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillBottomNavItem extends StatelessWidget {
  const _PillBottomNavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final PillNavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected
                  ? data.color.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isSelected ? 42 : 36,
                    height: isSelected ? 42 : 36,
                    decoration: BoxDecoration(
                      color: isSelected ? data.color : const Color(0xFFF3F0FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      color: isSelected ? Colors.white : const Color(0xFF665F85),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? data.color : const Color(0xFF665F85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PillNavItemData {
  const PillNavItemData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class MiniStatCard extends StatelessWidget {
  const MiniStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6C6192),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF25164D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF7B74A3)),
          ),
        ],
      ),
    );
  }
}

class MedicationLogCard extends StatelessWidget {
  const MedicationLogCard({
    super.key,
    required this.copy,
    required this.logs,
    this.emptyMessage,
  });

  final AppCopy copy;
  final List<DoseLog> logs;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.recentLog,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF25164D),
            ),
          ),
          const SizedBox(height: 14),
          if (logs.isEmpty)
            Text(
              emptyMessage ?? copy.emptyLog,
              style: const TextStyle(color: Color(0xFF7B74A3)),
            )
          else
            ...logs.map(
              (log) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: log.skipped
                            ? const Color(0xFFB8AECF)
                            : const Color(0xFF7A5AF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF25164D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.medicationNames.join(', '),
                            style: const TextStyle(color: Color(0xFF7B74A3)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      log.dateKey == DateTime.now()
                              .toIso8601String()
                              .split('T')
                              .first
                          ? log.time
                          : '${log.dateKey}\n${log.time}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Color(0xFF7B74A3)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.copy,
    required this.data,
  });

  final AppCopy copy;
  final List<DailyPillCount> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(
      0,
      (max, item) => math.max(max, math.max(item.takenCount, item.goalCount)),
    );
    final chartMax = maxValue == 0 ? 1 : maxValue;

    return SizedBox(
      height: 184,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${item.takenCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF44506C),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 18,
                          height: 120 * (item.goalCount / chartMax),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9E1FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 120 * (item.takenCount / chartMax),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7A5AF8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  copy.weekdayShort(item.day),
                  style: const TextStyle(color: Color(0xFF66718F)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PillRingPainter extends CustomPainter {
  const PillRingPainter({required this.progress});

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
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFF0E7FF)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(18), 0, math.pi * 2, false, bgPaint);
    canvas.drawArc(
      rect.deflate(18),
      start,
      math.pi * 2 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PillRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
