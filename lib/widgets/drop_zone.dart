import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/image_provider.dart';
import '../theme/app_theme.dart';

class DropZone extends ConsumerStatefulWidget {
  const DropZone({super.key});

  @override
  ConsumerState<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends ConsumerState<DropZone> {
  bool _isDragging = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true, // Web/モバイル環境でもバイトデータを確実に取得するため
    );

    if (result != null && result.files.isNotEmpty) {
      final validFiles = <({String name, Uint8List bytes})>[];
      for (final file in result.files) {
        if (file.bytes != null) {
          validFiles.add((name: file.name, bytes: file.bytes!));
        }
      }
      if (validFiles.isNotEmpty) {
        await ref.read(imageMergerProvider.notifier).addImagesFromBytes(validFiles);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) async {
        final validFiles = <({String name, Uint8List bytes})>[];
        for (final file in details.files) {
          try {
            final bytes = await file.readAsBytes();
            validFiles.add((name: file.name, bytes: bytes));
          } catch (e) {
            debugPrint('Error reading dropped file: $e');
          }
        }
        if (validFiles.isNotEmpty) {
          await ref.read(imageMergerProvider.notifier).addImagesFromBytes(validFiles);
        }
      },
      onDragEntered: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      child: GestureDetector(
        onTap: _pickFiles,
        child: Container(
          height: 180,
          decoration: AppTheme.glassDecoration(
            borderRadius: 20,
            color: _isDragging 
                ? AppTheme.accentColor.withAlpha(50) 
                : AppTheme.cardColor,
            borderColor: _isDragging 
                ? AppTheme.accentColor 
                : AppTheme.cardBorderColor,
          ),
          child: Stack(
            children: [
              // 波打つグラデーション背景エフェクト（簡易版）
              Positioned.fill(
                child: Opacity(
                  opacity: _isDragging ? 0.2 : 0.05,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [AppTheme.secondaryAccent, Colors.transparent],
                        radius: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isDragging ? Icons.downloading : Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: _isDragging ? AppTheme.secondaryAccent : AppTheme.textPrimaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isDragging ? 'ここにドロップ！' : '画像をドラッグ＆ドロップ、またはクリックして選択',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isDragging ? AppTheme.secondaryAccent : AppTheme.textPrimaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '複数画像の選択に対応 • PNG, JPG',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
