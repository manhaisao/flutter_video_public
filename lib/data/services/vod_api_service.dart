import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vod_models.dart';

// VOD API 服务层，封装所有HTTP请求，负责与苹果CMS v10 API交互
class VodApiService {
  final String baseUrl; // API服务器根地址
  final http.Client _client = http.Client();

  VodApiService({required this.baseUrl});

  // 构建完整的API基础路径：{baseUrl}/api.php/provide/vod/
  String get _apiUrl => baseUrl.endsWith('/')
      ? '${baseUrl}api.php/provide/vod/'
      : '$baseUrl/api.php/provide/vod/';

  // 获取所有分类列表 - GET /api.php/provide/vod/?ac=class
  Future<VodListResponse> fetchCategories() async {
    final uri = Uri.parse('$_apiUrl?ac=class');
    final response = await _get(uri);
    return VodListResponse.fromJson(response);
  }

  // 获取指定分类下的视频列表（带分页和扩展参数）
  // ac=list, t=分类ID, pg=页码
  Future<VodListResponse> fetchVodList({
    required int typeId,
    int page = 1,
    Map<String, String> extend = const {},
  }) async {
    final params = <String, String>{
      'ac': 'list',
      't': typeId.toString(),
      'pg': page.toString(),
      ...extend,
    };
    final uri = Uri.parse(_apiUrl).replace(queryParameters: params);
    final response = await _get(uri);
    final result = VodListResponse.fromJson(response);
    // 列表接口返回的vod_pic可能为空，通过批量detail接口补全封面图等字段
    if (result.list.isNotEmpty) {
      await _enrichListWithPics(result.list);
    }
    return result;
  }

  // 批量补全视频详情字段（封面、年份、地区等）
  // 通过 ac=detail&ids=... 一次性获取多条记录，然后逐个覆盖原条目
  Future<void> _enrichListWithPics(List<VodItem> items) async {
    try {
      final ids = items.map((e) => e.vodId.toString()).join(',');
      final detailUri = Uri.parse('$_apiUrl?ac=detail&ids=$ids');
      final detailResponse = await _get(detailUri);
      final detailList = (detailResponse['list'] as List<dynamic>?)
              ?.map((e) => VodItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final detailMap = <int, VodItem>{};
      for (final d in detailList) {
        detailMap[d.vodId] = d;
      }
      // 仅覆盖非空字段，保留原条目已有数据
      for (int i = 0; i < items.length; i++) {
        final d = detailMap[items[i].vodId];
        if (d != null) {
          items[i] = items[i].copyWith(
            vodPic: d.vodPic.isNotEmpty ? d.vodPic : null,
            vodYear: d.vodYear.isNotEmpty ? d.vodYear : null,
            vodArea: d.vodArea.isNotEmpty ? d.vodArea : null,
            vodLang: d.vodLang.isNotEmpty ? d.vodLang : null,
            vodActor: d.vodActor.isNotEmpty ? d.vodActor : null,
            vodDirector: d.vodDirector.isNotEmpty ? d.vodDirector : null,
          );
        }
      }
    } catch (_) {
      // 补全失败不影响列表正常展示，静默忽略
    }
  }

  // 获取单个视频详情 - GET /api.php/provide/vod/?ac=detail&ids={vodId}
  Future<VodItem> fetchVodDetail(int vodId) async {
    final uri = Uri.parse('$_apiUrl?ac=detail&ids=$vodId');
    final response = await _get(uri);
    final list = (response['list'] as List<dynamic>?)
            ?.map((e) => VodItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    if (list.isEmpty) {
      throw Exception('视频不存在');
    }
    return list.first;
  }

  // 关键词搜索 - GET /api.php/provide/vod/?ac=search&wd={keyword}&pg={page}
  Future<VodListResponse> search(String keyword, {int page = 1}) async {
    final uri = Uri.parse('$_apiUrl?ac=search&wd=$keyword&pg=$page');
    final response = await _get(uri);
    return VodListResponse.fromJson(response);
  }

  // 统一GET请求封装，带UA头伪装、15s超时和通用code校验
  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': 'okhttp/3.14.9',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final code = decoded['code'];
      // API的code为1表示成功，其余值视为失败
      if (code != null && code != 1) {
        throw Exception(decoded['msg']?.toString() ?? '请求失败');
      }
      return decoded;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  // 关闭HTTP客户端，释放资源
  void dispose() {
    _client.close();
  }
}
