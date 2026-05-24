import 'package:flutter/material.dart';

// 应用导航标签枚举 —— 侧边栏的六个主要页面入口
enum AppTab {
  home,       // 首页推荐
  tvSeries,   // 电视剧
  movie,      // 电影
  anime,      // 动漫
  variety,    // 综艺
  videoSite,  // 在线视频源（WebView）
}

// AppTab扩展 —— 为每个标签提供中文标题、Material图标和页面标签
extension AppTabExtension on AppTab {
  // 中文显示名
  String get title {
    switch (this) {
      case AppTab.home:
        return '首页';
      case AppTab.tvSeries:
        return '电视剧';
      case AppTab.movie:
        return '电影';
      case AppTab.anime:
        return '动漫';
      case AppTab.variety:
        return '综艺';
      case AppTab.videoSite:
        return '视频源';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.home:
        return Icons.home;
      case AppTab.tvSeries:
        return Icons.live_tv;
      case AppTab.movie:
        return Icons.movie;
      case AppTab.anime:
        return Icons.animation;
      case AppTab.variety:
        return Icons.star;
      case AppTab.videoSite:
        return Icons.videocam;
    }
  }

  String get fragmentLabel {
    switch (this) {
      case AppTab.home:
        return '推荐首页内容';
      case AppTab.tvSeries:
        return '电视剧列表';
      case AppTab.movie:
        return '电影精选';
      case AppTab.anime:
        return '动漫专区';
      case AppTab.variety:
        return '综艺热播';
      case AppTab.videoSite:
        return '在线视频源';
    }
  }
}
