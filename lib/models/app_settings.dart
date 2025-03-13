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
  final bool homeAppBarElevated; // 主页AppBar是否有阴影 (已弃用，总是为true)
  final bool homeAppBarColored; // 主页AppBar是否有背景色 (已弃用，总是为false)
  final String? customAppBarTitle; // 自定义AppBar标题文本
  
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.previewMode = PreviewMode.dialog,
    this.recordHistory = true,
    this.shareProviders = const {},
    this.selectedLanguage,
    this.themeColorMode = ThemeColorMode.system,
    this.customThemeColor = const Color(0xFF2196F3), // 默认蓝色
    this.homeAppBarElevated = true, // 默认有阴影（始终为true）
    this.homeAppBarColored = false, // 默认无背景色（始终为false）
    this.customAppBarTitle, // 自定义AppBar标题
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
    final homeAppBarElevated = json['homeAppBarElevated'] as bool?;
    final homeAppBarColored = json['homeAppBarColored'] as bool?;
    final customAppBarTitle = json['customAppBarTitle'] as String?;

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
      homeAppBarElevated: homeAppBarElevated ?? true,
      homeAppBarColored: homeAppBarColored ?? false,
      customAppBarTitle: customAppBarTitle,
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
      'homeAppBarElevated': homeAppBarElevated,
      'homeAppBarColored': homeAppBarColored,
      'customAppBarTitle': customAppBarTitle,
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
    bool? homeAppBarElevated,
    bool? homeAppBarColored,
    String? customAppBarTitle,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      previewMode: previewMode ?? this.previewMode,
      recordHistory: recordHistory ?? this.recordHistory,
      shareProviders: shareProviders ?? Map.from(this.shareProviders),
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      themeColorMode: themeColorMode ?? this.themeColorMode,
      customThemeColor: customThemeColor ?? this.customThemeColor,
      homeAppBarElevated: homeAppBarElevated ?? this.homeAppBarElevated,
      homeAppBarColored: homeAppBarColored ?? this.homeAppBarColored,
      customAppBarTitle: customAppBarTitle ?? this.customAppBarTitle,
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
        other.homeAppBarElevated == homeAppBarElevated &&
        other.homeAppBarColored == homeAppBarColored &&
        other.customAppBarTitle == customAppBarTitle &&
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
        homeAppBarElevated,
        homeAppBarColored,
        customAppBarTitle,
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