import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// 自定义窗口顶部栏：包含搜索框、设置/历史按钮和窗口控制按钮（最小化/最大化/关闭）
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    // WindowTitleBarBox 是 bitsdojo_window 提供的无边框窗口标题栏容器
    return WindowTitleBarBox(
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        color: AppColors.backgroundColor,
        child: Row(
          children: [
            // 左侧可拖拽区域，用于移动窗口
            Expanded(
              child: MoveWindow(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // 居中搜索框（占位，暂无交互）
            Container(
              width: 280,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.searchBoxBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, color: AppColors.searchBoxHint, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    '搜索影视/动漫/综艺',
                    style: TextStyle(color: AppColors.searchBoxHint, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // 设置按钮
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings),
              color: AppColors.secondaryText,
              splashRadius: 20,
              tooltip: '设置',
            ),
            // 历史记录按钮
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.history),
              color: AppColors.secondaryText,
              splashRadius: 20,
              tooltip: '历史',
            ),
            const SizedBox(width: 6),
            // 窗口最小化按钮（bitsdojo_window 提供）
            MinimizeWindowButton(
              colors: WindowButtonColors(
                iconNormal: AppColors.windowButtonNormal,
                mouseOver: AppColors.windowButtonHover,
                mouseDown: AppColors.windowButtonPressed,
                iconMouseOver: AppColors.primaryText,
                iconMouseDown: AppColors.primaryText,
              ),
            ),
            // 窗口最大化/还原按钮
            MaximizeWindowButton(
              colors: WindowButtonColors(
                iconNormal: AppColors.windowButtonNormal,
                mouseOver: AppColors.windowButtonHover,
                mouseDown: AppColors.windowButtonPressed,
                iconMouseOver: AppColors.primaryText,
                iconMouseDown: AppColors.primaryText,
              ),
            ),
            // 窗口关闭按钮（hover 时变红）
            CloseWindowButton(
              colors: WindowButtonColors(
                iconNormal: AppColors.windowButtonNormal,
                mouseOver: AppColors.closeButtonHover,
                mouseDown: AppColors.closeButtonPressed,
                iconMouseOver: AppColors.primaryText,
                iconMouseDown: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
