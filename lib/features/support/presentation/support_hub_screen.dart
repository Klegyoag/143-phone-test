import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';

class SupportHubScreen extends ConsumerStatefulWidget {
  const SupportHubScreen({super.key});
  @override
  ConsumerState<SupportHubScreen> createState() => _SupportHubScreenState();
}

class _SupportHubScreenState extends ConsumerState<SupportHubScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> articles = [], exports = [], notes = [], legalDocs = [];
  Map<String, dynamic> about = {};
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final repo = ref.read(supportRepositoryProvider);
      final result = await Future.wait([repo.helpArticles(), repo.exports(), repo.about(), repo.releaseNotes(), repo.legalDocuments(), PackageInfo.fromPlatform()]);
      articles = result[0] as List<Map<String, dynamic>>;
      exports = result[1] as List<Map<String, dynamic>>;
      about = result[2] as Map<String, dynamic>;
      notes = result[3] as List<Map<String, dynamic>>;
      legalDocs = result[4] as List<Map<String, dynamic>>;
      final info = result[5] as PackageInfo;
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help, Data & About')),
        body: loading
            ? const AppLoadingState(label: 'Loading your support space…')
            : error != null
                ? AppErrorState(message: error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
                      _hero(context),
                      _title('Your data'),
                      Card(child: Column(children: [
                        ListTile(leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.rose), title: const Text('Export as PDF'), subtitle: const Text('Generate a private downloadable copy.'), onTap: () => _requestExport('pdf')),
                        const Divider(height: 1),
                        ListTile(leading: const Icon(Icons.data_object_rounded, color: AppColors.rose), title: const Text('Export as JSON'), onTap: () => _requestExport('json')),
                      ])),
                      if (exports.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...exports.take(5).map((e) => ListTile(
                              dense: true,
                              title: Text('${e['type'] ?? 'Export'} • ${e['status'] ?? ''}'),
                              subtitle: Text('${e['created_at'] ?? ''}'),
                              trailing: '${e['status']}' == 'completed' ? IconButton(icon: const Icon(Icons.download_rounded), onPressed: () => _download('${e['id']}')) : null,
                            )),
                      ],
                      _title('Help Center'),
                      if (articles.isEmpty) const ListTile(title: Text('No help articles are published yet.')),
                      ...articles.take(8).map((a) => Card(child: ListTile(title: Text('${a['title'] ?? 'Help article'}'), subtitle: Text('${a['summary'] ?? a['excerpt'] ?? ''}'), trailing: const Icon(Icons.chevron_right), onTap: () => _article(a)))),
                      if (legalDocs.isNotEmpty) ...[
                        _title('Legal'),
                        Card(child: Column(children: legalDocs.map((d) => ListTile(
                          leading: const Icon(Icons.policy_outlined, color: AppColors.rose),
                          title: Text('${d['title'] ?? d['type'] ?? 'Legal document'}'),
                          subtitle: Text('Version ${d['version'] ?? ''}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _legal(d),
                        )).toList())),
                      ],
                      _title('FAQ & Support'),
                      Card(child: Column(children: [
                        ListTile(leading: const Icon(Icons.support_agent_rounded, color: AppColors.rose), title: const Text('Contact Support'), trailing: const Icon(Icons.chevron_right), onTap: _ticket),
                        const Divider(height: 1),
                        ListTile(leading: const Icon(Icons.rate_review_outlined, color: AppColors.rose), title: const Text('Send feedback'), trailing: const Icon(Icons.chevron_right), onTap: _feedback),
                        const Divider(height: 1),
                        ListTile(leading: const Icon(Icons.star_outline_rounded, color: AppColors.rose), title: const Text('Rate 143'), subtitle: const Text('Open the App Store / Play Store review experience when available.'), trailing: const Icon(Icons.open_in_new_rounded), onTap: _rateApp),
                      ])),
                      _title('About 143'),
                      Card(child: Column(children: [
                        ListTile(title: const Text('App version'), trailing: Text(appVersion.isEmpty ? '0.10.0' : appVersion)),
                        if (about.isNotEmpty) ListTile(title: Text('${about['name'] ?? '143'}'), subtitle: Text('${about['description'] ?? about['tagline'] ?? 'A private digital home for two people.'}')),
                      ])),
                      if (notes.isNotEmpty) ...[
                        _title("What's New"),
                        ...notes.take(6).map((n) => Card(child: ListTile(title: Text('${n['title'] ?? n['version'] ?? 'Release note'}'), subtitle: Text('${n['body'] ?? n['summary'] ?? ''}')))),
                      ],
                    ]),
                  ),
      );

  Widget _hero(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blush, AppColors.peach]), borderRadius: BorderRadius.circular(26)),
        child: Row(children: [const Icon(Icons.favorite_outline_rounded, color: AppColors.rose, size: 34), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('We’re here when you need us', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 4), const Text('Help, feedback and your private data exports — all in one calm place.')]))]),
      );

  Widget _title(String text) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)));

  Future<void> _requestExport(String format) async {
    try {
      await ref.read(supportRepositoryProvider).requestExport(format);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${format.toUpperCase()} export queued.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  Future<void> _download(String id) async {
    try {
      final d = await ref.read(supportRepositoryProvider).exportDownload(id);
      final uri = Uri.tryParse('${d['url'] ?? ''}');
      if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) throw StateError('Could not open export URL.');
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  Future<void> _article(Map<String, dynamic> article) async {
    final id = '${article['id'] ?? ''}';
    var full = article;
    if (id.isNotEmpty) {
      try { full = await ref.read(supportRepositoryProvider).helpArticle(id); } catch (_) {}
    }
    if (!mounted) return;
    showDialog(context: context, builder: (c) => AlertDialog(title: Text('${full['title'] ?? 'Help'}'), content: SingleChildScrollView(child: Text('${full['body'] ?? full['content'] ?? full['summary'] ?? ''}')), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))]));
  }


  Future<void> _legal(Map<String, dynamic> d) async {
    var full = d;
    final type = '${d['type'] ?? ''}';
    if (type.isNotEmpty) { try { full = await ref.read(supportRepositoryProvider).legalDocument(type); } catch (_) {} }
    if (!mounted) return;
    showDialog(context: context, builder: (c) => AlertDialog(title: Text('${full['title'] ?? type}'), content: SizedBox(width: 520, child: SingleChildScrollView(child: SelectableText('${full['body'] ?? full['content'] ?? full['text'] ?? ''}'))), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))]));
  }

  Future<void> _ticket() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Contact Support'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject')), const SizedBox(height: 12), TextField(controller: message, maxLines: 4, decoration: const InputDecoration(labelText: 'How can we help?'))]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Send'))]));
    if (ok == true && subject.text.trim().isNotEmpty && message.text.trim().isNotEmpty) {
      try { await ref.read(supportRepositoryProvider).createTicket(subject: subject.text.trim(), message: message.text.trim()); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support ticket sent.'))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    }
    subject.dispose(); message.dispose();
  }


  Future<void> _rateApp() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        return;
      }
      const appStoreId = String.fromEnvironment('IOS_APP_STORE_ID');
      await review.openStoreListing(appStoreId: appStoreId.isEmpty ? null : appStoreId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store listing is not configured for this build yet.')));
      }
    }
  }

  Future<void> _feedback() async {
    final message = TextEditingController();
    int rating = 5;
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(title: const Text('Send feedback'), content: Column(mainAxisSize: MainAxisSize.min, children: [Wrap(children: List.generate(5, (i) => IconButton(onPressed: () => setLocal(() => rating = i + 1), icon: Icon(i < rating ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: AppColors.rose))),), TextField(controller: message, maxLines: 4, decoration: const InputDecoration(labelText: 'Your feedback'))]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Send'))])));
    if (ok == true && message.text.trim().isNotEmpty) {
      try { await ref.read(supportRepositoryProvider).feedback(message: message.text.trim(), rating: rating); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you ♡'))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    }
    message.dispose();
  }
}
