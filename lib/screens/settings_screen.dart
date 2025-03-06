import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import 'share_providers_screen.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }
  
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Error loading app info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            _buildSettingsGroup(
              context,
              '外观',
              [
                _buildThemeSettingsButton(context),
              ],
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
              [
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: colorScheme.primary),
                  title: Text('关于', style: TextStyle(color: colorScheme.onSurface)),
                  subtitle: Text('ShareBridge v$_appVersion', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                ListTile(
                  leading: Icon(Icons.code_outlined,
                      color: colorScheme.primary),
                  title: Text('源代码', style: TextStyle(color: colorScheme.onSurface)),
                  subtitle: Text('跳转到Github查看', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.open_in_new,
                      size: 18, color: colorScheme.primary),
                  onTap: () async {
                    final Uri url = Uri.parse('https://github.com/xiaojiuwo233/ShareBridge');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeSettingsButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
      title: const Text('主题设置'),
      subtitle: const Text('自定义应用的外观'),
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.primary),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ThemeSettingsScreen(),
          ),
        );
      },
    );
  }

  Widget _buildPreviewSettings(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(Icons.preview_outlined, color: colorScheme.primary),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(Icons.language_outlined, color: colorScheme.primary),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(Icons.share_outlined, color: colorScheme.primary),
      title: const Text('分享提供者设置'),
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.primary),
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
} 