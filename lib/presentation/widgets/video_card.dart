import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/vod_models.dart';

// 视频卡片组件：展示封面图、影片名称、备注标签和类型
class VideoCard extends StatelessWidget {
  final VodItem item;
  final VoidCallback onTap;

  const VideoCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        // 裁剪圆角溢出内容
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 封面图（占大部分空间），加载失败时显示占位图标
            Expanded(
              child: Container(
                color: AppColors.cardBackground,
                child: item.vodPic.isNotEmpty
                    ? Image.network(
                        item.vodPic,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // 底部文字信息：影片名 + 备注/类型
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.vodName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // 备注（如"完结"/"更新至XX集"），橘色显示
                      if (item.vodRemarks.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.vodRemarks,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.orangeAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      // 类型标签（如"动作"/"喜剧"），灰色显示
                      if (item.typeName.isNotEmpty)
                        Text(
                          item.typeName,
                          style: const TextStyle(
                            color: AppColors.tertiaryText,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 封面加载失败或无封面时的占位图标
  Widget _placeholder() {
    return Center(
      child: Icon(Icons.movie, color: AppColors.tertiaryText.withValues(alpha: 0.4), size: 36),
    );
  }
}
