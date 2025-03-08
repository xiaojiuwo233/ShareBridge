import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import '../utils/theme_utils.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  bool _isSystemColorSupported = false;
  Color _previewColor = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _checkSystemColorSupport();
  }

  Future<void> _checkSystemColorSupport() async {
    bool isSupported = false;
    try {
      // 检查是否支持动态颜色
      final corePalette = await DynamicColorPlugin.getCorePalette();
      isSupported = corePalette != null;
    } catch (e) {
      isSupported = false;
    }
    
    setState(() {
      _isSystemColorSupported = isSupported;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '主题设置',
          style: TextStyle(color: colorScheme.primary),
        ),
        shadowColor: colorScheme.primary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          // 预览颜色
          _previewColor = provider.settings.themeColorMode == ThemeColorMode.custom
              ? provider.settings.customThemeColor
              : colorScheme.primary;
              
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingsGroup(
                context,
                '主题模式',
                [
                  _buildThemeModeSettings(context, provider),
                ],
              ),
              _buildSettingsGroup(
                context,
                '颜色设置',
                [
                  _buildThemeColorModeSettings(context, provider),
                  if (provider.settings.themeColorMode == ThemeColorMode.custom)
                    _buildCustomColorSettings(context, provider),
                ],
              ),
              if (_isSystemColorSupported)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '您的设备支持动态颜色（Material You），建议使用系统颜色以获得最佳体验。',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              if (!_isSystemColorSupported)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '您的设备不支持动态颜色（Material You），建议使用自定义颜色。',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // 预览卡片
              Card(
                color: colorScheme.surface,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主题预览',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // 主色调
                          _buildColorBlock('主色调', _previewColor),
                          const SizedBox(width: 8),
                          // 次要色调
                          _buildColorBlock(
                            '次要色调',
                            colorScheme.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // 表面色
                          _buildColorBlock('表面色', colorScheme.surface),
                          const SizedBox(width: 8),
                          // 背景色
                          _buildColorBlock('背景色', colorScheme.background),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 按钮预览
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('按钮预览'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorBlock(String label, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            ThemeUtils.colorToHex(color),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeModeSettings(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        children: [
          // 跟随系统
          RadioListTile<ThemeMode>(
            title: Row(
              children: [
                Icon(
                  Icons.brightness_auto,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                const Text('跟随系统'),
              ],
            ),
            value: ThemeMode.system,
            groupValue: provider.settings.themeMode,
            onChanged: (value) {
              if (value != null) {
                provider.updateThemeMode(value);
              }
            },
          ),
          // 浅色模式
          RadioListTile<ThemeMode>(
            title: Row(
              children: [
                Icon(
                  Icons.brightness_7,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                const Text('浅色模式'),
              ],
            ),
            value: ThemeMode.light,
            groupValue: provider.settings.themeMode,
            onChanged: (value) {
              if (value != null) {
                provider.updateThemeMode(value);
              }
            },
          ),
          // 深色模式
          RadioListTile<ThemeMode>(
            title: Row(
              children: [
                Icon(
                  Icons.brightness_4,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                const Text('深色模式'),
              ],
            ),
            value: ThemeMode.dark,
            groupValue: provider.settings.themeMode,
            onChanged: (value) {
              if (value != null) {
                provider.updateThemeMode(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeColorModeSettings(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        children: [
          // 跟随系统
          RadioListTile<ThemeColorMode>(
            title: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                const Text('跟随系统'),
              ],
            ),
            value: ThemeColorMode.system,
            groupValue: provider.settings.themeColorMode,
            onChanged: (value) {
              if (value != null) {
                provider.updateThemeColorMode(value);
              }
            },
          ),
          // 自定义颜色
          RadioListTile<ThemeColorMode>(
            title: Row(
              children: [
                Icon(
                  Icons.color_lens_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                const Text('自定义颜色'),
              ],
            ),
            value: ThemeColorMode.custom,
            groupValue: provider.settings.themeColorMode,
            onChanged: (value) {
              if (value != null) {
                provider.updateThemeColorMode(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColorSettings(BuildContext context, AppProvider provider) {
    final currentColor = provider.settings.customThemeColor;
    final colorScheme = Theme.of(context).colorScheme;
    
    // 预定义的颜色列表
    final predefinedColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '选择预设颜色',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final color in predefinedColors)
                InkWell(
                  onTap: () {
                    provider.updateCustomThemeColor(color);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentColor == color
                            ? colorScheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: currentColor == color
                        ? Icon(
                            Icons.check,
                            color: colorScheme.onPrimary,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              // 自定义颜色选择器按钮
              InkWell(
                onTap: () async {
                  final pickedColor = await showDialog<Color>(
                    context: context,
                    builder: (context) => const ColorPickerDialog(),
                  );
                  if (pickedColor != null) {
                    provider.updateCustomThemeColor(pickedColor);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// 颜色选择对话框
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late TextEditingController _hexController;
  Color _selectedColor = Colors.blue;
  
  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: ThemeUtils.colorToHex(_selectedColor));
  }
  
  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.maxFinite,
            height: 40,
            child: Material(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hexController,
            decoration: const InputDecoration(
              labelText: '十六进制颜色值',
              hintText: '#RRGGBB',
              prefixText: '#',
            ),
            onChanged: (value) {
              final color = ThemeUtils.hexToColor('#$value');
              if (color != null) {
                setState(() {
                  _selectedColor = color;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }
} 