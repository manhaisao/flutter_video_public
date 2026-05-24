import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/constants/app_colors.dart';

// 视频播放器组件：基于 media_kit，支持播放、缓冲中、播放失败三种状态显示
class VideoPlayerWidget extends StatefulWidget {
  final Player player;
  // 可选的初始播放地址
  final String? initialUrl;

  const VideoPlayerWidget({super.key, required this.player, this.initialUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoController _videoController;
  // 是否正在缓冲
  bool _isBuffering = true;
  // 是否播放出错
  bool _hasError = false;
  // 监听缓冲状态变化的订阅
  StreamSubscription<bool>? _bufferingSub;

  @override
  void initState() {
    super.initState();
    _videoController = VideoController(widget.player);
    // 订阅播放器的缓冲状态流
    _bufferingSub = widget.player.stream.buffering.listen((b) {
      if (mounted) setState(() => _isBuffering = b);
    });
    if (widget.initialUrl != null) {
      playUrl(widget.initialUrl!);
    }
  }

  // 播放指定 URL 的视频，自动处理加载和错误状态
  Future<void> playUrl(String url) async {
    if (!mounted) return;
    setState(() { _hasError = false; _isBuffering = true; });
    try {
      await widget.player.open(Media(url));
      await widget.player.play();
    } catch (_) {
      if (mounted) setState(() { _hasError = true; _isBuffering = false; });
    }
  }

  @override
  void dispose() {
    _bufferingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频渲染层
          Video(controller: _videoController,
              fit: BoxFit.contain,
              width: double.infinity, height: double.infinity),
          // 缓冲中遮罩
          if (_isBuffering)
            const Center(
              child: SizedBox(width: 48, height: 48,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: AppColors.orangeAccent)),
            ),
          // 播放失败提示
          if (_hasError)
            const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, color: AppColors.accentRed, size: 48),
                SizedBox(height: 8),
                Text('播放失败', style: TextStyle(color: Colors.white70)),
              ]),
            ),
        ],
      ),
    );
  }
}
