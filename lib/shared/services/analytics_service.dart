import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class AnalyticsService {
  AnalyticsService({
    required FirebaseAnalytics firebaseAnalytics,
    required Mixpanel mixpanel,
  })  : _firebaseAnalytics = firebaseAnalytics,
        _mixpanel = mixpanel;

  final FirebaseAnalytics _firebaseAnalytics;
  final Mixpanel _mixpanel;

  Future<void> trackScreen(String name) async {
    await _firebaseAnalytics.logScreenView(screenName: name);
    _mixpanel.track('screen_view', properties: <String, Object>{'screen': name});
  }

  Future<void> trackEvent(String name, [Map<String, Object>? properties]) async {
    await _firebaseAnalytics.logEvent(name: name, parameters: properties);
    _mixpanel.track(name, properties: properties);
  }
}
