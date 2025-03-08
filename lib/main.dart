import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/share_service.dart';
import 'utils/theme_utils.dart';
import 'models/app_settings.dart';

// 全局错误处理
void _handleError(Object error, StackTrace stack) {
  debugPrint('Global error: $error');
  debugPrint('Stack trace: $stack');
}

Future<void> main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 设置全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _handleError(details.exception, details.stack ?? StackTrace.empty);
  };

  final appProvider = AppProvider();
  await appProvider.init();

  final shareService = ShareService();
  shareService.onShareReceived = (record) {
    debugPrint('Main: Received share record');
    appProvider.setCurrentShare(record);
  };
  shareService.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<ThemeData>(
          future: _createTheme(provider.settings.themeColorMode,
              provider.settings.customThemeColor, provider.settings.themeMode),
          builder: (context, snapshot) {
            // 如果主题还在加载中，使用默认主题
            if (!snapshot.hasData) {
              final defaultBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
              return MaterialApp(
                title: 'ShareBridge',
                theme: ThemeUtils.getLightTheme(),
                darkTheme: ThemeUtils.getDarkTheme(),
                themeMode: provider.settings.themeMode,
                home: const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                debugShowCheckedModeBanner: false,
              );
            }
            
            // 加载完成后使用动态主题
            final lightTheme = snapshot.data;
            final darkTheme = ThemeUtils.getDarkTheme(
                seedColor: provider.settings.themeColorMode == ThemeColorMode.custom
                    ? provider.settings.customThemeColor
                    : null);
            
            return MaterialApp(
              title: 'ShareBridge',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: provider.settings.themeMode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh'),
                Locale('en'),
              ],
              locale: provider.settings.selectedLanguage != null
                  ? Locale(provider.settings.selectedLanguage!)
                  : null,
              home: const MainScreen(),
              debugShowCheckedModeBanner: false, // 移除调试标签
            );
          },
        );
      },
    );
  }
  
  // 创建主题
  Future<ThemeData> _createTheme(
      ThemeColorMode colorMode, Color customColor, ThemeMode themeMode) async {
    final brightness = themeMode == ThemeMode.dark
        ? Brightness.dark
        : themeMode == ThemeMode.light
            ? Brightness.light
            : WidgetsBinding.instance.platformDispatcher.platformBrightness;
            
    if (colorMode == ThemeColorMode.system) {
      return ThemeUtils.createTheme(
        useDynamicColor: true,
        seedColor: const Color(0xFF2196F3), // 默认蓝色
        brightness: brightness,
      );
    } else {
      return ThemeUtils.createTheme(
        useDynamicColor: false,
        seedColor: customColor,
        brightness: brightness,
      );
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final ShareService _shareService = ShareService();
  bool _isProcessingShare = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shareService.setGlobalContext(context);
      _checkInitialShare();
    });
  }

  @override
  void dispose() {
    _shareService.dispose();
    super.dispose();
  }

  Future<void> _checkInitialShare() async {
    if (_isProcessingShare) return;
    
    setState(() => _isProcessingShare = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final currentShare = provider.currentShare;
      if (currentShare != null) {
        debugPrint('MainScreen: Processing current share');
        await _shareService.showPreviewDialog(context, currentShare);
        provider.setCurrentShare(null);
      }
    } catch (e) {
      debugPrint('Error processing initial share: $e');
    } finally {
      setState(() => _isProcessingShare = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'ShareBridge' : '设置',
          style: TextStyle(color: colorScheme.primary),
        ),
        centerTitle: true,
        shadowColor: colorScheme.primary,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        animationDuration: const Duration(milliseconds: 400),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.timeline, color: _currentIndex == 0 ? colorScheme.primary : null),
            label: '时间线',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, color: _currentIndex == 1 ? colorScheme.primary : null),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
