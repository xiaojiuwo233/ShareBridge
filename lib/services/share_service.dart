import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../models/share_record.dart';
import '../providers/app_provider.dart';
import '../utils/file_utils.dart';
import '../widgets/preview_dialog.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

class ShareService {
  // 单例模式
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  // 监听分享数据的回调
  Function(ShareRecord)? onShareReceived;
  StreamSubscription? _intentDataStreamSubscription;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  // 全局 context
  BuildContext? _globalContext;
  
  final FirebaseService _firebaseService = FirebaseService();
  
  // 设置全局 context
  void setGlobalContext(BuildContext context) {
    _globalContext = context;
  }

  // 初始化分享服务
  void init() {
    if (_isInitialized) {
      debugPrint('ShareService already initialized');
      return;
    }

    debugPrint('Initializing ShareService...');

    try {
      // 监听运行时的分享
      _intentDataStreamSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen((List<SharedMediaFile> value) {
        debugPrint('Received share: ${value.length} files');
        _handleSharedFiles(value);
      }, onError: (err) {
        debugPrint("getMediaStream error: $err");
      });

      // 处理初始分享（从其他应用启动）
      ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
        debugPrint('Processing initial share...');
        if (value.isNotEmpty) {
          debugPrint('Initial share: ${value.length} files');
          _handleSharedFiles(value);
          // 处理完初始分享后重置
          ReceiveSharingIntent.instance.reset();
        }
      }).catchError((error) {
        debugPrint('Error processing initial share: $error');
      });

