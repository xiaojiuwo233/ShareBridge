import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/share_service.dart';
import 'utils/theme_utils.dart';

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
        return MaterialApp(
          title: 'ShareBridge',
          theme: ThemeUtils.getLightTheme(),
          darkTheme: ThemeUtils.getDarkTheme(),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'ShareBridge' : '设置'),
        centerTitle: true,
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timeline),
            label: '时间线',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
