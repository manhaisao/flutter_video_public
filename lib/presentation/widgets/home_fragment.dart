import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/vod_models.dart';
import '../../domain/entities/app_tab.dart';
import '../viewmodels/home_view_model.dart';
import 'video_card.dart';

// 首页内容区：包含 Hero 横幅大图和按分类展示的视频横向列表
class HomeFragment extends StatelessWidget {
  final HomeViewModel viewModel;
  // 点击视频项的回调
  final void Function(VodItem)? onVideoTap;
  // 点击"查看更多"的回调，传递对应分类标签
  final void Function(AppTab)? onViewMore;

  const HomeFragment({
    super.key,
    required this.viewModel,
    this.onVideoTap,
    this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    // 优先显示加载状态
    return ValueListenableBuilder<bool>(
      valueListenable: viewModel.isHomeLoading,
      builder: (context, loading, _) {
        if (loading) {
          return const Center(
            child: SizedBox(width: 40, height: 40,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.orangeAccent)),
          );
        }
        return _buildContent();
      },
    );
  }

  // 构建首页主体内容：嵌套监听四个分类列表，任一有数据即显示
  Widget _buildContent() {
    return ValueListenableBuilder<List<VodItem>>(
      valueListenable: viewModel.homeMovies,
      builder: (context, movies, _) {
        return ValueListenableBuilder<List<VodItem>>(
          valueListenable: viewModel.homeTvSeries,
          builder: (context, tvSeries, _) {
            return ValueListenableBuilder<List<VodItem>>(
              valueListenable: viewModel.homeVariety,
              builder: (context, variety, _) {
                return ValueListenableBuilder<List<VodItem>>(
                  valueListenable: viewModel.homeAnime,
                  builder: (context, anime, _) {
                    // 全部为空时显示占位提示
                    if (movies.isEmpty && tvSeries.isEmpty && variety.isEmpty && anime.isEmpty) {
                      return const Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.live_tv, color: AppColors.hintText, size: 48),
                          SizedBox(height: 12),
                          Text('暂无推荐内容', style: TextStyle(color: AppColors.tertiaryText)),
                        ]),
                      );
                    }
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // 取第一部电影作为 Hero 大图展示
                        if (movies.isNotEmpty)
                          _buildHeroBanner(movies.first),
                        // 各分类横向列表
                        if (movies.isNotEmpty)
                          _buildSectionRow('电影', movies, AppTab.movie),
                        if (tvSeries.isNotEmpty)
                          _buildSectionRow('电视剧', tvSeries, AppTab.tvSeries),
                        if (variety.isNotEmpty)
                          _buildSectionRow('综艺', variety, AppTab.variety),
                        if (anime.isNotEmpty)
                          _buildSectionRow('动漫', anime, AppTab.anime),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Hero 横幅大图：展示封面、渐变遮罩、影片标题和播放按钮
  Widget _buildHeroBanner(VodItem item) {
    return GestureDetector(
      onTap: () => onVideoTap?.call(item),
      child: Container(
        height: 320,
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardBackground,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 封面图片，加载失败时显示占位图
            if (item.vodPic.isNotEmpty)
              Image.network(item.vodPic, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _heroPlaceholder()),
            if (item.vodPic.isEmpty) _heroPlaceholder(),
            // 底部暗色渐变遮罩，保证文本可读性
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent, Colors.transparent],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // 左下角影片信息和播放按钮
            Positioned(bottom: 24, left: 24, right: 24,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.vodName, style: const TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${item.vodYear} · ${item.typeName} · ${item.vodRemarks}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => onVideoTap?.call(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.orangeAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text('立即播放', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // Hero 无封面时的占位图
  Widget _heroPlaceholder() {
    return Container(color: AppColors.cardBackground,
        child: const Center(child: Icon(Icons.movie, color: AppColors.hintText, size: 64)));
  }

  // 分类分区行：标题 + "查看更多" + 横向滚动视频卡片列表
  Widget _buildSectionRow(String title, List<VodItem> items, AppTab tab) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Row(children: [
          // 橙色竖条装饰
          Container(width: 3, height: 16,
              decoration: BoxDecoration(color: AppColors.orangeAccent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
              color: AppColors.primaryText, fontSize: 17, fontWeight: FontWeight.w600)),
          const Spacer(),
          // "查看更多"入口，点击跳转到对应分类全屏页
          GestureDetector(
            onTap: () => onViewMore?.call(tab),
            child: const Row(children: [
              Text('查看更多', style: TextStyle(color: AppColors.tertiaryText, fontSize: 12)),
              SizedBox(width: 2),
              Icon(Icons.chevron_right, color: AppColors.tertiaryText, size: 16),
            ]),
          ),
        ]),
      ),
      SizedBox(
        height: 220,
        // 横向滚动的卡片列表
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return SizedBox(
              width: 130,
              child: VideoCard(item: item, onTap: () => onVideoTap?.call(item)),
            );
          },
        ),
      ),
    ]);
  }
}