      _isInitialized = true;
      debugPrint('ShareService initialized');
    } catch (e) {
      debugPrint('Error initializing ShareService: $e');
    }
  }

  // 持久化存储图片
  Future<String?> _persistImage(String sourcePath) async {
    debugPrint('Persisting image: $sourcePath');
    try {
      final docsDir = await FileUtils.documentsDir;
      final fileName = p.basename(sourcePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final persistedFileName = '${p.basenameWithoutExtension(fileName)}_$timestamp${p.extension(fileName)}';
      final targetPath = p.join(docsDir.path, 'images', persistedFileName);
      
      // 创建images目录
      final imageDir = Directory(p.join(docsDir.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      // 检查源文件
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      // 检查文件大小
      final fileSize = await sourceFile.length();
      if (fileSize > 100 * 1024 * 1024) { // 100MB
        throw Exception('File too large: ${fileSize / 1024 / 1024}MB');
      }
      
      // 复制文件
      final newFile = await sourceFile.copy(targetPath);
      debugPrint('Image persisted to: ${newFile.path}');
      return newFile.path;
    } catch (e) {
      debugPrint('Error persisting image: $e');
      return null;
    }
  }

  // 处理分享的文件
  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    if (_isProcessing) {
      debugPrint('Already processing files, skipping...');
      return;
    }

    if (files.isEmpty) {
      debugPrint('No files to process');
      return;
    }

    _isProcessing = true;
    debugPrint('Processing shared files: ${files.length}');

    try {
      for (final file in files) {
        debugPrint('Processing file: ${file.path}, type: ${file.type}, message: ${file.message}');
        
        final String id = DateTime.now().millisecondsSinceEpoch.toString();
        final ShareType type;
        final String content;
        String? persistedPath;

        // 根据分享类型处理
        switch (file.type) {
          case SharedMediaType.text:
            type = ShareType.text;
            content = file.message ?? file.path;
            if (content.isEmpty) {
              debugPrint('Empty text content, skipping...');
              continue;
            }
            debugPrint('Text content: $content');
            break;
          case SharedMediaType.url:
            type = ShareType.url;
            content = file.path;
            final uri = Uri.tryParse(content);
            if (uri == null || !uri.hasAbsolutePath) {
              debugPrint('Invalid URL: $content, skipping...');
              continue;
            }
            debugPrint('URL content: $content');
            break;
          case SharedMediaType.image:
            type = ShareType.image;
            // 持久化存储图片
            persistedPath = await _persistImage(file.path);
            if (persistedPath == null) {
              debugPrint('Failed to persist image, skipping...');
              continue;
            }
            content = persistedPath;
            debugPrint('Image path: $content');
            break;
          case SharedMediaType.video:
          case SharedMediaType.file:
            type = ShareType.file;
            final sourceFile = File(file.path);
            if (!await sourceFile.exists()) {
              debugPrint('File does not exist: ${file.path}, skipping...');
              continue;
            }
            content = file.path;
            debugPrint('File path: $content');
            break;
        }

        final record = ShareRecord(
          id: id,
          type: type,
          content: content,
          sourcePath: persistedPath ?? (file.type == SharedMediaType.text ? null : file.path),
          sourceApp: file.mimeType,
          timestamp: DateTime.now(),
        );

        debugPrint('Created ShareRecord: ${record.type}, ${record.content}, ${record.sourcePath}');
        
        // 立即显示预览对话框
        if (_globalContext != null) {
          debugPrint('Showing preview dialog immediately');
          await showPreviewDialog(_globalContext!, record);
        } else {
          debugPrint('No global context available, using callback');
          onShareReceived?.call(record);
        }
      }
    } catch (e) {
      debugPrint('Error processing files: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // 执行分享
  Future<void> share(ShareRecord record) async {
    try {
      if (record.type == ShareType.image && record.sourcePath != null) {
        final file = File(record.sourcePath!);
        if (await file.exists()) {
          await Share.shareXFiles([XFile(record.sourcePath!)]);
          
          // 记录分享事件
          _firebaseService.logShare(
            contentType: "image",
            itemId: record.id,
          );
        }
      } else if (record.type == ShareType.file && record.sourcePath != null) {
        final file = File(record.sourcePath!);
        if (await file.exists()) {
          await Share.shareXFiles([XFile(record.sourcePath!)]);
          
          // 记录分享事件
          _firebaseService.logShare(
            contentType: "file",
            itemId: record.id,
          );
        }
      } else if (record.type == ShareType.text || record.type == ShareType.url) {
        final text = record.displayContent;
        await Share.share(text);
        
        // 记录分享事件
        _firebaseService.logShare(
          contentType: record.type == ShareType.url ? "url" : "text",
          itemId: record.id,
        );
      }
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (_globalContext != null) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  // 显示预览对话框
  Future<void> showPreviewDialog(BuildContext context, ShareRecord record) async {
    debugPrint('Showing preview dialog for: ${record.type}, ${record.content}');
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // 检查文件是否存在
    if ((record.type == ShareType.image || record.type == ShareType.file) && 
        record.sourcePath != null) {
      bool fileExists = await FileUtils.exists(record.sourcePath!);
      if (!fileExists) {
        debugPrint('File not found: ${record.sourcePath}');
        await _showFileDeletedDialog(context, record);
        return;
      }
    }
    
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PreviewDialog(
          record: record,
          recordHistory: provider.settings.recordHistory,
          onShare: (editedRecord, recordHistory, deleteSourceFile) async {
            debugPrint('Preview dialog: sharing edited record');
            debugPrint('Record history: $recordHistory, Delete source: $deleteSourceFile');
            
            try {
              // 保存到历史记录
              if (recordHistory) {
                await provider.addShareRecord(editedRecord);
                debugPrint('Added to history');
              }
              
              // 执行分享
              await share(editedRecord);
              
              // 删除源文件
              if (deleteSourceFile && editedRecord.sourcePath != null) {
                try {
                  final file = File(editedRecord.sourcePath!);
                  if (await file.exists()) {
                    await file.delete();
                    debugPrint('Deleted source file: ${editedRecord.sourcePath}');
                  }
                } catch (e) {
                  debugPrint('Error deleting source file: $e');
                }
              }
            } catch (e) {
              debugPrint('Error in preview dialog: $e');
              // 显示错误提示
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('分享失败: ${e.toString()}')),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error showing preview dialog: $e');
    }
  }
  
  // 显示文件已被清理的对话框
  Future<void> _showFileDeletedDialog(BuildContext context, ShareRecord record) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('文件已被清理'),
        content: const Text('此文件已不存在，可能已被系统或其他应用清理。'),
        actions: [
          TextButton(
            onPressed: () async {
              if (record.sourcePath != null) {
                try {
                  // 确保所有相关临时文件也被清理
                  await FileUtils.deleteFile(record.sourcePath!);
                } catch (e) {
                  debugPrint('Error deleting file references: $e');
                }
              }
              // 删除记录
              await provider.deleteShareRecord(record.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('删除记录'),
          ),
        ],
      ),
    );
  }

  // 检查分享记录的文件是否存在
  Future<bool> isFileExists(ShareRecord record) async {
    if (record.type != ShareType.image && record.type != ShareType.file) {
      return true; // 文本和URL类型不需要检查文件
    }
    
    if (record.sourcePath == null) {
      return false;
    }
    
    return await FileUtils.exists(record.sourcePath!);
  }

  // 清理资源
  void dispose() {
    debugPrint('Disposing ShareService');
    _intentDataStreamSubscription?.cancel();
    _isInitialized = false;
    _isProcessing = false;
    _globalContext = null;
  }
} 