import 'dart:async';
import '../../domain/entities/app_tab.dart';
import '../models/vod_models.dart';
import '../services/vod_api_service.dart';

// 仓库数据加载状态枚举
enum VodLoadState { idle, loading, loaded, error }

// 每个Tab的缓存数据快照，存储完整列表、过滤后列表和分页状态
class _TabPageData {
  final List<VodItem> fullItems; // 未过滤的完整数据（用于筛选选项生成）
  final List<VodItem> filteredItems; // 当前筛选后的数据（用于展示）
  final int currentPage; // 当前页码
  final int totalPages; // 总页数
  final Map<String, String> activeFilters; // 当前生效的筛选条件

  const _TabPageData({
    required this.fullItems,
    required this.filteredItems,
    required this.currentPage,
    required this.totalPages,
    required this.activeFilters,
  });
}

// 视频数据仓库，负责缓存管理、分页逻辑、客户端筛选和数据聚合
// 使用Stream广播模式通知ViewModel数据变更
class VodRepository {
  final VodApiService _apiService;

  List<VodItem> _list = []; // 当前展示的视频列表
  List<int> _activeTypeIds = []; // 当前激活的分类ID集合（可同时查询多个分类）
  int _currentPage = 1; // 当前页码
  int _totalPages = 1; // 总页数
  VodLoadState _listState = VodLoadState.idle; // 加载状态
  String? _errorMessage; // 错误信息

  // Tab级别缓存：切换Tab时优先命中缓存，避免重复请求
  final Map<AppTab, _TabPageData> _tabCache = {};
  AppTab _currentTab = AppTab.home;

  late final StreamController<VodRepository> _controller;

  VodRepository({required String apiBaseUrl})
      : _apiService = VodApiService(baseUrl: apiBaseUrl) {
    _controller = StreamController<VodRepository>.broadcast();
  }

  // 数据变更广播流，ViewModel订阅此流来刷新UI
  Stream<VodRepository> get stream => _controller.stream;
  List<int> get activeTypeIds => _activeTypeIds;
  VodLoadState get listState => _listState;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _currentPage < _totalPages; // 是否还有下一页
  bool get hasPrev => _currentPage > 1; // 是否还有上一页
  List<VodItem> get currentList => _list;

  // 通知所有监听者数据已变更
  void _notify() {
    if (!_controller.isClosed) _controller.add(this);
  }

  // ===== 从已加载数据构建客户端筛选选项 =====

  // 获取指定Tab的筛选维度（分类、地区、年份）
  Map<String, List<VodFilter>> getFilters(AppTab tab) {
    final cache = _tabCache[tab];
    if (cache == null || cache.fullItems.isEmpty) return {};
    return _buildFiltersFromItems(cache.fullItems);
  }

  // 获取指定Tab当前激活的筛选条件
  Map<String, String> getActiveFilters(AppTab tab) =>
      _tabCache[tab]?.activeFilters ?? {};

  // 主要国家/地区白名单，用于地区归一化和过滤
  static const _majorCountries = {
    '中国', '美国', '英国', '韩国', '日本', '法国', '德国',
    '印度', '泰国', '加拿大', '俄罗斯', '澳大利亚', '意大利',
    '西班牙', '墨西哥', '巴西',
  };

  // 地区名称归一化：将中国大陆/港澳台统一为"中国"，简称还原为全称
  String _normalizeArea(String raw) {
    // 港澳台统一归入中国
    if (raw.contains('中国') || raw.contains('香港') ||
        raw.contains('台湾') || raw.contains('澳门') ||
        raw == '大陆' || raw == '内地') {
      return '中国';
    }
    if (raw.contains('韩国') || raw.contains('南韩') || raw == '韩') return '韩国';
    if (raw.contains('日本') || raw == '日') return '日本';
    if (raw.contains('美国') || raw == '美') return '美国';
    if (raw.contains('英国') || raw == '英') return '英国';
    if (raw.contains('法国') || raw == '法') return '法国';
    if (raw.contains('德国') || raw == '德') return '德国';
    if (raw.contains('印度') || raw == '印') return '印度';
    if (raw.contains('泰国') || raw == '泰') return '泰国';
    if (raw.contains('加拿大') || raw.contains('加拿大')) return '加拿大';
    if (raw.contains('俄罗斯') || raw.contains('俄国') || raw == '俄') return '俄罗斯';
    if (raw.contains('澳大利亚') || raw.contains('澳洲')) return '澳大利亚';
    if (raw.contains('意大利') || raw == '意') return '意大利';
    if (raw.contains('西班牙') || raw == '西') return '西班牙';
    if (raw.contains('墨西哥') || raw == '墨') return '墨西哥';
    if (raw.contains('巴西') || raw == '巴') return '巴西';
    // 非主要国家丢弃，避免筛选项过多
    return '';
  }

  // 需要隐藏的筛选键（暂不需要地区筛选UI时启用）
  static const _hiddenFilterKeys = {'area'};

