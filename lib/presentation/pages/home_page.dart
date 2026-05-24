import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/app_tab.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/content_fragment.dart';
import '../widgets/side_tab.dart';
import '../widgets/top_bar.dart';
import 'vod_detail_page.dart';

const kDefaultApiUrl = 'http://api.apibdzy.com/';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = HomeViewModel(apiBaseUrl: kDefaultApiUrl);
    viewModel.isInitializing.addListener(_onChanged);
    viewModel.isLoadingMore.addListener(_onChanged);
    viewModel.repository.stream.listen((_) {
      if (mounted) setState(() {});
    });
    viewModel.initialize();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    viewModel.isInitializing.removeListener(_onChanged);
    viewModel.isLoadingMore.removeListener(_onChanged);
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Container(
        color: AppColors.backgroundColor,
        child: WindowBorder(
          color: AppColors.windowBorder,
          width: 1,
          child: Column(
            children: [
              const TopBar(),
              Expanded(
                child: Row(
                  children: [
                    _buildSidebar(),
                    Expanded(
                      child: Container(
                        color: AppColors.backgroundColor,
                        child: ValueListenableBuilder<AppTab>(
                          valueListenable: viewModel.selectedTab,
                          builder: (context, selectedTab, _) {
                            return ContentFragment(
                              currentTab: selectedTab,
                              viewModel: viewModel,
                              repository: viewModel.repository,
                              onNextPage: () => viewModel.loadNextPage(),
                              onPrevPage: () => viewModel.loadPrevPage(),
                              onGoToPage: (page) => viewModel.goToPage(page),
                              onVideoTap: (item) {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => VodDetailPage(
                                    vodId: item.vodId,
                                    apiBaseUrl: kDefaultApiUrl,
                                  ),
                                ));
                              },
                              onViewMore: (tab) => viewModel.selectTab(tab),
                              onFilterSelected: (key, value) =>
                                  viewModel.applyFilter(key, value),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      color: AppColors.backgroundColor,
      child: ValueListenableBuilder<AppTab>(
        valueListenable: viewModel.selectedTab,
        builder: (context, selectedTab, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('导航', style: TextStyle(
                color: Colors.white54, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              for (final tab in AppTab.values)
                SideTab(
                  tab: tab,
                  selected: tab == selectedTab,
                  onTap: () => viewModel.selectTab(tab),
                ),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }
}
