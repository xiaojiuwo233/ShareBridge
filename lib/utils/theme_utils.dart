import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:ui';

/// 主题工具类
class ThemeUtils {
  // 平台通道
  static const MethodChannel _channel = MethodChannel('com.xjw.sharebridge/theme');
  
  // 默认颜色
  static const Color _defaultColor = Color(0xFF2196F3); // 蓝色
  
  // 缓存系统颜色 (分别缓存亮色和暗色模式)
  static Color? _systemLightColor;
  static Color? _systemDarkColor;
  
  /// 尝试从平台获取系统主题色
  static Future<Color> getSystemThemeColor({Brightness brightness = Brightness.light}) async {
    // 检查缓存
    if (brightness == Brightness.light && _systemLightColor != null) {
      return _systemLightColor!;
    } else if (brightness == Brightness.dark && _systemDarkColor != null) {
      return _systemDarkColor!;
    }
    
    try {
      // 向原生端请求系统主题色，传递当前亮度模式
      final colorString = await _channel.invokeMethod('getSystemColor', {
        'isDarkMode': brightness == Brightness.dark,
      }) as String?;
      
      if (colorString != null && colorString.isNotEmpty) {
        final colorValue = int.tryParse(colorString.replaceFirst('#', 'FF'), radix: 16);
        if (colorValue != null) {
          final color = Color(colorValue);
          
          // 根据亮度模式保存缓存
          if (brightness == Brightness.light) {
            _systemLightColor = color;
          } else {
            _systemDarkColor = color;
          }
          
          return color;
        }
      }
    } catch (e) {
      debugPrint('Error getting system theme color: $e');
    }
    
    return _defaultColor;
  }
  
  /// 创建主题，支持 Material You
  static Future<ThemeData> createTheme({
    required bool useDynamicColor,
    required Color seedColor,
    required Brightness brightness,
  }) async {
    ColorScheme? dynamicColorScheme;
    
    // 如果启用了动态颜色，尝试使用 Material You
    if (useDynamicColor) {
      // 先尝试使用 dynamic_color 库
      dynamicColorScheme = await DynamicColorPlugin.getCorePalette()
          .then(
            (corePalette) => corePalette?.toColorScheme(brightness: brightness),
          );

      // 如果 dynamic_color 库无法获取色彩方案，尝试使用原生通道
      if (dynamicColorScheme == null) {
        try {
          final systemColor = await getSystemThemeColor(brightness: brightness);
          return _buildThemeWithSeedColor(systemColor, brightness);
        } catch (e) {
          debugPrint('Error creating theme with system color: $e');
        }
      }
    }
    
    // 如果上述尝试都失败，则使用提供的种子颜色
    return dynamicColorScheme != null
        ? _buildThemeWithColorScheme(dynamicColorScheme)
        : _buildThemeWithSeedColor(seedColor, brightness);
  }
  
  /// 使用 ColorScheme 构建主题
  static ThemeData _buildThemeWithColorScheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.primary,
      ),
    );
  }

  /// 使用种子颜色构建主题
  static ThemeData _buildThemeWithSeedColor(Color seedColor, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    
    return _buildThemeWithColorScheme(colorScheme);
  }
  
  /// 创建亮色主题（兼容旧方法）
  static ThemeData getLightTheme({Color? seedColor}) {
    return _buildThemeWithSeedColor(seedColor ?? _defaultColor, Brightness.light);
  }

  /// 创建暗色主题（兼容旧方法）
  static ThemeData getDarkTheme({Color? seedColor}) {
    return _buildThemeWithSeedColor(seedColor ?? _defaultColor, Brightness.dark);
  }

  /// 获取主题色
  static MaterialColor getMaterialColor(Color color) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.value, shades);
  }

  /// 获取主题亮度
  static Brightness getBrightness(BuildContext context) {
    return Theme.of(context).brightness;
  }

  /// 检查是否是暗色主题
  static bool isDarkMode(BuildContext context) {
    return getBrightness(context) == Brightness.dark;
  }

  /// 获取主题色
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// 获取次要主题色
  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  /// 获取背景色
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }

  /// 获取表面色
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// 获取错误色
  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  /// 获取文本主色
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// 获取文本次要色
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 获取禁用色
  static Color getDisabledColor(BuildContext context) {
    return Theme.of(context).disabledColor;
  }

  /// 获取分隔线颜色
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  /// 获取卡片颜色
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// 获取阴影颜色
  static Color getShadowColor(BuildContext context) {
    return Theme.of(context).shadowColor;
  }

  /// 获取涟漪效果颜色
  static Color getSplashColor(BuildContext context) {
    return Theme.of(context).splashColor;
  }

  /// 获取高亮颜色
  static Color getHighlightColor(BuildContext context) {
    return Theme.of(context).highlightColor;
  }

  /// 获取提示文本样式
  static TextStyle? getHintStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: getSecondaryTextColor(context),
        );
  }

  /// 获取标题文本样式
  static TextStyle? getTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge;
  }

  /// 获取副标题文本样式
  static TextStyle? getSubtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: getSecondaryTextColor(context),
        );
  }

  /// 获取正文文本样式
  static TextStyle? getBodyStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge;
  }

  /// 获取小号文本样式
  static TextStyle? getSmallStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall;
  }
  
  /// 将颜色转为十六进制字符串
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  /// 从十六进制字符串转换为颜色
  static Color? hexToColor(String hexString) {
    if (hexString.isEmpty) return null;
    
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }
} 