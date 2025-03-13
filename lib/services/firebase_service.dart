import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

/// Firebase服务类，负责初始化Firebase功能并提供分析服务
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() => _instance;
  
  FirebaseService._internal();
  
  late final FirebaseAnalytics _analytics;
  FirebaseAnalytics get analytics => _analytics;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// 初始化Firebase服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      debugPrint('Firebase服务初始化成功');
      
      // 收集设备信息和应用版本
      await _setDeviceProperties();
    } catch (e) {
      debugPrint('Firebase初始化错误: $e');
      // 创建一个空的分析实例，避免空指针异常
      _analytics = FirebaseAnalytics.instance;
    }
  }
  
  /// 收集设备信息和应用版本
  Future<void> _setDeviceProperties() async {
    try {
      // 获取应用信息
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      
      // 设置应用版本用户属性
      await setUserProperty(name: 'app_version', value: '$version+$buildNumber');
      
      // 获取设备信息
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        await setUserProperty(name: 'device_model', value: androidInfo.model);
        await setUserProperty(name: 'android_version', value: androidInfo.version.release);
        await setUserProperty(name: 'device_brand', value: androidInfo.brand);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        await setUserProperty(name: 'device_model', value: iosInfo.model);
        await setUserProperty(name: 'ios_version', value: iosInfo.systemVersion);
      }
      
      // 记录一个事件，包含设备信息和应用版本
      await logEvent(
        name: 'app_info',
        parameters: {
          'app_version': '$version+$buildNumber',
          'platform': Platform.operatingSystem,
        },
      );
    } catch (e) {
      debugPrint('设置设备属性失败: $e');
    }
  }
  
  /// 记录分析事件
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      debugPrint('Firebase未初始化，无法记录事件');
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: name, 
        parameters: parameters,
      );
      debugPrint('Firebase事件已记录: $name');
    } catch (e) {
      debugPrint('Firebase事件记录失败: $e');
    }
  }
  
  /// 设置用户属性
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('设置用户属性失败: $e');
    }
  }
  
  /// 设置当前屏幕
  Future<void> setCurrentScreen({
    required String screenName,
    String screenClassOverride = 'Flutter',
  }) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.setCurrentScreen(
        screenName: screenName,
        screenClassOverride: screenClassOverride,
      );
    } catch (e) {
      debugPrint('设置当前屏幕失败: $e');
    }
  }
  
  /// 记录应用打开事件
  Future<void> logAppOpen() async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('记录应用打开事件失败: $e');
    }
  }
  
  /// 记录分享内容事件
  Future<void> logShare({
    required String contentType,
    required String itemId,
    String method = 'ShareBridge',
  }) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: itemId,
        method: method,
      );
    } catch (e) {
      debugPrint('记录分享事件失败: $e');
    }
  }
  
  /// 记录搜索事件
  Future<void> logSearch({required String searchTerm}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
    } catch (e) {
      debugPrint('记录搜索事件失败: $e');
    }
  }
  
  /// 记录设置变更事件
  Future<void> logSettingsChange({
    required String settingName,
    required String settingValue,
  }) async {
    if (!_isInitialized) return;
    
    try {
      await logEvent(
        name: 'settings_change',
        parameters: {
          'setting_name': settingName,
          'setting_value': settingValue,
        },
      );
    } catch (e) {
      debugPrint('记录设置变更事件失败: $e');
    }
  }
} 