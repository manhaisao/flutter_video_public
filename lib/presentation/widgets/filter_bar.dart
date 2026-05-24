import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/vod_models.dart';
import '../../data/repositories/vod_repository.dart';
import '../../domain/entities/app_tab.dart';

// 筛选栏组件：根据当前分类标签显示多行筛选项（如地区、年份、类型等），以可选标签形式展示
class FilterBar extends StatefulWidget {
  final VodRepository repository;
  final AppTab tab;
  // 选中筛选项后的回调，key 为筛选字段名，value 为选中的值
  final void Function(String key, String value) onFilterSelected;

  const FilterBar({
    super.key,
    required this.repository,
    required this.tab,
    required this.onFilterSelected,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  // 监听 repository 数据变化以刷新 UI（如筛选选项加载完成后更新）
  StreamSubscription<VodRepository>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.repository.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _sub?.cancel();
      _sub = widget.repository.stream.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前标签下的筛选配置
    final filtersByTypeId = widget.repository.getFilters(widget.tab);
    if (filtersByTypeId.isEmpty) return const SizedBox.shrink();

    final filterList = filtersByTypeId.values.first;
    if (filterList.isEmpty) return const SizedBox.shrink();

    // 获取当前已激活的筛选值
    final activeFilters = widget.repository.getActiveFilters(widget.tab);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // 每行一个筛选维度（如：地区、年份、类型）
        children: filterList.map((filter) {
          final selectedValue = activeFilters[filter.key];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _FilterRow(
              label: filter.name,
              values: filter.values,
              selectedValue: selectedValue,
              onSelected: (value) {
                widget.onFilterSelected(filter.key, value);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 单行筛选项：左侧标签名 + 右侧水平滚动的可选标签列表
class _FilterRow extends StatelessWidget {
  final String label;
  final List<VodFilterValue> values;
  final String? selectedValue;
  final void Function(String value) onSelected;

  const _FilterRow({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 筛选标签名（如"地区:"）
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.hintText,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Expanded(
          // 水平滚动以容纳较多筛选项
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "全部" 选项：值为空字符串时视为选中
                _buildChip('全部', '', selectedValue == null || selectedValue!.isEmpty),
                const SizedBox(width: 6),
                ...values.map((v) {
                  final isSelected = selectedValue == v.v;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildChip(v.n, v.v, isSelected),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建筛选标签：选中时橘色背景白色文字，未选中时深色背景灰色文字
  Widget _buildChip(String text, String value, bool isSelected) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orangeAccent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
