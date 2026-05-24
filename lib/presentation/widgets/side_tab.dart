import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/app_tab.dart';

// 侧边栏标签项：显示图标和文字，支持选中/悬停状态
class SideTab extends StatefulWidget {
  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  const SideTab({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  State<SideTab> createState() => _SideTabState();
}

class _SideTabState extends State<SideTab> {
  // 鼠标是否悬停在该标签上
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // 选中状态：橘色文字和图标，无背景
    if (widget.selected) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(widget.tab.icon, color: AppColors.orangeAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                widget.tab.title,
                style: const TextStyle(
                  color: AppColors.orangeAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 未选中状态：悬停时白色，否则灰色
    final foregroundColor = _isFocused ? AppColors.primaryText : AppColors.unselectedTabText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          // 监听鼠标进入/离开以更新焦点状态
          onHover: (hovered) {
            setState(() => _isFocused = hovered);
          },
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(widget.tab.icon, color: foregroundColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  widget.tab.title,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
