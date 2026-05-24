import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// 带缓冲进度的播放进度条：三层轨道（底色/已缓冲/已播放） + 拖拽滑块 + 时间显示
class BufferedProgressBar extends StatelessWidget {
  final Duration progress;
  // 已缓冲到的位置
  final Duration buffered;
  final Duration total;
  // 拖拽或点击跳转到指定位置的回调
  final void Function(Duration)? onSeek;

  const BufferedProgressBar({
    super.key,
    required this.progress,
    required this.buffered,
    required this.total,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final totalMs = total.inMilliseconds.toDouble();
    // 已播放进度比例
    final progressFrac = totalMs > 0 ? (progress.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;
    // 已缓冲进度比例
    final bufferedFrac = totalMs > 0 ? (buffered.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 左侧当前播放时间
        Text(_formatDuration(progress),
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // 点击跳转
            onTapDown: (d) => _seek(d.localPosition.dx, context),
            // 拖拽跳转
            onHorizontalDragUpdate: (d) => _seek(d.localPosition.dx, context),
            child: Container(
              height: 20,
              alignment: Alignment.centerLeft,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // 底层轨道（灰色细条）
                      Container(height: 4, width: w,
                          decoration: BoxDecoration(color: Colors.white12,
                              borderRadius: BorderRadius.circular(2))),
                      // 已缓冲轨道（半透明白色）
                      Container(height: 4, width: w * bufferedFrac,
                          decoration: BoxDecoration(color: Colors.white24,
                              borderRadius: BorderRadius.circular(2))),
                      // 已播放轨道（橙色）
                      Container(height: 4, width: w * progressFrac,
                          decoration: BoxDecoration(color: AppColors.orangeAccent,
                              borderRadius: BorderRadius.circular(2))),
                      // 拖拽滑块（橙色圆点）
                      Positioned(
                        left: (w * progressFrac) - 6,
                        child: Container(width: 12, height: 12,
                            decoration: const BoxDecoration(
                                color: AppColors.orangeAccent, shape: BoxShape.circle)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 右侧总时长
        Text(_formatDuration(total),
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
      ],
    );
  }

  // 根据本地点击/拖拽位置计算目标时间并回调
  void _seek(double localX, BuildContext context) {
    if (onSeek == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width;
    final frac = (localX / w).clamp(0.0, 1.0);
    onSeek!(Duration(milliseconds: (total.inMilliseconds * frac).round()));
  }

  // 格式化时长为 mm:ss 或 hh:mm:ss
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
