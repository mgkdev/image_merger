import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'widgets/drop_zone.dart';
import 'widgets/image_grid.dart';
import 'widgets/control_panel.dart';

void main() {
  runApp(const ImageMergerApp());
}

class ImageMergerApp extends StatelessWidget {
  const ImageMergerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Image Grid Merger',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const ImageMergerHomePage(),
      ),
    );
  }
}

class ImageMergerHomePage extends StatelessWidget {
  const ImageMergerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 画面サイズに基づきレスポンシブなUIを判定する
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Stack(
        children: [
          // 1. 深みのある美しい背景グラデーション
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0C20),
                    Color(0xFF15102A),
                    Color(0xFF0A0716),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // ネオンの光が背後に差し込むようなエフェクト
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withAlpha(30),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryAccent.withAlpha(30),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // 2. メインコンテンツ
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // アプリケーションバー風のタイトルエリア
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentColor.withAlpha(100)),
                        ),
                        child: const Icon(Icons.grid_on, color: AppTheme.secondaryAccent),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image Grid Merger',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '直感的で高品質な画像結合ツール',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // コンテンツ本体のレイアウト
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: isWideScreen 
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 左カラム：操作エリアとグリッドプレビュー
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    const DropZone(),
                                    const SizedBox(height: 24),
                                    const ImageGrid(),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // 右カラム：設定パネル（スクロール追従・固定長）
                              const SizedBox(
                                width: 360,
                                child: ControlPanel(),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              DropZone(),
                              SizedBox(height: 20),
                              ControlPanel(),
                              SizedBox(height: 24),
                              ImageGrid(),
                              SizedBox(height: 40),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
