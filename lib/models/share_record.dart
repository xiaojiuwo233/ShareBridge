
/// 分享记录的类型枚举
enum ShareType {
  text,
  image,
  file,
  url,
  unknown,
}

/// 分享记录模型类
class ShareRecord {
  final String id; // 唯一标识符
  final ShareType type; // 分享类型
  final String content; // 分享内容
  final String? sourcePath; // 源文件路径（如果有）
  final String? sourceApp; // 来源应用
  final DateTime timestamp; // 分享时间
  bool isPinned; // 是否固定/收藏
  String? editedContent; // 编辑后的内容
  
  ShareRecord({
    required this.id,
    required this.type,
    required this.content,
    this.sourcePath,
    this.sourceApp,
    required this.timestamp,
    this.isPinned = false,
    this.editedContent,
  }) {
    // 验证ID不为空
    assert(id.isNotEmpty, 'ID cannot be empty');
    // 验证内容不为空
    assert(content.isNotEmpty, 'Content cannot be empty');
  }

  /// 从JSON创建ShareRecord实例
  factory ShareRecord.fromJson(Map<String, dynamic> json) {
    // 数据验证
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw FormatException('Invalid or missing ID in JSON data');
    }

    final content = json['content'] as String?;
    if (content == null || content.isEmpty) {
      throw FormatException('Invalid or missing content in JSON data');
    }

    // 类型验证
    ShareType type;
    try {
      type = ShareType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ShareType.unknown,
      );
    } catch (_) {
      type = ShareType.unknown;
    }

    // 时间戳验证
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } catch (_) {
      timestamp = DateTime.now();
    }

    return ShareRecord(
      id: id,
      type: type,
      content: content,
      sourcePath: json['sourcePath'] as String?,
      sourceApp: json['sourceApp'] as String?,
      timestamp: timestamp,
      isPinned: json['isPinned'] as bool? ?? false,
      editedContent: json['editedContent'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'content': content,
      'sourcePath': sourcePath,
      'sourceApp': sourceApp,
      'timestamp': timestamp.toIso8601String(),
      'isPinned': isPinned,
      'editedContent': editedContent,
    };
  }

  /// 创建ShareRecord的副本
  ShareRecord copyWith({
    String? id,
    ShareType? type,
    String? content,
    String? sourcePath,
    String? sourceApp,
    DateTime? timestamp,
    bool? isPinned,
    String? editedContent,
  }) {
    return ShareRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      sourcePath: sourcePath ?? this.sourcePath,
      sourceApp: sourceApp ?? this.sourceApp,
      timestamp: timestamp ?? this.timestamp,
      isPinned: isPinned ?? this.isPinned,
      editedContent: editedContent ?? this.editedContent,
    );
  }

  /// 判断两个ShareRecord是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareRecord &&
        other.id == id &&
        other.type == type &&
        other.content == content &&
        other.sourcePath == sourcePath &&
        other.sourceApp == sourceApp &&
        other.timestamp == timestamp &&
        other.isPinned == isPinned &&
        other.editedContent == editedContent;
  }

  /// 生成哈希码
  @override
  int get hashCode => Object.hash(
        id,
        type,
        content,
        sourcePath,
        sourceApp,
        timestamp,
        isPinned,
        editedContent,
      );

  /// 获取显示内容
  String get displayContent => editedContent ?? content;

  /// 检查是否为图片类型
  bool get isImage => type == ShareType.image;

  /// 检查是否为文本类型
  bool get isText => type == ShareType.text;

  /// 检查是否为URL类型
  bool get isUrl => type == ShareType.url;

  /// 检查是否为文件类型
  bool get isFile => type == ShareType.file;
} 