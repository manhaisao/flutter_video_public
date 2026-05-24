import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/vod_models.dart';
import '../../data/services/vod_api_service.dart';
import '../widgets/video_player_widget.dart';

// 视频详情页 - 展示视频信息、播放器、播放源切换和剧集选择
class VodDetailPage extends StatefulWidget {
  final int vodId; // 视频ID
  final String apiBaseUrl; // API服务器基础地址

  const VodDetailPage({super.key, required this.vodId, required this.apiBaseUrl});

  @override
  State<VodDetailPage> createState() => _VodDetailPageState();
}

class _VodDetailPageState extends State<VodDetailPage> {
  VodItem? _item; // 视频详情数据
  bool _isLoading = true; // 是否正在加载
  String? _error; // 加载错误信息
  late final Player _player; // 媒体播放器实例
  late final VideoPlayerWidget _playerWidget; // 播放器UI组件
  List<PlaySource> _sources = []; // 多播放源列表
  int _currentSource = 0; // 当前选中的播放源索引
  int _currentEpisode = 0; // 当前播放的剧集索引

  @override
  void initState() {
    super.initState();
    _player = Player(); // 创建媒体播放器
    _playerWidget = VideoPlayerWidget(player: _player); // 创建播放器UI
    _loadDetail();
  }

  // 加载视频详情 - 请求API获取视频信息并解析播放源
  Future<void> _loadDetail() async {
    try {
      final service = VodApiService(baseUrl: widget.apiBaseUrl);
      final item = await service.fetchVodDetail(widget.vodId);
      _parseSources(item); // 解析播放源字符串
      if (mounted) {
        setState(() { _item = item; _isLoading = false; });
        _playInitialEpisode(); // 自动播放第一个剧集
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // 解析播放源字符串 - 将 "源名1$$$源名2" 和 "E01$url#E02$url$$$..." 格式解析为PlaySource列表
  void _parseSources(VodItem item) {
    final playFrom = item.vodPlayFrom;
    final playUrl = item.vodPlayUrl;
    if (playUrl.isEmpty) return;

    final fromNames = playFrom.split(r'$$$'); // 按 $$$ 分割源名称
    final urlGroups = playUrl.split(r'$$$'); // 按 $$$ 分割各源的URL组

    final sources = <PlaySource>[];
    for (int i = 0; i < fromNames.length && i < urlGroups.length; i++) {
      final name = fromNames[i].trim();
      final episodes = <Episode>[];
      final parts = urlGroups[i].split('#'); // 按 # 分割每个剧集
      for (final part in parts) {
        final segs = part.split(r'$'); // 按 $ 分割剧集标签和URL
        if (segs.length >= 2) {
          episodes.add(Episode(label: segs[0].trim(), url: segs[1].trim()));
        }
      }
      if (episodes.isNotEmpty) {
        sources.add(PlaySource(name: name.isNotEmpty ? name : '源${i + 1}', episodes: episodes));
      }
    }
    _sources = sources;
  }

  // 在帧渲染完成回调中触发播放，确保Widget树已构建后再操作Player
  void _playInitialEpisode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playCurrentEpisode();
    });
  }

  // 播放当前选中的剧集
  Future<void> _playCurrentEpisode() async {
    if (_sources.isEmpty || _item == null) return;
    final src = _sources[_currentSource];
    if (src.episodes.isEmpty) return;
    final ep = src.episodes[_currentEpisode];

    try {
      await _player.open(Media(ep.url));
      await _player.play();
    } catch (e) {
      debugPrint('[VodDetail] _playCurrentEpisode error: $e');
    }
  }

  // 切换播放源 - 重置剧集索引为0
  void _selectSource(int index) {
    if (index == _currentSource) return;
    setState(() { _currentSource = index; _currentEpisode = 0; });
    _playCurrentEpisode();
  }

