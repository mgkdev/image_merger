// ignore_for_file: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart' show Color;
import '../models/image_model.dart';

enum FitMode {
  fit, // アスペクト比維持・余白あり
  cover, // アスペクト比維持・切り抜き
}

enum OutputFormat { png, jpeg }

class ImageMergeParams {
  final List<ImageModel> images;
  final int columnCount;
  final int margin;
  final Color backgroundColor;
  final FitMode fitMode;
  final OutputFormat format;

  ImageMergeParams({
    required this.images,
    required this.columnCount,
    required this.margin,
    required this.backgroundColor,
    required this.fitMode,
    required this.format,
  });
}

class ImageMergerService {
  /// 画像を結合するメイン処理。WebとネイティブでIsolateの有無を切り分ける。
  static Future<Uint8List> mergeImages(ImageMergeParams params) async {
    if (kIsWeb) {
      // Web環境ではIsolateが使用できないため、直接実行する
      return _executeMerge(params);
    } else {
      // ネイティブ環境ではcomputeを使用してバックグラウンド処理する
      return compute(_executeMerge, params);
    }
  }

  /// プレビュー用の縮小画像を生成する
  static Future<Uint8List> resizeForPreview(
    Uint8List originalBytes, {
    int maxDimension = 300,
  }) async {
    if (kIsWeb) {
      return _executeResize(originalBytes, maxDimension);
    } else {
      return compute(
        (args) => _executeResize(args[0] as Uint8List, args[1] as int),
        [originalBytes, maxDimension],
      );
    }
  }

  static Uint8List _executeResize(Uint8List originalBytes, int maxDimension) {
    final image = img.decodeImage(originalBytes);
    if (image == null) return originalBytes;

    int newWidth = image.width;
    int newHeight = image.height;

    if (image.width > maxDimension || image.height > maxDimension) {
      if (image.width > image.height) {
        newWidth = maxDimension;
        newHeight = (image.height * (maxDimension / image.width)).round();
      } else {
        newHeight = maxDimension;
        newWidth = (image.width * (maxDimension / image.height)).round();
      }
    }

    final resized = img.copyResize(image, width: newWidth, height: newHeight);
    return Uint8List.fromList(img.encodePng(resized));
  }

  /// 実際の結合処理ロジック
  static Uint8List _executeMerge(ImageMergeParams params) {
    if (params.images.isEmpty) {
      return Uint8List(0);
    }

    // 各画像のデコードを試みる
    final decodedImages = <img.Image>[];
    for (final imgModel in params.images) {
      final decoded = img.decodeImage(imgModel.originalBytes);
      if (decoded != null) {
        decodedImages.add(decoded);
      }
    }

    if (decodedImages.isEmpty) {
      return Uint8List(0);
    }

    // セルの基本サイズ（画像の最大幅・最大高さ）を決定する
    int maxCellWidth = 0;
    int maxCellHeight = 0;
    for (final image in decodedImages) {
      if (image.width > maxCellWidth) maxCellWidth = image.width;
      if (image.height > maxCellHeight) maxCellHeight = image.height;
    }

    // 行数・列数の算出
    final int columnCount = params.columnCount;
    final int rowCount = (decodedImages.length / columnCount).ceil();
    final int margin = params.margin;

    // キャンバスの総サイズ計算
    final int totalWidth =
        columnCount * maxCellWidth + (columnCount + 1) * margin;
    final int totalHeight = rowCount * maxCellHeight + (rowCount + 1) * margin;

    // キャンバス作成と背景色の塗りつぶし
    final canvas = img.Image(
      width: totalWidth,
      height: totalHeight,
      numChannels: 4,
    );
    final bgColor = img.ColorRgba8(
      params.backgroundColor.red,
      params.backgroundColor.green,
      params.backgroundColor.blue,
      params.backgroundColor.alpha,
    );
    canvas.clear(bgColor);

    for (int i = 0; i < decodedImages.length; i++) {
      final srcImage = decodedImages[i];
      final row = i ~/ columnCount;
      final col = i % columnCount;

      // 各セルの左上座標
      final int cellLeft = col * (maxCellWidth + margin) + margin;
      final int cellTop = row * (maxCellHeight + margin) + margin;

      img.Image processedCellImage;

      if (params.fitMode == FitMode.fit) {
        // Fit: アスペクト比を維持してセルに収め、中央配置する
        final double srcAspect = srcImage.width / srcImage.height;
        final double cellAspect = maxCellWidth / maxCellHeight;

        int targetWidth, targetHeight;
        if (srcAspect > cellAspect) {
          targetWidth = maxCellWidth;
          targetHeight = (maxCellWidth / srcAspect).round();
        } else {
          targetHeight = maxCellHeight;
          targetWidth = (maxCellHeight * srcAspect).round();
        }

        final resized = img.copyResize(
          srcImage,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.average,
        );

        // セルの内部に余白を考慮して中央に配置するための黒・または透明な土台画像を作る
        // ただし、直接キャンバスに配置するので、土台を作らずオフセットを計算してマージする
        final offsetX = ((maxCellWidth - targetWidth) / 2).round();
        final offsetY = ((maxCellHeight - targetHeight) / 2).round();

        img.compositeImage(
          canvas,
          resized,
          dstX: cellLeft + offsetX,
          dstY: cellTop + offsetY,
        );
      } else {
        // Cover: アスペクト比を維持してセル全体を覆い、はみ出した部分を切り抜く
        final double srcAspect = srcImage.width / srcImage.height;
        final double cellAspect = maxCellWidth / maxCellHeight;

        int targetWidth, targetHeight;
        if (srcAspect > cellAspect) {
          // 高さをセルに合わせる
          targetHeight = maxCellHeight;
          targetWidth = (maxCellHeight * srcAspect).round();
        } else {
          // 幅をセルに合わせる
          targetWidth = maxCellWidth;
          targetHeight = (maxCellWidth / srcAspect).round();
        }

        final resized = img.copyResize(
          srcImage,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.average,
        );

        // 中央切り抜きの開始位置
        final cropX = ((targetWidth - maxCellWidth) / 2).round();
        final cropY = ((targetHeight - maxCellHeight) / 2).round();

        processedCellImage = img.copyCrop(
          resized,
          x: cropX,
          y: cropY,
          width: maxCellWidth,
          height: maxCellHeight,
        );

        img.compositeImage(
          canvas,
          processedCellImage,
          dstX: cellLeft,
          dstY: cellTop,
        );
      }
    }

    // エンコードして返す
    if (params.format == OutputFormat.png) {
      return Uint8List.fromList(img.encodePng(canvas));
    } else {
      return Uint8List.fromList(img.encodeJpg(canvas, quality: 90));
    }
  }
}
