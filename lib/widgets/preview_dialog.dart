import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/share_record.dart';

class PreviewDialog extends StatefulWidget {
  final ShareRecord record;
  final bool recordHistory;
  final bool deleteSourceFile;
  final Function(ShareRecord, bool, bool) onShare;
  
  const PreviewDialog({
    super.key,
    required this.record,
    this.recordHistory = true,
    this.deleteSourceFile = false,
    required this.onShare,
  });

  @override
  State<PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<PreviewDialog> {
  late TextEditingController _textController;
  late bool _recordHistory;
  late bool _deleteSourceFile;
  String? _editedImagePath;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.record.content);
    _recordHistory = widget.recordHistory;
    _deleteSourceFile = widget.deleteSourceFile;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _cropImage() async {
    final sourcePath = widget.record.sourcePath;
    if (sourcePath == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 90,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _editedImagePath = croppedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ShareBridge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildPreviewContent(),
            const SizedBox(height: 16),
            _buildOptions(),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    switch (widget.record.type) {
      case ShareType.text:
      case ShareType.url:
        return TextField(
          controller: _textController,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '编辑文本',
          ),
        );
      case ShareType.image:
        return Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Image.file(
                File(_editedImagePath ?? widget.record.sourcePath!),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _cropImage,
              icon: const Icon(Icons.crop),
              label: const Text('裁剪图片'),
            ),
          ],
        );
      default:
        return const Text('不支持的内容类型');
    }
  }

  Widget _buildOptions() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('记录历史'),
          value: _recordHistory,
          onChanged: (value) {
            setState(() {
              _recordHistory = value ?? true;
            });
          },
        ),
        if (widget.record.sourcePath != null)
          CheckboxListTile(
            title: const Text('分享后删除源文件'),
            value: _deleteSourceFile,
            onChanged: (value) {
              setState(() {
                _deleteSourceFile = value ?? false;
              });
            },
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final editedRecord = widget.record.copyWith(
              editedContent: _textController.text,
              sourcePath: _editedImagePath ?? widget.record.sourcePath,
            );
            widget.onShare(editedRecord, _recordHistory, _deleteSourceFile);
            Navigator.of(context).pop();
          },
          child: const Text('分享'),
        ),
      ],
    );
  }
} 