import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';

import '../providers/image_provider.dart';
import '../services/image_merger_service.dart';
import '../theme/app_theme.dart';

class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  // 背景色変更用のダイアログを表示
  void _showColorPicker(BuildContext context, WidgetRef ref, Color currentColor) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('背景色を選択'),
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                ref.read(imageMergerProvider.notifier).updateBackgroundColor(color);
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        );
      },
    );
  }

  // エクスポート処理
  Future<void> _exportImage(BuildContext context, WidgetRef ref) async {
    final state = ref.read(imageMergerProvider);
    final notifier = ref.read(imageMergerProvider.notifier);

    if (state.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像を追加してください。')),
      );
      return;
    }

    try {
      // 結合画像の生成
      final bytes = await notifier.generateMergedImage();
      final ext = state.format == OutputFormat.png ? 'png' : 'jpg';
      final fileName = 'merged_image_${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (kIsWeb) {
        // Webでのダウンロード
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像をダウンロードしました。')),
        );
      } else if (Platform.isAndroid || Platform.isIOS) {
        // モバイルでの共有シート
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        final xFile = XFile(file.path, mimeType: state.format == OutputFormat.png ? 'image/png' : 'image/jpeg');
        
        // iPadでのポップオーバー表示エラーを回避するため、画面中央の位置を指定
        final screenSize = MediaQuery.of(context).size;
        final rect = Rect.fromLTWH(
          screenSize.width / 2 - 10,
          screenSize.height / 2 - 10,
          20,
          20,
        );

        await Share.shareXFiles(
          [xFile], 
          sharePositionOrigin: rect,
        );
      } else {
        // デスクトップでの保存ファイルダイアログ
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: '結合画像を保存',
          fileName: fileName,
          type: FileType.image,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('画像を保存しました: ${file.path}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存中にエラーが発生しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageMergerProvider);
    final notifier = ref.read(imageMergerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '結合設定',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryAccent,
                ),
          ),
          const SizedBox(height: 24),

          // 1. 列数設定
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('列数 (Columns)', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.columnCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryAccent),
                ),
              ),
            ],
          ),
          Slider(
            min: 1,
            max: 8,
            divisions: 7,
            value: state.columnCount.toDouble(),
            onChanged: (val) => notifier.updateColumnCount(val.round()),
          ),
          const SizedBox(height: 16),

          // 2. 余白設定
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('余白サイズ (Margin)', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.margin} px',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryAccent),
                ),
              ),
            ],
          ),
          Slider(
            min: 0,
            max: 100,
            value: state.margin.toDouble(),
            onChanged: (val) => notifier.updateMargin(val.round()),
          ),
          const SizedBox(height: 20),

          // 3. フィットモード
          const Text('フィットモード', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<FitMode>(
            segments: const [
              ButtonSegment<FitMode>(
                value: FitMode.fit,
                label: Text('フィット (余白あり)'),
                icon: Icon(Icons.aspect_ratio),
              ),
              ButtonSegment<FitMode>(
                value: FitMode.cover,
                label: Text('カバー (切り抜き)'),
                icon: Icon(Icons.crop_free),
              ),
            ],
            selected: {state.fitMode},
            onSelectionChanged: (Set<FitMode> val) {
              notifier.updateFitMode(val.first);
            },
          ),
          const SizedBox(height: 24),

          // 4. 背景色
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('背景色', style: TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => _showColorPicker(context, ref, state.backgroundColor),
                child: Container(
                  width: 48,
                  height: 32,
                  decoration: BoxDecoration(
                    color: state.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white30, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: state.backgroundColor.withAlpha(100),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. 保存フォーマット
          const Text('出力形式', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<OutputFormat>(
            segments: const [
              ButtonSegment<OutputFormat>(
                value: OutputFormat.png,
                label: Text('PNG (高品質)'),
              ),
              ButtonSegment<OutputFormat>(
                value: OutputFormat.jpeg,
                label: Text('JPEG'),
              ),
            ],
            selected: {state.format},
            onSelectionChanged: (Set<OutputFormat> val) {
              notifier.updateFormat(val.first);
            },
          ),
          const SizedBox(height: 32),

          // 6. エクスポートボタン
          ElevatedButton.icon(
            onPressed: state.isProcessing ? null : () => _exportImage(context, ref),
            icon: state.isProcessing 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.ios_share),
            label: Text(
              state.isProcessing ? '処理中...' : '画像を保存する',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppTheme.accentColor.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
