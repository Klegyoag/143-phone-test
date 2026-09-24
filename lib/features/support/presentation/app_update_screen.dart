import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/update/app_update_service.dart';
import '../../../l10n/app_localizations.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});
  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  AppUpdateInfo? info;
  Object? error;
  bool loading = true;

  @override
  void initState() { super.initState(); _check(); }

  Future<void> _check() async {
    setState(() { loading = true; error = null; });
    try { info = await AppUpdateService().check(); }
    catch (e) { error = e; }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.t('appUpdates'))),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _check,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (error != null) _card(Icons.error_outline, l.t('updateCheckFailed'), '$error'),
          if (info != null) ...[
            _card(Icons.phone_android_rounded, l.t('installedVersion'), info!.installedVersion),
            if (!info!.configured) _card(Icons.info_outline_rounded, l.t('updateCheckNotConfigured'), l.t('updateCheckBoundaryBody')),
            if (info!.configured) _card(
              info!.available ? Icons.system_update_rounded : Icons.check_circle_outline_rounded,
              info!.required ? l.t('updateRequired') : info!.available ? l.t('updateAvailable') : l.t('upToDate'),
              info!.latestVersion == null ? l.t('versionUnknown') : '${l.t('latestVersion')}: ${info!.latestVersion}',
            ),
            if ((info!.releaseNotes ?? '').isNotEmpty) _card(Icons.new_releases_outlined, l.t('whatsNew'), info!.releaseNotes!),
            if (info!.available && (info!.storeUrl ?? '').isNotEmpty)
              Semantics(button: true, label: l.t('openStoreUpdate'), child: FilledButton.icon(
                onPressed: () async { final uri = Uri.tryParse(info!.storeUrl!); if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication); },
                icon: const Icon(Icons.open_in_new_rounded), label: Text(l.t('openStoreUpdate')),
              )),
          ],
        ]),
      ),
    );
  }

  Widget _card(IconData icon, String title, String body) => Card(child: ListTile(
    leading: Icon(icon, color: AppColors.rose), title: Text(title), subtitle: Text(body),
  ));
}