  // 从视频列表中提取年份、地区（归一化）、分类名，构建筛选维度
  Map<String, List<VodFilter>> _buildFiltersFromItems(List<VodItem> items) {
    final years = <String>{};
    final areas = <String>{};
    final typeNames = <String>{};

    for (final item in items) {
      if (item.vodYear.isNotEmpty) {
        years.add(item.vodYear);
      }
      if (item.vodArea.isNotEmpty) {
        final normalized = _normalizeArea(item.vodArea);
        if (normalized.isNotEmpty) areas.add(normalized);
      }
      if (item.typeName.isNotEmpty) {
        typeNames.add(item.typeName);
      }
    }

    final filterList = <VodFilter>[];

    // 分类筛选
    if (typeNames.isNotEmpty) {
      filterList.add(VodFilter(
        key: 'class',
        name: '分类',
        values: typeNames.map((t) => VodFilterValue(n: t, v: t)).toList(),
      ));
    }

    // 地区筛选（字母排序）
    if (areas.isNotEmpty) {
      final sortedAreas = areas.toList()..sort();
      filterList.add(VodFilter(
        key: 'area',
        name: '地区',
        values: sortedAreas.map((a) => VodFilterValue(n: a, v: a)).toList(),
      ));
    }

    // 年份筛选（按年份降序）
    if (years.isNotEmpty) {
      final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
      filterList.add(VodFilter(
        key: 'year',
        name: '年份',
        values: sortedYears.map((y) => VodFilterValue(n: y, v: y)).toList(),
      ));
    }

    if (filterList.isEmpty) return {};
    // key "1" 对应默认分类ID，过滤掉隐藏键
    return {'1': filterList.where((f) => !_hiddenFilterKeys.contains(f.key)).toList()};
  }

  // ===== 客户端筛选逻辑 =====

  // 在客户端对列表按筛选条件过滤（支持year/area/class三个维度）
  List<VodItem> _applyClientFilters(List<VodItem> items, Map<String, String> filters) {
    if (filters.isEmpty) return items;
    var filtered = items;
    for (final entry in filters.entries) {
      if (entry.value.isEmpty) continue;
      switch (entry.key) {
        case 'year':
          filtered = filtered.where((i) => i.vodYear == entry.value).toList();
          break;
        case 'area':
          // 地区筛选时先归一化再比较
          filtered = filtered.where((i) => _normalizeArea(i.vodArea) == entry.value).toList();
          break;
        case 'class':
          filtered = filtered.where((i) => i.typeName == entry.value).toList();
          break;
      }
    }
    return filtered;
  }

  // 仅对当前缓存重新应用筛选条件，不发API请求（用于UI即时响应）
  void applyFiltersToView() {
    final cache = _tabCache[_currentTab];
    if (cache == null) return;
    _list = _applyClientFilters(cache.fullItems, cache.activeFilters);
    _listState = VodLoadState.loaded;
    _notify();
  }

  // 应用筛选条件并更新缓存：先显示加载状态，再替换列表
  Future<void> applyFilter({
    required AppTab tab,
    required List<int> typeIds,
    required String key,
    required String value,
  }) async {
    final cache = _tabCache[tab];
    if (cache == null) return;

    // 构建新的筛选条件Map（value为空时移除该筛选维度）
    final newFilters = Map<String, String>.from(cache.activeFilters);
    if (value.isEmpty) {
      newFilters.remove(key);
    } else {
      newFilters[key] = value;
    }

    final filtered = _applyClientFilters(cache.fullItems, newFilters);

    _listState = VodLoadState.loading;
    _notify();

    // 短暂延迟让loading状态在UI上先渲染，避免闪烁
    await Future.delayed(const Duration(milliseconds: 100));

    _currentTab = tab;
    _activeTypeIds = List.of(typeIds);
    _currentPage = cache.currentPage;
    _totalPages = cache.totalPages;
    _list = filtered;
    _listState = VodLoadState.loaded;

    // 更新缓存中的筛选结果
    _tabCache[tab] = _TabPageData(
      fullItems: cache.fullItems,
      filteredItems: filtered,
      currentPage: cache.currentPage,
      totalPages: cache.totalPages,
      activeFilters: newFilters,
    );
    _notify();
  }

  // ===== 分页列表加载（带Tab缓存） =====

