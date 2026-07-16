import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../models/image_model.dart';
import '../services/image_merger_service.dart';

class ImageMergerState {
  final List<ImageModel> images;
  final int columnCount;
  final int margin;
  final Color backgroundColor;
  final FitMode fitMode;
  final OutputFormat format;
  final bool isProcessing;

  ImageMergerState({
    this.images = const [],
    this.columnCount = 2,
    this.margin = 10,
    this.backgroundColor = Colors.black,
    this.fitMode = FitMode.fit,
    this.format = OutputFormat.png,
    this.isProcessing = false,
  });

  ImageMergerState copyWith({
    List<ImageModel>? images,
    int? columnCount,
    int? margin,
    Color? backgroundColor,
    FitMode? fitMode,
    OutputFormat? format,
    bool? isProcessing,
  }) {
    return ImageMergerState(
      images: images ?? this.images,
      columnCount: columnCount ?? this.columnCount,
      margin: margin ?? this.margin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fitMode: fitMode ?? this.fitMode,
      format: format ?? this.format,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class ImageMergerNotifier extends StateNotifier<ImageMergerState> {
  ImageMergerNotifier() : super(ImageMergerState());

  final _uuid = const Uuid();

  /// 画像ファイルをバイトデータから追加する
  Future<void> addImagesFromBytes(
    List<({String name, Uint8List bytes})> files,
  ) async {
    state = state.copyWith(isProcessing: true);

    final newImages = <ImageModel>[];
    for (final file in files) {
      try {
        // 画像をデコードしてメタデータ（解像度、アスペクト比）を取得
        final decoded = img.decodeImage(file.bytes);
        if (decoded == null) continue;

        final width = decoded.width;
        final height = decoded.height;
        final aspect = width / height;

        // プレビュー表示用にリサイズ
        final previewBytes = await ImageMergerService.resizeForPreview(
          file.bytes,
        );

        newImages.add(
          ImageModel(
            id: _uuid.v4(),
            name: file.name,
            originalBytes: file.bytes,
            previewBytes: previewBytes,
            aspectRatio: aspect,
            originalWidth: width,
            originalHeight: height,
          ),
        );
      } catch (e) {
        debugPrint('Error loading image ${file.name}: $e');
      }
    }

    state = state.copyWith(
      images: [...state.images, ...newImages],
      isProcessing: false,
    );
  }

  /// 指定インデックスの画像を削除する
  void removeImage(String id) {
    state = state.copyWith(
      images: state.images.where((img) => img.id != id).toList(),
    );
  }

  /// すべての画像をクリアする
  void clearAll() {
    state = state.copyWith(images: []);
  }

  /// 画像リストの順序を入れ替える
  void reorderImages(int oldIndex, int newIndex) {
    final list = List<ImageModel>.from(state.images);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(images: list);
  }

  /// 列数の更新
  void updateColumnCount(int count) {
    if (count < 1) return;
    state = state.copyWith(columnCount: count);
  }

  /// 余白の更新
  void updateMargin(int margin) {
    state = state.copyWith(margin: margin);
  }

  /// 背景色の更新
  void updateBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color);
  }

  /// フィットモードの更新
  void updateFitMode(FitMode mode) {
    state = state.copyWith(fitMode: mode);
  }

  /// 出力形式の更新
  void updateFormat(OutputFormat format) {
    state = state.copyWith(format: format);
  }

  /// 結合画像の生成
  Future<Uint8List> generateMergedImage() async {
    state = state.copyWith(isProcessing: true);
    try {
      final params = ImageMergeParams(
        images: state.images,
        columnCount: state.columnCount,
        margin: state.margin,
        backgroundColor: state.backgroundColor,
        fitMode: state.fitMode,
        format: state.format,
      );
      final result = await ImageMergerService.mergeImages(params);
      state = state.copyWith(isProcessing: false);
      return result;
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      rethrow;
    }
  }
}

final imageMergerProvider =
    StateNotifierProvider<ImageMergerNotifier, ImageMergerState>((ref) {
      return ImageMergerNotifier();
    });