  // 选择剧集播放
  void _selectEpisode(int index) {
    if (index == _currentEpisode) return;
    setState(() => _currentEpisode = index);
    _playCurrentEpisode();
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orangeAccent))
            : _error != null
                ? _buildError() // 加载失败显示错误页
                : _buildContent(),
      ),
    );
  }

  // 错误页面 - 显示错误信息和重试按钮
  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppColors.accentRed, size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppColors.tertiaryText)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () { setState(() { _isLoading = true; _error = null; }); _loadDetail(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangeAccent),
          child: const Text('重试', style: TextStyle(color: Colors.white)),
        ),
      ]),
    );
  }

  // 主内容区域 - 顶部栏 + 播放器/信息 + 源选择/剧集列表
  Widget _buildContent() {
    final item = _item!;
    final currentSource = _sources.isNotEmpty ? _sources[_currentSource] : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 顶部导航栏：返回按钮、视频标题
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: AppColors.cardBackground,
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.vodName,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),

      // 主体区域：播放器+信息 + 剧集列表
      Expanded(
        child: Column(children: [
          // 上半部分：播放器（左）和视频信息面板（右），比例 3:2
          Expanded(
            flex: 5,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 视频播放器
              Expanded(flex: 3, child: _playerWidget),
              // 视频信息面板
              Expanded(
                flex: 2,
                child: Container(
                  color: AppColors.cardBackground,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.vodName,
                          style: const TextStyle(color: AppColors.primaryText, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _infoRow('年份', item.vodYear),
                      _infoRow('地区', item.vodArea),
                      _infoRow('类型', item.typeName),
                      _infoRow('备注', item.vodRemarks),
                      if (item.vodDirector.isNotEmpty) _infoRow('导演', item.vodDirector),
                      if (item.vodActor.isNotEmpty) _infoRow('演员', item.vodActor),
                      if (item.vodContent.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('简介', style: TextStyle(color: AppColors.secondaryText, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_stripHtml(item.vodContent),
                            style: const TextStyle(color: AppColors.tertiaryText, fontSize: 12, height: 1.5)),
                      ],
                    ]),
                  ),
                ),
              ),
            ]),
          ),

          // 下半部分：播放源选择 + 剧集网格
          if (currentSource != null)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundColor,
                  border: Border(top: BorderSide(color: AppColors.dividerColor)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // 播放源选择器 - 仅多个源时显示
                  if (_sources.length > 1) ...[
                    const Text('播放源', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 4, children: List.generate(_sources.length, (i) {
                      final selected = i == _currentSource;
                      return ChoiceChip(
                        label: Text(_sources[i].name,
                            style: TextStyle(color: selected ? Colors.white : AppColors.secondaryText, fontSize: 12)),
                        selected: selected,
                        selectedColor: AppColors.orangeAccent,
                        backgroundColor: AppColors.cardBackground,
                        side: BorderSide.none,
                        onSelected: (_) => _selectSource(i),
                      );
                    })),
                    const SizedBox(height: 16),
                  ],
                  // 剧集列表标题
                  const Text('剧集列表', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                  const SizedBox(height: 8),
                  // 剧集网格 - 8列
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 3),
                      itemCount: currentSource.episodes.length,
                      itemBuilder: (context, index) {
                        final ep = currentSource.episodes[index];
                        final isCurrent = index == _currentEpisode;

                        return GestureDetector(
                          onTap: () => _selectEpisode(index),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.orangeAccent : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(ep.label,
                                style: TextStyle(
                                    color: isCurrent ? Colors.white : AppColors.secondaryText, fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }

  // 信息行组件 - 标签: 值 格式，用于展示年份/地区/类型等元数据
  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 44, child: Text('$label:',
            style: const TextStyle(color: AppColors.hintText, fontSize: 12))),
        Expanded(child: Text(value,
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 12))),
      ]),
    );
  }

  // 去除HTML标签和 &nbsp; 实体，用于清洗简介文本
  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }
}
