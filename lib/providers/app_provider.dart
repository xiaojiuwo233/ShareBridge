import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/share_record.dart';
import '../utils/file_utils.dart';

class AppProvider with ChangeNotifier {
  static const String _settingsKey = 'app_settings';
  static const String _historyKey = 'share_history';
  static const int _maxHistorySize = 1000; // 最大历史记录数量
  
  late SharedPreferences _prefs;
  AppSettings _settings;
  List<ShareRecord> _history;
  ShareRecord? _currentShare;
  bool _isInitialized = false;

  AppProvider()
      : _settings = const AppSettings(),
        _history = [];

  // Getters
  AppSettings get settings => _settings;
  List<ShareRecord> get history => List.unmodifiable(_history);
  ShareRecord? get currentShare => _currentShare;
  bool get isDarkMode => _settings.themeMode == ThemeMode.dark ||
      (_settings.themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);
  bool get isInitialized => _isInitialized;

  // 初始化
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('AppProvider already initialized');
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      await Future.wait([
        _loadSettings(),
        _loadHistory(),
      ]);
      
      // 清理临时文件
      _cleanupTempFiles();
      
      _isInitialized = true;
      debugPrint('AppProvider initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AppProvider: $e');
      // 使用默认值
      _settings = const AppSettings();
      _history = [];
      _isInitialized = true;
    }
  }

  // 清理临时文件
  Future<void> _cleanupTempFiles() async {
    try {
      // 在后台线程中执行清理，避免阻塞UI
      FileUtils.cleanupTempFiles().then((_) {
        debugPrint('Temporary files cleanup completed');
      });
    } catch (e) {
      debugPrint('Error during temp files cleanup: $e');
    }
  }

  // 加载设置
  Future<void> _loadSettings() async {
    try {
      final String? settingsJson = _prefs.getString(_settingsKey);
      if (settingsJson != null) {
        _settings = AppSettings.fromJson(jsonDecode(settingsJson));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _settings = const AppSettings();
    }
  }

  // 加载历史记录
  Future<void> _loadHistory() async {
    try {
      final String? historyJson = _prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _history = historyList
            .map((item) => ShareRecord.fromJson(item))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // 限制历史记录数量
        if (_history.length > _maxHistorySize) {
          _history = _history.sublist(0, _maxHistorySize);
          await _saveHistory();
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      _history = [];
    }
  }

  // 保存设置
  Future<void> _saveSettings() async {
    try {
      await _prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // 保存历史记录
  Future<void> _saveHistory() async {
    try {
      await _prefs.setString(_historyKey,
          jsonEncode(_history.map((record) => record.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  // 更新设置
  Future<void> updateSettings(AppSettings newSettings) async {
    if (_settings == newSettings) return; // 避免不必要的更新
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  // 更新主题模式
  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_settings.themeMode == mode) return;
    _settings = _settings.copyWith(themeMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  // 更新预览模式
  Future<void> updatePreviewMode(PreviewMode mode) async {
    if (_settings.previewMode == mode) return;
    _settings = _settings.copyWith(previewMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  // 更新语言设置
  Future<void> updateLanguage(String? languageCode) async {
    if (_settings.selectedLanguage == languageCode) return;
    _settings = _settings.copyWith(selectedLanguage: languageCode);
    await _saveSettings();
    notifyListeners();
  }

  // 更新分享提供者状态
  Future<void> updateShareProvider(String provider, bool enabled) async {
    if (_settings.shareProviders[provider] == enabled) return;
    final Map<String, bool> newProviders = Map.from(_settings.shareProviders);
    newProviders[provider] = enabled;
    _settings = _settings.copyWith(shareProviders: newProviders);
    await _saveSettings();
    notifyListeners();
  }

  // 设置当前分享内容
  void setCurrentShare(ShareRecord? record) {
    if (_currentShare == record) return;
    _currentShare = record;
    notifyListeners();
  }

  // 添加分享记录
  Future<void> addShareRecord(ShareRecord record) async {
    // 检查是否已存在相同ID的记录
    if (_history.any((item) => item.id == record.id)) {
      debugPrint('Record with ID ${record.id} already exists');
      return;
    }

    _history.insert(0, record);
    
    // 限制历史记录数量
    if (_history.length > _maxHistorySize) {
      _history = _history.sublist(0, _maxHistorySize);
    }
    
    await _saveHistory();
    notifyListeners();
  }

  // 更新分享记录
  Future<void> updateShareRecord(ShareRecord record) async {
    final index = _history.indexWhere((item) => item.id == record.id);
    if (index != -1) {
      _history[index] = record;
      await _saveHistory();
      notifyListeners();
    }
  }

  // 删除分享记录
  Future<void> deleteShareRecord(String id) async {
    final initialLength = _history.length;
    _history.removeWhere((record) => record.id == id);
    if (_history.length != initialLength) {
      await _saveHistory();
      notifyListeners();
    }
  }

  // 切换记录的固定状态
  Future<void> toggleRecordPin(String id) async {
    final index = _history.indexWhere((record) => record.id == id);
    if (index != -1) {
      final record = _history[index];
      record.isPinned = !record.isPinned;
      
      // 重新排序：将固定的记录移到对应分组的顶部
      if (record.isPinned) {
        _history.removeAt(index);
        _history.insert(0, record);
      }
      
      await _saveHistory();
      notifyListeners();
    }
  }

  // 获取固定的记录
  List<ShareRecord> get pinnedRecords =>
      List.unmodifiable(_history.where((record) => record.isPinned));

  // 获取未固定的记录
  List<ShareRecord> get unpinnedRecords =>
      List.unmodifiable(_history.where((record) => !record.isPinned));

  // 清除所有历史记录
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  // 清除未固定的历史记录
  Future<void> clearUnpinnedHistory() async {
    _history.removeWhere((record) => !record.isPinned);
    await _saveHistory();
    notifyListeners();
  }
} 