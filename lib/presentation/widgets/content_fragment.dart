import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/vod_models.dart';
import '../../data/repositories/vod_repository.dart';
import '../../domain/entities/app_tab.dart';
import '../viewmodels/home_view_model.dart';
import 'home_fragment.dart';
import 'video_grid.dart';
import 'filter_bar.dart';
import 'webview_fragment.dart';

// 视频源地址常量
const _videoSourceUrl = 'http://饭太硬.top/tv';

// 内容区路由组件：根据当前标签切换到对应的内容视图（首页/视频站点/分类列表页）
class ContentFragment extends StatelessWidget {
  final AppTab currentTab;
  final HomeViewModel? viewModel;
  final VodRepository? repository;
  // 分页回调
  final VoidCallback? onNextPage;
  final VoidCallback? onPrevPage;
  final Function(int page)? onGoToPage;
  // 点击视频项回调
  final void Function(VodItem)? onVideoTap;
  // 点击"查看更多"回调
  final void Function(AppTab)? onViewMore;
  // 筛选条件变更回调
  final void Function(String key, String value)? onFilterSelected;

  const ContentFragment({
    super.key,
    required this.currentTab,
    this.viewModel,
    this.repository,
    this.onNextPage,
    this.onPrevPage,
    this.onGoToPage,
    this.onVideoTap,
    this.onViewMore,
    this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 视频站点标签 → 显示 WebView
    if (currentTab == AppTab.videoSite) {
      return const WebViewFragment(url: _videoSourceUrl);
    }

    // 首页标签 → 显示 HomeFragment
    if (currentTab == AppTab.home && viewModel != null) {
      return HomeFragment(
        viewModel: viewModel!,
        onVideoTap: onVideoTap,
        onViewMore: onViewMore,
      );
    }

    // 其他分类标签（电影/电视剧/动漫/综艺）→ 显示筛选栏 + 视频网格列表
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Text(
            currentTab.fragmentLabel,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // 分类筛选栏（如地区、年份、类型等）
        if (repository != null)
          FilterBar(
            repository: repository!,
            tab: currentTab,
            onFilterSelected: (key, value) =>
                onFilterSelected?.call(key, value),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: repository != null
              ? VideoGrid(
                  repository: repository!,
                  onNextPage: onNextPage,
                  onPrevPage: onPrevPage,
                  onGoToPage: onGoToPage,
                  onVideoTap: onVideoTap,
                )
              : const Center(
                  child: Text('暂无数据',
                    style: TextStyle(color: AppColors.tertiaryText, fontSize: 16)),
                ),
        ),
      ],
    );
  }
}
