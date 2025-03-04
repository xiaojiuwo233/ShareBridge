import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/share_record.dart';
import '../services/share_service.dart';
import '../widgets/share_record_tile.dart';
import '../widgets/image_preview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final pinnedRecords = provider.pinnedRecords;
        final unpinnedRecords = provider.unpinnedRecords;
        
        if (provider.history.isEmpty) {
          return const Center(
            child: Text('暂无分享记录'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pinnedRecords.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '已固定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...pinnedRecords.map((record) => ShareRecordTile(
                record: record,
                onTap: () {
                  ShareService().showPreviewDialog(context, record);
                },
                onLongPress: () {
                  _showActionMenu(context, record, provider);
                },
              )),
              const Divider(height: 32),
            ],
            if (unpinnedRecords.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '历史',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...unpinnedRecords.map((record) => ShareRecordTile(
                record: record,
                onTap: () {
                  ShareService().showPreviewDialog(context, record);
                },
                onLongPress: () {
                  _showActionMenu(context, record, provider);
                },
              )),
            ],
          ],
        );
      },
    );
  }

  void _showActionMenu(BuildContext context, ShareRecord record, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('操作'),
        children: [
          if (record.type == ShareType.image)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImagePreviewScreen(
                      imagePath: record.sourcePath!,
                    ),
                  ),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.image),
                  SizedBox(width: 16),
                  Text('查看大图'),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              ShareService().showPreviewDialog(context, record);
            },
            child: const Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 16),
                Text('编辑'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              ShareService().share(record);
            },
            child: const Row(
              children: [
                Icon(Icons.share),
                SizedBox(width: 16),
                Text('分享'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              provider.toggleRecordPin(record.id);
            },
            child: Row(
              children: [
                Icon(record.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                const SizedBox(width: 16),
                Text(record.isPinned ? '取消固定' : '固定'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('确定要删除这条记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await provider.deleteShareRecord(record.id);
                if (record.type == ShareType.image && record.sourcePath != null) {
                  try {
                    final file = File(record.sourcePath!);
                    if (await file.exists()) {
                      await file.delete();
                    }
                  } catch (e) {
                    debugPrint('Error deleting image file: $e');
                  }
                }
              }
            },
            child: const Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 16),
                Text('删除', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 