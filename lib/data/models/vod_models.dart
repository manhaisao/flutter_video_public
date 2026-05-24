// 影视条目数据模型，对应API返回的视频/剧集信息
class VodItem {
  final int vodId; // 影片唯一ID
  final String vodName; // 影片名称
  final int typeId; // 所属分类ID
  final String typeName; // 分类名称（如动作片、喜剧等）
  final String vodPic; // 封面图片URL
  final String vodRemarks; // 备注信息（通常显示更新状态/集数）
  final String vodYear; // 上映年份
  final String vodArea; // 制片地区
  final String vodActor; // 演员列表
  final String vodDirector; // 导演
  final String vodContent; // 剧情简介
  final String vodPlayFrom; // 播放源标识（如youku、qq等）
  final String vodPlayUrl; // 播放地址（剧集URL列表）
  final String vodLang; // 语言
  final String vodTime; // 时长或更新时间

  VodItem({
    required this.vodId,
    required this.vodName,
    this.typeId = 0,
    this.typeName = '',
    this.vodPic = '',
    this.vodRemarks = '',
    this.vodYear = '',
    this.vodArea = '',
    this.vodActor = '',
    this.vodDirector = '',
    this.vodContent = '',
    this.vodPlayFrom = '',
    this.vodPlayUrl = '',
    this.vodLang = '',
    this.vodTime = '',
  });

  // 创建副本并选择性覆盖字段，用于不可变数据更新
  VodItem copyWith({
    int? vodId,
    String? vodName,
    int? typeId,
    String? typeName,
    String? vodPic,
    String? vodRemarks,
    String? vodYear,
    String? vodArea,
    String? vodActor,
    String? vodDirector,
    String? vodContent,
    String? vodPlayFrom,
    String? vodPlayUrl,
    String? vodLang,
    String? vodTime,
  }) {
    return VodItem(
      vodId: vodId ?? this.vodId,
      vodName: vodName ?? this.vodName,
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      vodPic: vodPic ?? this.vodPic,
      vodRemarks: vodRemarks ?? this.vodRemarks,
      vodYear: vodYear ?? this.vodYear,
      vodArea: vodArea ?? this.vodArea,
      vodActor: vodActor ?? this.vodActor,
      vodDirector: vodDirector ?? this.vodDirector,
      vodContent: vodContent ?? this.vodContent,
      vodPlayFrom: vodPlayFrom ?? this.vodPlayFrom,
      vodPlayUrl: vodPlayUrl ?? this.vodPlayUrl,
      vodLang: vodLang ?? this.vodLang,
      vodTime: vodTime ?? this.vodTime,
    );
  }

  // 从API JSON反序列化，字段名使用snake_case映射
  factory VodItem.fromJson(Map<String, dynamic> json) {
    return VodItem(
      vodId: int.tryParse(json['vod_id']?.toString() ?? '0') ?? 0,
      vodName: json['vod_name']?.toString() ?? '',
      typeId: int.tryParse(json['type_id']?.toString() ?? '0') ?? 0,
      typeName: json['type_name']?.toString() ?? '',
      vodPic: json['vod_pic']?.toString() ?? '',
      vodRemarks: json['vod_remarks']?.toString() ?? '',
      vodYear: json['vod_year']?.toString() ?? '',
      vodArea: json['vod_area']?.toString() ?? '',
      vodActor: json['vod_actor']?.toString() ?? '',
      vodDirector: json['vod_director']?.toString() ?? '',
      vodContent: json['vod_content']?.toString() ?? '',
      vodPlayFrom: json['vod_play_from']?.toString() ?? '',
      vodPlayUrl: json['vod_play_url']?.toString() ?? '',
      vodLang: json['vod_lang']?.toString() ?? '',
      vodTime: json['vod_time']?.toString() ?? '',
    );
  }
}

// 影视分类，包含分类ID和名称
class VodClass {
  final int typeId; // 分类ID
  final String typeName; // 分类名称

  VodClass({required this.typeId, required this.typeName});

  factory VodClass.fromJson(Map<String, dynamic> json) {
    return VodClass(
      typeId: int.tryParse(json['type_id']?.toString() ?? '0') ?? 0,
      typeName: json['type_name']?.toString() ?? '',
    );
  }
}

// 筛选维度（如地区、年份、分类），包含键名、显示名和可选值列表
class VodFilter {
  final String key; // 筛选键（如year、area、class）
  final String name; // 筛选显示名（如"年份"、"地区"）
  final List<VodFilterValue> values; // 该维度下的可选值列表

  VodFilter({required this.key, required this.name, required this.values});

  factory VodFilter.fromJson(Map<String, dynamic> json) {
    return VodFilter(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      values: (json['value'] as List<dynamic>?)
              ?.map((e) => VodFilterValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// 筛选值选项：n为显示文本，v为实际值
class VodFilterValue {
  final String n; // 显示名称
  final String v; // 实际值（用于API请求或过滤）

  VodFilterValue({required this.n, required this.v});

  factory VodFilterValue.fromJson(Map<String, dynamic> json) {
    return VodFilterValue(
      n: json['n']?.toString() ?? '',
      v: json['v']?.toString() ?? '',
    );
  }
}

// API列表接口响应体，包含分页信息、视频列表、分类和筛选条件
class VodListResponse {
  final int code; // 响应状态码（1表示成功）
  final String msg; // 响应消息
  final int page; // 当前页码
  final int pagecount; // 总页数
  final int total; // 总记录数
  final List<VodItem> list; // 当前页视频列表
  final List<VodClass> classes; // 分类列表
  final Map<String, List<VodFilter>> filters; // 筛选条件，key为分类ID

  VodListResponse({
    required this.code,
    this.msg = '',
    this.page = 1,
    this.pagecount = 1,
    this.total = 0,
    this.list = const [],
    this.classes = const [],
    this.filters = const {},
  });

  factory VodListResponse.fromJson(Map<String, dynamic> json) {
    final listData = json['list'] as List<dynamic>?;
    final classData = json['class'] as List<dynamic>?;
    final filtersData = json['filters'] as Map<String, dynamic>?;

    // 解析嵌套的filters结构：{分类ID: [筛选维度列表]}
    Map<String, List<VodFilter>> parsedFilters = {};
    if (filtersData != null) {
      filtersData.forEach((key, value) {
        if (value is List) {
          parsedFilters[key] = value
              .map((e) => VodFilter.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return VodListResponse(
      code: int.tryParse(json['code']?.toString() ?? '0') ?? 0,
      msg: json['msg']?.toString() ?? '',
      page: int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      pagecount: int.tryParse(json['pagecount']?.toString() ?? '1') ?? 1,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      list: listData
              ?.map((e) => VodItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      classes: classData
              ?.map((e) => VodClass.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      filters: parsedFilters,
    );
  }
}

// 剧集/集数信息：label为集数名称（如"第1集"），url为播放地址
class Episode {
  final String label; // 集数标签
  final String url; // 播放地址

  Episode({required this.label, required this.url});
}

// 播放源，包含源名称（如"量子云"）和该源下的剧集列表
class PlaySource {
  final String name; // 播放源名称
  final List<Episode> episodes; // 该播放源下的剧集列表

  PlaySource({required this.name, required this.episodes});
}
