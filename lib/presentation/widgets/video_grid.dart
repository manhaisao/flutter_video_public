import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/vod_models.dart';
import '../../data/repositories/vod_repository.dart';
import 'video_card.dart';

// 视频网格视图：响应式列数 + 加载/错误状态 + 底部分页栏
class VideoGrid extends StatefulWidget {
  final VodRepository repository;
  // 分页回调
  final VoidCallback? onNextPage;
  final VoidCallback? onPrevPage;
  final Function(int page)? onGoToPage;
  // 点击视频项回调
  final void Function(VodItem)? onVideoTap;

  const VideoGrid({
    super.key,
    required this.repository,
    this.onNextPage,
    this.onPrevPage,
    this.onGoToPage,
    this.onVideoTap,
  });

  @override
  State<VideoGrid> createState() => _VideoGridState();
}

class _VideoGridState extends State<VideoGrid> {
  // 监听 repository 数据变化以触发 UI 刷新
  StreamSubscription<VodRepository>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.repository.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(VideoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // repository 切换时重新订阅新 stream
    if (oldWidget.repository != widget.repository) {
      _sub?.cancel();
      _sub = widget.repository.stream.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.repository.listState;
    final list = widget.repository.currentList;
    final error = widget.repository.errorMessage;

    // 首次加载中状态
    if (state == VodLoadState.loading && list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(color: AppColors.orangeAccent, strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text('加载中...', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          ],
        ),
      );
    }

    // 加载失败（无缓存数据时）显示错误和重试按钮
    if (state == VodLoadState.error && list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.accentRed, size: 48),
            const SizedBox(height: 12),
            Text(error ?? '加载失败', style: const TextStyle(color: AppColors.tertiaryText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (widget.onGoToPage != null) {
                  widget.onGoToPage!(widget.repository.currentPage);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangeAccent),
              child: const Text('重试', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 根据可用宽度动态计算列数：每列至少200px，限制2~8列
              final crossAxisCount = (constraints.maxWidth / 200).floor().clamp(2, 8);
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.55,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return VideoCard(item: item, onTap: () => widget.onVideoTap?.call(item));
                },
              );
            },
          ),
        ),
        // 底部分页栏：翻页中显示加载动画，否则显示页码
        if (widget.repository.listState == VodLoadState.loading)
          const _PaginationBar(
            currentPage: -1, totalPages: -1, onPrev: null, onNext: null,
            loading: true,
          )
        else
          _PaginationBar(
            currentPage: widget.repository.currentPage,
            totalPages: widget.repository.totalPages,
            onPrev: widget.onPrevPage,
            onNext: widget.onNextPage,
          ),
      ],
    );
  }
}

// 分页栏组件：上一页按钮 + 页码显示 + 下一页按钮
class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool loading;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    this.onPrev,
    this.onNext,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(top: BorderSide(color: AppColors.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页按钮：首页时禁用
          _PageButton(
            icon: Icons.chevron_left,
            onTap: (currentPage > 1 && !loading) ? onPrev : null,
          ),
          const SizedBox(width: 16),
          // 加载中显示小转圈，否则显示"第 X / Y 页"
          if (loading)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orangeAccent),
            )
          else
            Text(
              '第 $currentPage / $totalPages 页',
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
          const SizedBox(width: 16),
          // 下一页按钮：末页时禁用
          _PageButton(
            icon: Icons.chevron_right,
            onTap: (currentPage < totalPages && !loading) ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// 翻页按钮：禁用时半透明显示
class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PageButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.cardBackground : AppColors.cardBackground.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 20,
            color: enabled ? AppColors.primaryText : AppColors.hintText),
        ),
      ),
    );
  }
}
