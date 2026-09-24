import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../couple/presentation/couple_settings_screen.dart';
import '../../profile/presentation/personalization_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/presentation/security_screen.dart';
import '../../support/presentation/support_hub_screen.dart';
import 'modules/achievements_screen.dart';
import 'modules/ai_screen.dart';
import 'modules/backup_widgets_screen.dart';
import 'modules/budget_screen.dart';
import 'modules/calendar_screen.dart';
import 'modules/connection_screen.dart';
import 'modules/device_security_screen.dart';
import 'modules/games_screen.dart';
import 'modules/goals_jars_screen.dart';
import 'modules/insights_screen.dart';
import 'modules/journeys_screen.dart';
import 'modules/long_distance_screen.dart';
import 'modules/music_screen.dart';
import 'modules/preferences_screen.dart';
import 'modules/reconnection_screen.dart';
import 'modules/romantic_interaction_screen.dart';
import 'modules/scheduled_love_screen.dart';
import 'modules/settings_hub_screen.dart';
import 'modules/shared_lists_screen.dart';
import 'modules/smart_date_screen.dart';
import 'modules/story_screen.dart';
import 'modules/together_screen.dart';

class UsScreen extends StatelessWidget {
  const UsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = <_UsItem>[
      _UsItem(Icons.person_outline_rounded, l.t('profile'), () => _open(context, const ProfileScreen())),
      _UsItem(Icons.favorite_rounded, 'Our Space', () => _open(context, const CoupleSettingsScreen())),
      _UsItem(Icons.palette_outlined, l.t('appearance'), () => _open(context, const PersonalizationScreen())),
      _UsItem(Icons.lock_outline_rounded, l.t('security'), () => _open(context, const SecurityScreen())),
      _UsItem(Icons.auto_stories_outlined, l.t('ourStory'), () => _open(context, const StoryScreen())),
      _UsItem(Icons.sports_esports_outlined, l.t('games'), () => _open(context, const GamesScreen())),
      _UsItem(Icons.calendar_month_outlined, l.t('calendar'), () => _open(context, const CalendarScreen())),
      _UsItem(Icons.flag_outlined, l.t('goals'), () => _open(context, const GoalsJarsScreen())),
      _UsItem(Icons.inventory_2_outlined, l.t('jarsBucket'), () => _open(context, const GoalsJarsScreen())),
      _UsItem(Icons.card_giftcard_outlined, l.t('ourLists'), () => _open(context, const SharedListsScreen())),
      _UsItem(Icons.music_note_outlined, l.t('music'), () => _open(context, const MusicScreen())),
      _UsItem(Icons.public_outlined, l.t('distance'), () => _open(context, const LongDistanceScreen())),
      _UsItem(Icons.insights_outlined, l.t('insights'), () => _open(context, const InsightsScreen())),
      _UsItem(Icons.route_outlined, l.t('journeys'), () => _open(context, const JourneysScreen())),
      _UsItem(Icons.emoji_events_outlined, l.t('achievements'), () => _open(context, const AchievementsScreen())),
      _UsItem(Icons.auto_awesome_outlined, l.t('ai143'), () => _open(context, const AiScreen())),
      _UsItem(Icons.ondemand_video_outlined, l.t('together'), () => _open(context, const TogetherScreen())),
      _UsItem(Icons.favorite_border_rounded, l.t('preferences'), () => _open(context, const PreferencesScreen())),
      _UsItem(Icons.waving_hand_outlined, l.t('needYou'), () => _open(context, const ConnectionScreen())),
      _UsItem(Icons.favorite_outline_rounded, 'Connection', () => _open(context, const RomanticInteractionScreen())),
      _UsItem(Icons.schedule_send_outlined, l.t('scheduledLove'), () => _open(context, const ScheduledLoveScreen())),
      _UsItem(Icons.spa_outlined, l.t('reconnect'), () => _open(context, const CoolDownScreen())),
      _UsItem(Icons.auto_awesome_motion_outlined, l.t('smartDate'), () => _open(context, const SmartDateScreen())),
      _UsItem(Icons.account_balance_wallet_outlined, l.t('budget'), () => _open(context, const BudgetScreen())),
      _UsItem(Icons.cloud_done_outlined, l.t('backup'), () => _open(context, const BackupScreen())),
      _UsItem(Icons.phonelink_lock_outlined, l.t('devices'), () => _open(context, const LinkedDevicesScreen())),
      _UsItem(Icons.widgets_outlined, l.t('widgets'), () => _open(context, const WidgetsScreen())),
      _UsItem(Icons.shield_outlined, l.t('privacy'), () => _open(context, const SettingsHubScreen())),
      _UsItem(Icons.help_outline_rounded, l.t('helpData'), () => _open(context, const SupportHubScreen())),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.t('us')), backgroundColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 120), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(28)),
          child: Column(children: [
            Semantics(
              label: 'Two partner profiles connected by a heart',
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 27, child: Icon(Icons.person)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.favorite_rounded, color: AppColors.rose)), CircleAvatar(radius: 27, child: Icon(Icons.person_outline))]),
            ),
            const SizedBox(height: 12),
            Text(l.t('ourLittleWorld'), style: Theme.of(context).textTheme.titleLarge),
            Text(l.t('littleWorldSubtitle'), style: const TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 22),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .95),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return Semantics(
              button: true,
              label: item.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: item.onTap,
                child: Ink(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.icon, color: AppColors.rose), const SizedBox(height: 8), Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(item.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))]),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  static void _open(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _UsItem {
  const _UsItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

