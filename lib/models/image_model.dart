import 'dart:typed_data';

class ImageModel {
  final String id;
  final String name;
  final Uint8List originalBytes;
  final Uint8List previewBytes;
  final double aspectRatio;
  final int originalWidth;
  final int originalHeight;

  ImageModel({
    required this.id,
    required this.name,
    required this.originalBytes,
    required this.previewBytes,
    required this.aspectRatio,
    required this.originalWidth,
    required this.originalHeight,
  });

  ImageModel copyWith({
    String? id,
    String? name,
    Uint8List? originalBytes,
    Uint8List? previewBytes,
    double? aspectRatio,
    int? originalWidth,
    int? originalHeight,
  }) {
    return ImageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      originalBytes: originalBytes ?? this.originalBytes,
      previewBytes: previewBytes ?? this.previewBytes,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
    );
  }
}
