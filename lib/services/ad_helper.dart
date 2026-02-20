import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  AdHelper._();

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8202197996440855/9759619993';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-8202197996440855/9759619993'; // Same for now
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}
