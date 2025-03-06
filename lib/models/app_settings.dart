import 'package:flutter/material.dart';

/// 预览模式枚举
enum PreviewMode {
  dialog,    // 弹窗预览
  fullScreen // 全屏预览
}

/// 主题色模式枚举
enum ThemeColorMode {
  system,    // 跟随系统（Material You）
  custom     // 自定义颜色
}

/// 应用设置模型类
class AppSettings {
  final ThemeMode themeMode; // 主题模式（亮色/暗色/系统）
  final PreviewMode previewMode; // 预览模式
  final bool recordHistory; // 是否记录历史
  final Map<String, bool> shareProviders; // 分享提供者开关状态
  final String? selectedLanguage; // 选择的语言
  final ThemeColorMode themeColorMode; // 主题颜色模式
  final Color customThemeColor; // 自定义主题色
  
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.previewMode = PreviewMode.dialog,
    this.recordHistory = true,
    this.shareProviders = const {},
    this.selectedLanguage,
    this.themeColorMode = ThemeColorMode.system,
    this.customThemeColor = const Color(0xFF2196F3), // 默认蓝色
  });

  /// 从JSON创建AppSettings实例
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // 数据验证和默认值处理
    final themeModeStr = json['themeMode'] as String?;
    final previewModeStr = json['previewMode'] as String?;
    final recordHistory = json['recordHistory'] as bool?;
    final shareProviders = json['shareProviders'] as Map?;
    final selectedLanguage = json['selectedLanguage'] as String?;
    final themeColorModeStr = json['themeColorMode'] as String?;
    final customThemeColorInt = json['customThemeColor'] as int?;

    // 主题模式验证
    ThemeMode themeMode;
    try {
      themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeStr,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      themeMode = ThemeMode.system;
    }

    // 预览模式验证
    PreviewMode previewMode;
    try {
      previewMode = PreviewMode.values.firstWhere(
        (e) => e.toString() == previewModeStr,
        orElse: () => PreviewMode.dialog,
      );
    } catch (_) {
      previewMode = PreviewMode.dialog;
    }

    // 主题色模式验证
    ThemeColorMode themeColorMode;
    try {
      themeColorMode = ThemeColorMode.values.firstWhere(
        (e) => e.toString() == themeColorModeStr,
        orElse: () => ThemeColorMode.system,
      );
    } catch (_) {
      themeColorMode = ThemeColorMode.system;
    }

    // 自定义主题色验证
    Color customThemeColor = const Color(0xFF2196F3); // 默认蓝色
    if (customThemeColorInt != null) {
      customThemeColor = Color(customThemeColorInt);
    }

    // 语言代码验证
    String? validatedLanguage;
    if (selectedLanguage != null && (selectedLanguage == 'zh' || selectedLanguage == 'en')) {
      validatedLanguage = selectedLanguage;
    }

    return AppSettings(
      themeMode: themeMode,
      previewMode: previewMode,
      recordHistory: recordHistory ?? true,
      shareProviders: Map<String, bool>.from(shareProviders ?? {}),
      selectedLanguage: validatedLanguage,
      themeColorMode: themeColorMode,
      customThemeColor: customThemeColor,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.toString(),
      'previewMode': previewMode.toString(),
      'recordHistory': recordHistory,
      'shareProviders': shareProviders,
      'selectedLanguage': selectedLanguage,
      'themeColorMode': themeColorMode.toString(),
      'customThemeColor': customThemeColor.value,
    };
  }

  /// 创建AppSettings的副本
  AppSettings copyWith({
    ThemeMode? themeMode,
    PreviewMode? previewMode,
    bool? recordHistory,
    Map<String, bool>? shareProviders,
    String? selectedLanguage,
    ThemeColorMode? themeColorMode,
    Color? customThemeColor,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      previewMode: previewMode ?? this.previewMode,
      recordHistory: recordHistory ?? this.recordHistory,
      shareProviders: shareProviders ?? Map.from(this.shareProviders),
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      themeColorMode: themeColorMode ?? this.themeColorMode,
      customThemeColor: customThemeColor ?? this.customThemeColor,
    );
  }

  /// 判断两个AppSettings是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.previewMode == previewMode &&
        other.recordHistory == recordHistory &&
        other.selectedLanguage == selectedLanguage &&
        other.themeColorMode == themeColorMode &&
        other.customThemeColor == customThemeColor &&
        _mapsEqual(other.shareProviders, shareProviders);
  }

  /// 生成哈希码
  @override
  int get hashCode => Object.hash(
        themeMode,
        previewMode,
        recordHistory,
        selectedLanguage,
        themeColorMode,
        customThemeColor,
        Object.hashAll(shareProviders.entries),
      );

  /// 比较两个Map是否相等
  bool _mapsEqual(Map<String, bool> map1, Map<String, bool> map2) {
    if (map1.length != map2.length) return false;
    return map1.entries.every(
      (entry) => map2.containsKey(entry.key) && map2[entry.key] == entry.value,
    );
  }
} 