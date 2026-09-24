import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';

class EncryptionStatusScreen extends ConsumerStatefulWidget {
  const EncryptionStatusScreen({super.key});
  @override
  ConsumerState<EncryptionStatusScreen> createState() => _EncryptionStatusScreenState();
}

class _EncryptionStatusScreenState extends ConsumerState<EncryptionStatusScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = ref.read(cryptoRepositoryProvider).deviceKeyStatus();
  }

  void reload() => setState(() => future = ref.read(cryptoRepositoryProvider).deviceKeyStatus());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Encryption')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoadingState(label: 'Checking device key status…');
          if (snapshot.hasError) return AppErrorState(message: '${snapshot.error}', onRetry: reload);
          final devices = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: AppColors.blush,
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(Icons.lock_outline_rounded, color: AppColors.rose), SizedBox(width: 10), Text('E2EE transport boundary', style: TextStyle(fontWeight: FontWeight.w800))]),
                    SizedBox(height: 12),
                    Text('The Laravel backend can store public identity keys, signed prekeys and one-time prekeys. Private keys must stay on this device. This build does not invent a cryptographic protocol: actual message/media encryption remains pending a reviewed client crypto engine.'),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              Text('Registered key devices', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (devices.isEmpty)
                const Card(child: ListTile(leading: Icon(Icons.phonelink_lock_outlined), title: Text('No public key bundle registered yet'), subtitle: Text('This is expected until the production client crypto engine provisions this device.')))
              else
                ...devices.map((d) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AppColors.blushStrong, child: Icon(Icons.key_rounded, color: AppColors.rose)),
                        title: Text('${d['device_id'] ?? 'Device'}'),
                        subtitle: Text('${d['unused_prekeys'] ?? 0} unused one-time prekeys'),
                      ),
                    )),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh key status')),
            ],
          );
        },
      ),
    );
  }
}
