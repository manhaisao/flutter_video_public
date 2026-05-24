import 'package:flutter/material.dart';

/// 应用程序中央色值管理
/// 统一定义所有颜色常量，便于维护和主题切换
class AppColors {
  // 禁止实例化
  AppColors._();

  // ============ 背景色 ============
  /// 深色背景主色
  static const Color backgroundColor = Color(0xFF141414);

  /// 左侧边栏背景色
  static const Color sidebarBackground = Color(0xFF0F0F0F);

  /// 内容卡片背景色
  static const Color cardBackground = Color(0xFF1F1F1F);

  // ============ 文字色 ============
  /// 主要文字色（白色）
  static const Color primaryText = Color(0xFFFFFFFF);

  /// 次要文字色（浅灰）
  static const Color secondaryText = Color(0xFFCCCCCC);

  /// 辅助文字色（深灰）
  static const Color tertiaryText = Color(0xFF999999);

  /// 提示文字色（极淡灰）
  static const Color hintText = Color(0xFF666666);

  // ============ 组件色 ============
  /// 窗口按钮默认色
  static const Color windowButtonNormal = Color(0xFF808080);

  /// 窗口按钮悬停色
  static const Color windowButtonHover = Color(0xFF606060);

  /// 窗口按钮按下色
  static const Color windowButtonPressed = Color(0xFF404040);

  /// 关闭按钮悬停色
  static const Color closeButtonHover = Color(0xFFB00020);

  /// 关闭按钮按下色
  static const Color closeButtonPressed = Color(0xFF910017);

  // ============ 选中状态 ============
  /// Tab 未选中文字色
  static const Color unselectedTabText = Color(0xFFB8B8B8);

  // ============ 搜索框 ============
  /// 搜索框背景色（8% 白色透明）
  static const Color searchBoxBackground = Color(0x14FFFFFF);

  /// 搜索框文字提示色
  static const Color searchBoxHint = Color(0xFF8B8B8B);

  // ============ 边框和分割线 ============
  /// 窗口边框色
  static const Color windowBorder = Color(0xFF141414);

  /// 分割线色
  static const Color dividerColor = Color(0xFF2A2A2A);

  // ============ 品牌色 ============
  /// 品牌主色（紫色）
  static const Color brandPrimary = Color(0xFF7C3AED);

  /// 品牌次级色
  static const Color brandSecondary = Color(0xFF8B5CF6);

  /// 强调色（红色）
  static const Color accentRed = Color(0xFFEF4444);

  /// 橘色（选中状态）
  static const Color orangeAccent = Color(0xFFFF8C42);

  /// 成功色（绿色）
  static const Color successGreen = Color(0xFF10B981);

  /// 警告色（黄色）
  static const Color warningYellow = Color(0xFFFB923C);
}
