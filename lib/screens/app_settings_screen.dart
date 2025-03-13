import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late TextEditingController _titleController;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _titleController = TextEditingController(
      text: appProvider.settings.customAppBarTitle,
    );
    _firebaseService.setCurrentScreen(screenName: '应用设置');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '应用设置',
          style: TextStyle(color: colorScheme.primary),
        ),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '主页设置',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 自定义AppBar标题
              ListTile(
                leading: Icon(
                  Icons.text_fields,
                  color: colorScheme.primary,
                ),
                title: const Text('自定义主页标题'),
                subtitle: Text(
                  provider.settings.customAppBarTitle == null || 
                  provider.settings.customAppBarTitle == "DEFAULT_TITLE" ? 
                  '默认 (ShareBridge)' : provider.settings.customAppBarTitle!,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                onTap: () {
                  _showTitleEditDialog(context, provider);
                },
              ),
              // 预览效果
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      provider.settings.customAppBarTitle == null || 
                      provider.settings.customAppBarTitle == "DEFAULT_TITLE" ? 
                      'ShareBridge' : provider.settings.customAppBarTitle!,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTitleEditDialog(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '自定义标题',
          style: TextStyle(color: colorScheme.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题文本',
                hintText: '输入自定义标题',
              ),
              maxLength: 20,
            ),
          ],
        ),
        actions: [
          // 横向排列的按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // 设置为特殊的默认标记值，不再使用null
                  provider.updateCustomAppBarTitle("DEFAULT_TITLE");
                  
                  // 关闭对话框并显示提示
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('已恢复默认标题'),
                      backgroundColor: colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  
                  // 更新UI显示
                  setState(() {
                    _titleController.text = '';
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
                child: const Text('恢复默认'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  // 保存用户输入的文本
                  final text = _titleController.text.trim();
                  provider.updateCustomAppBarTitle(text.isEmpty ? "DEFAULT_TITLE" : text);
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 