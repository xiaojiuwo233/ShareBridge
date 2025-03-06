import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/share_record.dart';
import '../services/share_service.dart';
import '../widgets/share_record_tile.dart';
import '../widgets/image_preview_screen.dart';
import '../utils/file_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final pinnedRecords = provider.pinnedRecords;
        final unpinnedRecords = provider.unpinnedRecords;
        final colorScheme = Theme.of(context).colorScheme;
        
        if (provider.history.isEmpty) {
          return const Center(
            child: Text('暂无分享记录'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pinnedRecords.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '已固定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              ...pinnedRecords.map((record) => ShareRecordTile(
                record: record,
                onTap: () {
                  // 检查文件是否存在，ShareService会处理文件不存在的情况
                  ShareService().showPreviewDialog(context, record);
                },
                onLongPress: () {
                  _showActionMenu(context, record, provider);
                },
              )),
              const Divider(height: 32),
            ],
            if (unpinnedRecords.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '时间线',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              ..._buildTimelineRecords(context, unpinnedRecords, provider),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildTimelineRecords(
    BuildContext context, 
    List<ShareRecord> records, 
    AppProvider provider
  ) {
    // 按日期分组记录
    final Map<String, List<ShareRecord>> groupedRecords = {};
    
    for (final record in records) {
      final date = DateFormat('yyyy-MM-dd').format(record.timestamp);
      if (!groupedRecords.containsKey(date)) {
        groupedRecords[date] = [];
      }
      groupedRecords[date]!.add(record);
    }

    // 排序日期
    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    // 获取Material You主题颜色
    final primaryColor = Theme.of(context).colorScheme.primary;
    final dividerColor = Theme.of(context).dividerColor;
    
    // 创建日期组件列表
    List<Widget> dateWidgets = [];
    
    // 为每个日期组构建内容
    for (int dateIndex = 0; dateIndex < sortedDates.length; dateIndex++) {
      final date = sortedDates[dateIndex];
      final dateRecords = groupedRecords[date]!;
      
      // 1. 添加日期标签和点
      dateWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧布局（时间线和点）
              SizedBox(
                width: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 日期文本区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    _formatDateHeader(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      
      // 2. 添加该日期下的所有记录
      for (final record in dateRecords) {
        dateWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧占位（与时间线对齐）
                const SizedBox(width: 24),
                
                // 记录卡片
                Expanded(
                  child: ShareRecordTile(
                    record: record,
                    onTap: () {
                      // 检查文件是否存在，然后再显示预览对话框
                      // ShareService会处理文件不存在的情况
                      ShareService().showPreviewDialog(context, record);
                    },
                    onLongPress: () {
                      _showActionMenu(context, record, provider);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    // 构建一个连续的时间线布局
    return [
      Container(
        margin: const EdgeInsets.only(top: 8),
        child: Stack(
          children: [
            // 第一层：绘制连续的垂直线（贯穿整个时间线）
            Positioned(
              left: 11.5, // 微调位置使其与点完全居中对齐
              top: 0,
              bottom: 0,
              width: 2,
              child: Container(color: dividerColor),
            ),
            
            // 第二层：添加内容（日期点和卡片）
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dateWidgets,
            ),
          ],
        ),
      ),
    ];
  }
  
  String _formatDateHeader(String dateStr) {
    final now = DateTime.now();
    final date = DateTime.parse(dateStr);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '今天';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return '昨天';
    } else {
      return DateFormat('yyyy年MM月dd日').format(date);
    }
  }

  void _showActionMenu(BuildContext context, ShareRecord record, AppProvider provider) {
    final shareService = ShareService();
    final colorScheme = Theme.of(context).colorScheme;
    
    // 检查文件是否存在
    shareService.isFileExists(record).then((fileExists) {
      showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('操作', style: TextStyle(color: colorScheme.primary)),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showRecordDetails(context, record);
              },
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 16),
                  Text('查看详情', style: TextStyle(color: colorScheme.onSurface)),
                ],
              ),
            ),
            // 只有在文件存在时才显示查看大图选项
            if (record.type == ShareType.image && record.sourcePath != null && fileExists)
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
                child: Row(
                  children: [
                    Icon(Icons.image, color: colorScheme.primary),
                    const SizedBox(width: 16),
                    Text('查看大图', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
            // 只有在文件存在时才显示编辑选项
            if (fileExists)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  ShareService().showPreviewDialog(context, record);
                },
                child: Row(
                  children: [
                    Icon(Icons.edit, color: colorScheme.primary),
                    const SizedBox(width: 16),
                    Text('编辑', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
            // 只有在文件存在时才显示分享选项
            if (fileExists)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  ShareService().share(record);
                },
                child: Row(
                  children: [
                    Icon(Icons.share, color: colorScheme.primary),
                    const SizedBox(width: 16),
                    Text('分享', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
            // 只有在文件存在时才显示固定/取消固定选项
            if (fileExists)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  provider.toggleRecordPin(record.id);
                },
                child: Row(
                  children: [
                    Icon(
                      record.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: colorScheme.primary
                    ),
                    const SizedBox(width: 16),
                    Text(
                      record.isPinned ? '取消固定' : '固定',
                      style: TextStyle(color: colorScheme.onSurface)
                    ),
                  ],
                ),
              ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('确认删除', style: TextStyle(color: colorScheme.primary)),
                    content: Text('确定要删除这条记录吗？', style: TextStyle(color: colorScheme.onSurface)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('取消', style: TextStyle(color: colorScheme.primary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('删除', style: TextStyle(color: colorScheme.error)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  // 先删除源文件
                  if (record.sourcePath != null) {
                    try {
                      // 使用FileUtils工具类删除文件及其临时副本
                      await FileUtils.deleteFile(record.sourcePath!);
                    } catch (e) {
                      debugPrint('Error deleting source file: $e');
                    }
                  }
                  // 然后删除记录
                  await provider.deleteShareRecord(record.id);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.delete, color: colorScheme.error),
                  const SizedBox(width: 16),
                  Text('删除', style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showRecordDetails(BuildContext context, ShareRecord record) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('详细信息', style: TextStyle(color: colorScheme.primary)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('类型', _getTypeString(record.type)),
              _buildDetailItem('分享时间', DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp)),
              if (record.sourceApp != null)
                _buildDetailItem('来源应用', record.sourceApp!),
              if (record.sourcePath != null)
                _buildDetailItem('文件路径', record.sourcePath!),
              // 只有非图片类型才显示内容
              if (record.type == ShareType.text)
                _buildDetailItem('内容', record.displayContent),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  String _getTypeString(ShareType type) {
    switch (type) {
      case ShareType.text:
        return '文本';
      case ShareType.image:
        return '图片';
      case ShareType.file:
        return '文件';
      case ShareType.url:
        return '链接';
      default:
        return '未知';
    }
  }
} 