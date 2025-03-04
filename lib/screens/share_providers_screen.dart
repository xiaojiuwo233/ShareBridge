import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ShareProvidersScreen extends StatelessWidget {
  const ShareProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分享提供者设置'),
        scrolledUnderElevation: 0,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final providers = provider.settings.shareProviders;
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final entry = providers.entries.elementAt(index);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SwitchListTile(
                    title: Text(entry.key),
                    subtitle: Text('启用或禁用${entry.key}分享功能'),
                    value: entry.value,
                    onChanged: (bool value) {
                      provider.updateShareProvider(entry.key, value);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 