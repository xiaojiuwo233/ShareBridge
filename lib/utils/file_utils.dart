import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 文件工具类
class FileUtils {
  /// 获取应用的临时目录
  static Future<Directory> get tempDir async {
    try {
      return await getTemporaryDirectory();
    } catch (e) {
      debugPrint('Error getting temp directory: $e');
      rethrow;
    }
  }

  /// 获取应用的文档目录
  static Future<Directory> get documentsDir async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('Error getting documents directory: $e');
      rethrow;
    }
  }

  /// 获取应用的永久存储目录（用于存储分享文件）
  static Future<Directory> get sharedFilesDir async {
    try {
      final docs = await documentsDir;
      final sharedDir = Directory('${docs.path}/shared_files');
      if (!await sharedDir.exists()) {
        await sharedDir.create(recursive: true);
      }
      return sharedDir;
    } catch (e) {
      debugPrint('Error getting shared files directory: $e');
      rethrow;
    }
  }

  /// 获取文件的MIME类型
  static String? getMimeType(String filePath) {
    if (filePath.isEmpty) return null;
    
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.7z':
        return 'application/x-7z-compressed';
      case '.mp3':
        return 'audio/mpeg';
      case '.mp4':
        return 'video/mp4';
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';
      case '.html':
      case '.htm':
        return 'text/html';
      case '.css':
        return 'text/css';
      case '.js':
        return 'application/javascript';
      default:
        return 'application/octet-stream';
    }
  }

  /// 检查文件是否是图片
  static bool isImage(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType?.startsWith('image/') ?? false;
  }

  /// 检查文件是否是视频
  static bool isVideo(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType?.startsWith('video/') ?? false;
  }

  /// 检查文件是否是音频
  static bool isAudio(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType?.startsWith('audio/') ?? false;
  }

  /// 将文件复制到永久存储目录
  static Future<File?> saveSharedFile(String sourcePath) async {
    try {
      if (sourcePath.isEmpty) {
        throw ArgumentError('Source path cannot be empty');
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('Source file does not exist', sourcePath);
      }

      // 检查文件大小
      final fileSize = await sourceFile.length();
      if (fileSize > 100 * 1024 * 1024) { // 100MB
        throw const FileSystemException('File too large (max 100MB)');
      }

      // 获取存储目录
      final storageDir = await sharedFilesDir;
      final fileName = path.basename(sourcePath);
      
      // 创建带时间戳的文件名，确保唯一性
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName);
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      final newFileName = '$nameWithoutExt-$timestamp$extension';
      final targetPath = path.join(storageDir.path, newFileName);
      
      // 复制文件到永久存储目录
      return await sourceFile.copy(targetPath);
    } catch (e) {
      debugPrint('Error saving shared file: $e');
      return null;
    }
  }

  /// 复制文件到应用的文档目录（保留用于兼容现有代码）
  static Future<File?> copyToDocuments(String sourcePath) async {
    try {
      if (sourcePath.isEmpty) {
        throw ArgumentError('Source path cannot be empty');
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException('Source file does not exist', sourcePath);
      }

      // 检查文件大小
      final fileSize = await sourceFile.length();
      if (fileSize > 100 * 1024 * 1024) { // 100MB
        throw const FileSystemException('File too large (max 100MB)');
      }

      // 直接调用新方法进行永久存储
      return await saveSharedFile(sourcePath);
    } catch (e) {
      debugPrint('Error copying file: $e');
      return null;
    }
  }

  /// 删除文件及其所有临时副本
  static Future<bool> deleteFile(String filePath) async {
    try {
      if (filePath.isEmpty) {
        throw ArgumentError('File path cannot be empty');
      }

      bool result = false;
      
      // 删除主文件
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        result = true;
      }
      
      // 尝试删除可能存在的临时文件
      final fileName = path.basename(filePath);
      
      // 检查并删除缓存目录中的文件
      try {
        final tempDirectory = await tempDir;
        final tempFilePath = path.join(tempDirectory.path, fileName);
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
      
      // 检查并删除share_plus缓存目录中的文件
      try {
        final tempDirectory = await tempDir;
        final sharePlusDir = Directory('${tempDirectory.path}/share_plus');
        if (await sharePlusDir.exists()) {
          final sharePlusFilePath = path.join(sharePlusDir.path, fileName);
          final sharePlusFile = File(sharePlusFilePath);
          if (await sharePlusFile.exists()) {
            await sharePlusFile.delete();
          }
        }
      } catch (e) {
        debugPrint('Error deleting share_plus temp file: $e');
      }
      
      return result;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// 检查文件是否存在
  static Future<bool> exists(String filePath) async {
    try {
      if (filePath.isEmpty) return false;
      return await File(filePath).exists();
    } catch (e) {
      debugPrint('Error checking file existence: $e');
      return false;
    }
  }

  /// 获取文件大小（以字节为单位）
  static Future<int> getFileSize(String filePath) async {
    try {
      if (filePath.isEmpty) {
        throw ArgumentError('File path cannot be empty');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File does not exist', filePath);
      }

      return await file.length();
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    i = i < suffixes.length ? i : suffixes.length - 1;
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// 清理临时文件
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        // 获取所有文件
        final entities = await tempDir.list().toList();
        
        // 获取24小时前的时间
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(hours: 24));
        
        // 删除24小时前的文件
        for (var entity in entities) {
          try {
            if (entity is File) {
              final stat = await entity.stat();
              if (stat.modified.isBefore(yesterday)) {
                await entity.delete();
              }
            } else if (entity is Directory && path.basename(entity.path) == 'share_plus') {
              // 特别处理share_plus目录
              final shareFiles = await entity.list().toList();
              for (var shareFile in shareFiles) {
                if (shareFile is File) {
                  final stat = await shareFile.stat();
                  if (stat.modified.isBefore(yesterday)) {
                    await shareFile.delete();
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('Error deleting temp file: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }

  /// 创建目录
  static Future<Directory?> createDirectory(String dirPath) async {
    try {
      if (dirPath.isEmpty) {
        throw ArgumentError('Directory path cannot be empty');
      }

      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return await dir.create(recursive: true);
      }
      return dir;
    } catch (e) {
      debugPrint('Error creating directory: $e');
      return null;
    }
  }

  /// 获取文件扩展名
  static String getFileExtension(String filePath) {
    if (filePath.isEmpty) return '';
    return path.extension(filePath).toLowerCase();
  }

  /// 获取文件名（不含扩展名）
  static String getFileNameWithoutExtension(String filePath) {
    if (filePath.isEmpty) return '';
    return path.basenameWithoutExtension(filePath);
  }

  /// 获取文件名（含扩展名）
  static String getFileName(String filePath) {
    if (filePath.isEmpty) return '';
    return path.basename(filePath);
  }
}

/// 文件大小计算扩展
extension FileSizeExtension on int {
  String get fileSize => FileUtils.formatFileSize(this);
} 