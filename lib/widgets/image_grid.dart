import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../providers/image_provider.dart';
import '../services/image_merger_service.dart';
import '../theme/app_theme.dart';

class ImageGrid extends ConsumerWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageMergerProvider);
    final notifier = ref.read(imageMergerProvider.notifier);

    if (state.images.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            '追加された画像がありません。\n上のエリアに画像をドロップしてください。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'プレビューと並び替え (${state.images.length}枚)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () => notifier.clearAll(),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('すべてクリア'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // プレビュー全体の背景色が設定通りに適用されるようにする
        Container(
          padding: EdgeInsets.all(state.margin.toDouble()),
          decoration: BoxDecoration(
            color: state.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: ReorderableGridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: state.columnCount,
              crossAxisSpacing: state.margin.toDouble(),
              mainAxisSpacing: state.margin.toDouble(),
              childAspectRatio: 1.0, // プレビューのセルは正方形に統一
            ),
            itemCount: state.images.length,
            onReorder: notifier.reorderImages,
            itemBuilder: (context, index) {
              final imageModel = state.images[index];
              return Container(
                key: ValueKey(imageModel.id),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // フィットモードによる画像の配置
                    Positioned.fill(
                      child: Image.memory(
                        imageModel.previewBytes,
                        fit: state.fitMode == FitMode.fit 
                            ? BoxFit.contain 
                            : BoxFit.cover,
                      ),
                    ),
                    // 画像のインデックス番号バッジ（左上）
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // 削除ボタン（右上）
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => notifier.removeImage(imageModel.id),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(150),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ドラッグインジケータ（下部に薄く表示）
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 24,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black87],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.drag_indicator,
                            size: 14,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
