import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import 'share_providers_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            _buildSettingsGroup(
              context,
              '外观',
              [_buildThemeSettings(context, provider)],
            ),
            _buildSettingsGroup(
              context,
              '功能',
              [
                _buildPreviewSettings(context, provider),
                _buildLanguageSettings(context, provider),
                _buildShareProviderSettingsButton(context, provider),
              ],
            ),
            _buildSettingsGroup(
              context,
              '关于',
              [_buildAboutSection(context)],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeSettings(BuildContext context, AppProvider provider) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('主题设置'),
      trailing: DropdownButton<ThemeMode>(
        value: provider.settings.themeMode,
        items: const [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text('跟随系统'),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text('浅色'),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text('深色'),
          ),
        ],
        onChanged: (ThemeMode? mode) {
          if (mode != null) {
            provider.updateThemeMode(mode);
          }
        },
      ),
    );
  }

  Widget _buildPreviewSettings(BuildContext context, AppProvider provider) {
    return ListTile(
      leading: const Icon(Icons.preview_outlined),
      title: const Text('预览设置'),
      trailing: DropdownButton<PreviewMode>(
        value: provider.settings.previewMode,
        items: const [
          DropdownMenuItem(
            value: PreviewMode.dialog,
            child: Text('弹窗预览'),
          ),
          DropdownMenuItem(
            value: PreviewMode.fullScreen,
            child: Text('全屏预览'),
          ),
        ],
        onChanged: (PreviewMode? mode) {
          if (mode != null) {
            provider.updatePreviewMode(mode);
          }
        },
      ),
    );
  }

  Widget _buildLanguageSettings(BuildContext context, AppProvider provider) {
    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: const Text('语言设置'),
      trailing: DropdownButton<String?>(
        value: provider.settings.selectedLanguage,
        items: const [
          DropdownMenuItem(
            value: null,
            child: Text('跟随系统'),
          ),
          DropdownMenuItem(
            value: 'zh',
            child: Text('中文'),
          ),
          DropdownMenuItem(
            value: 'en',
            child: Text('English(not supported)'),
          ),
        ],
        onChanged: (String? languageCode) {
          provider.updateLanguage(languageCode);
        },
      ),
    );
  }

  Widget _buildShareProviderSettingsButton(BuildContext context, AppProvider provider) {
    return ListTile(
      leading: const Icon(Icons.share_outlined),
      title: const Text('分享提供者设置'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ShareProvidersScreen(),
          ),
        );
      },
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('关于'),
          subtitle: const Text('ShareBridge v1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.code_outlined),
          title: const Text('源代码'),
          subtitle: const Text('跳转到Github查看'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () async {
            final Uri url = Uri.parse('https://github.com/xiaojiuwo233/ShareBridge');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
        ),
      ],
    );
  }
} 