  // 加载指定Tab的视频列表，支持多分类ID聚合和分页
  // 缓存命中（相同Tab第1页且无扩展参数）直接返回，否则请求API
  Future<void> loadList({
    required List<int> typeIds,
    required AppTab tab,
    int page = 1,
    Map<String, String>? extend,
  }) async {
    final effectiveFilters = extend ?? _tabCache[tab]?.activeFilters ?? {};

    // 缓存命中：已加载过的Tab第1页无筛选请求，直接恢复缓存数据
    if (page == 1 && extend == null) {
      final cached = _tabCache[tab];
      if (cached != null) {
        _currentTab = tab;
        _activeTypeIds = List.of(typeIds);
        _currentPage = cached.currentPage;
        _totalPages = cached.totalPages;
        // 无筛选条件时展示完整列表，否则展示过滤后列表
        _list = cached.activeFilters.isEmpty
            ? List.of(cached.fullItems)
            : List.of(cached.filteredItems);
        _listState = VodLoadState.loaded;
        _notify();
        return; // 缓存命中，直接返回，不发网络请求
      }
    }

    // 缓存未命中——请求API
    _currentTab = tab;
    _activeTypeIds = List.of(typeIds);
    _currentPage = page;
    _list = [];
    _listState = VodLoadState.loading;
    _notify();

    try {
      // 并发请求所有分类ID，然后合并结果
      final futures = _activeTypeIds.map((tid) => _apiService.fetchVodList(
            typeId: tid,
            page: page,
          ));
      final results = await Future.wait(futures);

      final merged = <VodItem>[];
      for (final r in results) {
        merged.addAll(r.list);
      }
      // 取所有分类中的最大页数作为总页数
      final maxPages = results.fold(1, (max, r) {
        final pc = r.pagecount;
        return pc > max ? pc : max;
      });

      final filtered = _applyClientFilters(merged, effectiveFilters);

      _totalPages = maxPages;
      _list = filtered;
      _listState = VodLoadState.loaded;

      // 缓存完整数据和筛选后数据
      _tabCache[tab] = _TabPageData(
        fullItems: List.of(merged),
        filteredItems: List.of(filtered),
        currentPage: page,
        totalPages: maxPages,
        activeFilters: Map.from(effectiveFilters),
      );
    } catch (e) {
      _listState = VodLoadState.error;
      _errorMessage = e.toString();
      // 失败时回退页码
      if (_currentPage > 1) _currentPage--;
    }
    _notify();
  }

  // ===== 分页导航 =====

  // 加载下一页：并发请求所有分类的下一页，追加合并到缓存
  Future<void> loadNextPage() async {
    if (!hasMore || _listState == VodLoadState.loading) return;
    _currentPage++;
    _listState = VodLoadState.loading;
    _notify();

    try {
      final futures = _activeTypeIds.map((tid) => _apiService.fetchVodList(
            typeId: tid,
            page: _currentPage,
          ));
      final results = await Future.wait(futures);

      final merged = <VodItem>[];
      for (final r in results) {
        merged.addAll(r.list);
      }
      final maxPages = results.fold(1, (max, r) {
        final pc = r.pagecount;
        return pc > max ? pc : max;
      });

      // 将新数据追加到已有的完整列表中
      final cache = _tabCache[_currentTab];
      final existingFull = cache?.fullItems ?? [];
      final allItems = [...existingFull, ...merged];
      final activeFilters = cache?.activeFilters ?? {};
      final filtered = _applyClientFilters(allItems, activeFilters);

      _totalPages = maxPages;
      _list = filtered;
      _listState = VodLoadState.loaded;

      _tabCache[_currentTab] = _TabPageData(
        fullItems: allItems,
        filteredItems: filtered,
        currentPage: _currentPage,
        totalPages: maxPages,
        activeFilters: Map.from(activeFilters),
      );
    } catch (e) {
      _listState = VodLoadState.error;
      _errorMessage = e.toString();
      _currentPage--; // 失败时回退页码
    }
    _notify();
  }

  // 加载上一页：并发请求上一页数据，保留缓存中的fullItems用于筛选选项
  Future<void> loadPrevPage() async {
    if (!hasPrev || _listState == VodLoadState.loading) return;
    _currentPage--;
    _listState = VodLoadState.loading;
    _notify();

    try {
      final futures = _activeTypeIds.map((tid) => _apiService.fetchVodList(
            typeId: tid,
            page: _currentPage,
          ));
      final results = await Future.wait(futures);

      final merged = <VodItem>[];
      for (final r in results) {
        merged.addAll(r.list);
      }
      final maxPages = results.fold(1, (max, r) {
        final pc = r.pagecount;
        return pc > max ? pc : max;
      });

      // 返回上一页时优先保留缓存的fullItems以保证筛选选项完整性
      final cache = _tabCache[_currentTab];
      final activeFilters = cache?.activeFilters ?? {};
      final filtered = _applyClientFilters(merged, activeFilters);

      _totalPages = maxPages;
      _list = filtered;
      _listState = VodLoadState.loaded;

      // 保留已有fullItems，避免筛选选项丢失
      final existingFull = cache?.fullItems ?? [];
      _tabCache[_currentTab] = _TabPageData(
        fullItems: existingFull.isNotEmpty ? existingFull : merged,
        filteredItems: filtered,
        currentPage: _currentPage,
        totalPages: maxPages,
        activeFilters: Map.from(activeFilters),
      );
    } catch (e) {
      _listState = VodLoadState.error;
      _errorMessage = e.toString();
      _currentPage++; // 失败时回退页码
    }
    _notify();
  }

  // 释放资源：关闭API客户端和广播流
  void dispose() {
    _apiService.dispose();
    _controller.close();
  }
}
