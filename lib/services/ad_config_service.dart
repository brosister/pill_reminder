import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AdConfigService {
  static final AdConfigService _instance = AdConfigService._internal();
  factory AdConfigService() => _instance;
  AdConfigService._internal();

  bool _useTestAds = true;
  String _bannerAdIdAndroid = '';
  String _bannerAdIdIOS = '';
  String _interstitialAdIdAndroid = '';
  String _interstitialAdIdIOS = '';
  String _testBannerAdIdAndroid = '';
  String _testBannerAdIdIOS = '';
  String _testInterstitialAdIdAndroid = '';
  String _testInterstitialAdIdIOS = '';

  String get bannerAdId {
    if (_useTestAds) {
      return Platform.isIOS
          ? (_testBannerAdIdIOS.isNotEmpty ? _testBannerAdIdIOS : AppConfig.testBannerAdIdIOS)
          : (_testBannerAdIdAndroid.isNotEmpty ? _testBannerAdIdAndroid : AppConfig.testBannerAdIdAndroid);
    }
    return Platform.isIOS
        ? (_bannerAdIdIOS.isNotEmpty ? _bannerAdIdIOS : AppConfig.prodBannerAdIdIOS)
        : (_bannerAdIdAndroid.isNotEmpty ? _bannerAdIdAndroid : AppConfig.prodBannerAdIdAndroid);
  }

  String get interstitialAdId {
    if (_useTestAds) {
      return Platform.isIOS
          ? (_testInterstitialAdIdIOS.isNotEmpty ? _testInterstitialAdIdIOS : AppConfig.testInterstitialAdIdIOS)
          : (_testInterstitialAdIdAndroid.isNotEmpty ? _testInterstitialAdIdAndroid : AppConfig.testInterstitialAdIdAndroid);
    }
    return Platform.isIOS
        ? (_interstitialAdIdIOS.isNotEmpty ? _interstitialAdIdIOS : AppConfig.prodInterstitialAdIdIOS)
        : (_interstitialAdIdAndroid.isNotEmpty ? _interstitialAdIdAndroid : AppConfig.prodInterstitialAdIdAndroid);
  }

  Future<void> loadConfig() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/api/admin/pill-reminder/ad-settings'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final config = data['data'];
        if (data['success'] == true && config != null) {
          _useTestAds = config['ad_mode'] == 'test';
          _bannerAdIdAndroid = config['android_banner_ad_id'] ?? '';
          _interstitialAdIdAndroid = config['android_interstitial_ad_id'] ?? '';
          _bannerAdIdIOS = config['ios_banner_ad_id'] ?? '';
          _interstitialAdIdIOS = config['ios_interstitial_ad_id'] ?? '';
          _testBannerAdIdAndroid = config['test_android_banner_ad_id'] ?? '';
          _testInterstitialAdIdAndroid = config['test_android_interstitial_ad_id'] ?? '';
          _testBannerAdIdIOS = config['test_ios_banner_ad_id'] ?? '';
          _testInterstitialAdIdIOS = config['test_ios_interstitial_ad_id'] ?? '';
          return;
        }
      }
    } catch (e) {
      debugPrint('PillReminder ad config load error: $e');
    }
    _useTestAds = true;
  }
}
