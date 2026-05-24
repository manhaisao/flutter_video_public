import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'core/constants/app_colors.dart';
import 'presentation/pages/home_page.dart';

// 应用入口 —— 初始化media_kit视频引擎，创建无边框桌面窗口
void main() {
  MediaKit.ensureInitialized(); // 必须最先调用，初始化视频播放
  runApp(const MyApp());

  // 窗口就绪后配置无边框窗口属性
  doWhenWindowReady(() {
    const initialSize = Size(1920, 1080);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = '雯雯影视';
    appWindow.show();
  });
}

// 根Widget，配置暗色主题和首页
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '雯雯影视',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundColor,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}
