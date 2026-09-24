import 'package:flutter/material.dart';

import '../../../core/provider/provider_readiness.dart';
import '../../../core/theme/app_colors.dart';

class IntegrationReadinessScreen extends StatelessWidget {
  const IntegrationReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const ProviderReadiness().inspect();
    return Scaffold(
      appBar: AppBar(title: const Text('Provider & Device Readiness')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          Card(
            color: AppColors.blush,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.fact_check_outlined, color: AppColors.rose), SizedBox(width: 10), Expanded(child: Text('Integration boundaries, not fake success', style: TextStyle(fontWeight: FontWeight.w800)))]),
                SizedBox(height: 10),
                Text('143 keeps provider credentials outside committed Flutter source. A green item means the frontend boundary is configured enough to exercise; it does not replace provider-console setup or physical-device QA.'),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map((item) => Semantics(
                container: true,
                label: '${item.name}. ${item.ready ? 'Ready for integration testing' : 'Setup pending'}. ${item.detail}',
                child: Card(
                  child: ListTile(
                    minVerticalPadding: 14,
                    leading: CircleAvatar(
                      backgroundColor: item.ready ? AppColors.blushStrong : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(item.ready ? Icons.check_rounded : Icons.build_circle_outlined, color: item.ready ? AppColors.rose : null),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(item.detail),
                    trailing: item.secretRequired ? const Tooltip(message: 'External/provider secure setup required', child: Icon(Icons.key_outlined)) : null,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
