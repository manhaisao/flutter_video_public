import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/vod_models.dart';
import '../../data/repositories/vod_repository.dart';
import '../../data/services/vod_api_service.dart';
import '../../domain/entities/app_tab.dart';

// 苹果CMS v10 API中各类别的type_id映射
// 电影分类ID列表（动作片、喜剧片、爱情片等）
const movieIds = [6, 7, 8, 9, 10, 11, 12, 39];
// 电视剧分类ID列表（国产剧、港剧、日韩剧、欧美剧等）
const tvSeriesIds = [13, 14, 15, 16, 17, 18, 19, 23];
// 动漫分类ID列表
const animeIds = [29, 30, 31];
// 综艺分类ID列表
const varietyIds = [25, 26, 27, 28];

// 首页ViewModel，管理Tab切换、首页分类数据和页面状态
// 使用ValueNotifier模式驱动UI更新，不依赖第三方状态管理库
class HomeViewModel {
  // 当前选中的Tab，UI通过ValueListenableBuilder监听变化
  final ValueNotifier<AppTab> selectedTab = ValueNotifier<AppTab>(AppTab.home);
  final VodRepository _repository;
  final String _apiBaseUrl;
  StreamSubscription<VodRepository>? _repoSub; // 仓库变更流订阅

  final ValueNotifier<bool> isInitializing = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isLoadingMore = ValueNotifier<bool>(false);

  // 首页各类别展示数据（各取前8条）
  final ValueNotifier<List<VodItem>> homeMovies = ValueNotifier([]);
  final ValueNotifier<List<VodItem>> homeTvSeries = ValueNotifier([]);
  final ValueNotifier<List<VodItem>> homeVariety = ValueNotifier([]);
  final ValueNotifier<List<VodItem>> homeAnime = ValueNotifier([]);
  final ValueNotifier<bool> isHomeLoading = ValueNotifier(true);

  HomeViewModel({required String apiBaseUrl})
      : _apiBaseUrl = apiBaseUrl,
        _repository = VodRepository(apiBaseUrl: apiBaseUrl) {
    // 监听仓库数据变更，同步更新VM状态
    _repoSub = _repository.stream.listen((_) => _onDataChanged());
  }

  VodRepository get repository => _repository;
  String get apiBaseUrl => _apiBaseUrl;

  // 仓库数据变更回调：根据加载状态更新isInitializing和isLoadingMore
  void _onDataChanged() {
    isInitializing.value = false;
    isLoadingMore.value = _repository.listState == VodLoadState.loading;
  }

  // 初始化：加载首页各类别前8条数据
  Future<void> initialize() async {
    await _loadHomeCategories();
  }

  // 并发请求首页四个类别的数据（电影、电视剧、综艺、动漫），各取前8条
  Future<void> _loadHomeCategories() async {
    isHomeLoading.value = true;
    try {
      final results = await Future.wait([
        _fetchCategory(movieIds[0], page: 1, limit: 8),
        _fetchCategory(tvSeriesIds[0], page: 1, limit: 8),
        _fetchCategory(varietyIds[0], page: 1, limit: 8),
        _fetchCategory(animeIds[0], page: 1, limit: 8),
      ]);
      homeMovies.value = results[0];
      homeTvSeries.value = results[1];
      homeVariety.value = results[2];
      homeAnime.value = results[3];
    } catch (_) {}
    isHomeLoading.value = false;
  }

  // 获取指定分类的视频列表，取前limit条（临时创建service实例，用后即焚）
  Future<List<VodItem>> _fetchCategory(int typeId, {int page = 1, int limit = 8}) async {
    try {
      final service = VodApiService(baseUrl: _apiBaseUrl);
      final response = await service.fetchVodList(typeId: typeId, page: page);
      return response.list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  // 切换Tab：更新选中状态，加载对应分类的视频列表（第1页）
  void selectTab(AppTab tab) {
    selectedTab.value = tab;
    final typeIds = _tabToTypeIds(tab);
    if (typeIds != null) {
      _repository.loadList(typeIds: typeIds, tab: tab, page: 1);
    }
  }

  // 应用筛选条件，委托给仓库层执行客户端过滤
  void applyFilter(String key, String value) {
    final tab = selectedTab.value;
    final typeIds = _tabToTypeIds(tab);
    if (typeIds != null) {
      _repository.applyFilter(tab: tab, typeIds: typeIds, key: key, value: value);
    }
  }

  // 获取当前Tab可用的筛选维度列表
  Map<String, List<VodFilter>>? getFiltersForCurrentTab() {
    return _repository.getFilters(selectedTab.value);
  }

  // 获取当前Tab已激活的筛选条件
  Map<String, String> getActiveFiltersForCurrentTab() {
    return _repository.getActiveFilters(selectedTab.value);
  }

  // 跳转到指定页码
  Future<void> goToPage(int page) async {
    final typeIds = _repository.activeTypeIds;
    if (typeIds.isNotEmpty) {
      await _repository.loadList(typeIds: typeIds, tab: selectedTab.value, page: page);
    }
  }

  // 加载下一页（委托仓库层）
  Future<void> loadNextPage() async {
    await _repository.loadNextPage();
  }

  // 加载上一页（委托仓库层）
  Future<void> loadPrevPage() async {
    await _repository.loadPrevPage();
  }

  // Tab到分类ID列表的映射：home和videoSite不关联分类（null），其余Tab映射到对应type ID数组
  List<int>? _tabToTypeIds(AppTab tab) {
    return switch (tab) {
      AppTab.home => null,
      AppTab.movie => movieIds,
      AppTab.tvSeries => tvSeriesIds,
      AppTab.anime => animeIds,
      AppTab.variety => varietyIds,
      AppTab.videoSite => null,
    };
  }

  // 释放所有资源：取消流订阅、关闭仓库、释放所有ValueNotifier
  void dispose() {
    _repoSub?.cancel();
    _repository.dispose();
    selectedTab.dispose();
    isInitializing.dispose();
    isLoadingMore.dispose();
    homeMovies.dispose();
    homeTvSeries.dispose();
    homeVariety.dispose();
    homeAnime.dispose();
    isHomeLoading.dispose();
  }
}
