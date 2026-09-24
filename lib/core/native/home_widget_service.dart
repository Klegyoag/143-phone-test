import 'package:home_widget/home_widget.dart';

import '../../features/us/data/advanced_repository.dart';

/// Bridges privacy-filtered `/widgets/data` into the native Android/iOS widget
/// stores. Provider secrets are not involved; the native widget only receives
/// the small display fields the user enabled in widget settings.
class HomeWidgetService {
  HomeWidgetService(this._repository);
  final AdvancedRepository _repository;

  static const appGroupId = 'group.com.x10think.onefourthree';
  static const androidWidgetName = 'PartnerStatusWidget';
  static const iosWidgetName = 'OneFourThreeWidgets';

  Future<Map<String, dynamic>> sync() async {
    final config = await _repository.widgetConfig();
    final data = await _repository.widgetData();
    final cfg = config['data'] is Map ? (config['data'] as Map).cast<String, dynamic>() : config;
    final safe = _safePayload(data, cfg);

    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.saveWidgetData<String>('title', safe['title'] as String);
    await HomeWidget.saveWidgetData<String>('partner_status', safe['partner_status'] as String);
    await HomeWidget.saveWidgetData<String>('detail', safe['detail'] as String);
    await HomeWidget.saveWidgetData<String>('next_date', safe['next_date'] as String);
    await HomeWidget.saveWidgetData<String>('mood', safe['mood'] as String);
    await HomeWidget.saveWidgetData<String>('memory', safe['memory'] as String);
    await HomeWidget.saveWidgetData<bool>('allow_lock_sensitive', safe['allow_lock_sensitive'] as bool);
    await HomeWidget.saveWidgetData<bool>('quick_ping_enabled', safe['quick_ping_enabled'] as bool);
    await HomeWidget.updateWidget(androidName: androidWidgetName, iOSName: iosWidgetName);
    return safe;
  }

  Map<String, dynamic> _safePayload(Map<String, dynamic> data, Map<String, dynamic> config) {
    bool enabled(String key, [bool fallback = true]) => config[key] is bool ? config[key] as bool : fallback;
    String text(dynamic value, String fallback) {
      final v = value?.toString().trim() ?? '';
      return v.isEmpty ? fallback : v;
    }

    final allowSensitive = enabled('lock_screen_sensitive_text', false);
    final status = enabled('partner_status') ? text(data['partner_status'], 'Open 143 to see your person') : '143 · Private by choice';
    final days = enabled('anniversary') ? text(data['days_together'] ?? data['anniversary'], '') : '';
    final nextDate = enabled('next_date') ? text(data['next_date'], '') : '';
    final mood = enabled('mood') ? text(data['partner_mood'] ?? data['mood'], '') : '';
    final memory = enabled('memory') && allowSensitive ? text(data['memory'] ?? data['on_this_day'], '') : '';

    final detailParts = <String>[
      if (days.isNotEmpty) days.toLowerCase().contains('day') ? days : '$days days together',
      if (mood.isNotEmpty) 'Mood: $mood',
    ];

    return {
      'title': '143 · Our little world',
      'partner_status': status,
      'detail': detailParts.isEmpty ? 'Private by default ♡' : detailParts.join(' · '),
      'next_date': nextDate,
      'mood': mood,
      'memory': memory,
      'allow_lock_sensitive': allowSensitive,
      'quick_ping_enabled': enabled('quick_ping', true),
    };
  }
}
