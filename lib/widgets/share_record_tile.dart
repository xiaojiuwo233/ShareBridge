import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/share_record.dart';
import '../providers/app_provider.dart';
import '../services/share_service.dart';
import '../utils/date_utils.dart' as app_date;
import 'package:path/path.dart' as path;

class ShareRecordTile extends StatelessWidget {
  final ShareRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ShareRecordTile({
    super.key,
    required this.record,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final shareService = ShareService();

    return Card(
      margin: const EdgeInsets.only(left: 8, right: 0, bottom: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeadingIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 4),
                    _buildSubtitle(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    switch (record.type) {
      case ShareType.text:
        return const Icon(Icons.text_fields);
      case ShareType.url:
        return const Icon(Icons.link);
      case ShareType.image:
        if (record.sourcePath != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(record.sourcePath!),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image);
              },
            ),
          );
        }
        return const Icon(Icons.image);
      case ShareType.file:
        return const Icon(Icons.insert_drive_file);
      default:
        return const Icon(Icons.help_outline);
    }
  }

  Widget _buildTitle() {
    String title;
    switch (record.type) {
      case ShareType.text:
        title = record.content.length > 50
            ? '${record.content.substring(0, 50)}...'
            : record.content;
        break;
      case ShareType.url:
        title = record.content;
        break;
      case ShareType.image:
        title = '图片';
        break;
      case ShareType.file:
        title = record.sourcePath != null
            ? path.basename(record.sourcePath!)
            : '文件';
        break;
      default:
        title = '未知类型';
    }

    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      }
    );
  }

  Widget _buildSubtitle() {
    final sourceApp = record.sourceApp ?? '未知来源';
    final timeAgo = app_date.DateUtils.formatTimeAgo(record.timestamp);
    
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Text(
          '$sourceApp · $timeAgo',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deleteShareRecord(record.id);
    }
  }
} 