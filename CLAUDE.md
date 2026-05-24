# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Run on Windows desktop (default)
flutter run -d windows

# Build Windows release
flutter build windows

# Static analysis
flutter analyze

# Run tests
flutter test
```

## Architecture Overview

"雯雯影视" — Windows桌面视频浏览器，无边框窗口 + 自定义标题栏，使用第三方视频API获取内容，支持m3u8/HLS在线播放和本地下载。

### 分层结构

```
lib/
├── main.dart                          # 入口：初始化media_kit，创建无边框窗口
├── core/constants/
│   └── app_colors.dart                # 全局颜色常量（暗色主题）
├── domain/entities/
│   └── app_tab.dart                   # AppTab枚举 + 扩展（标题/图标/标签）
├── data/
│   ├── models/
│   │   ├── vod_models.dart            # 视频数据模型（VodItem, Episode, PlaySource等）
│   │   └── download_task.dart         # 下载任务模型（DownloadTask, DownloadSegment）
│   ├── services/
│   │   ├── vod_api_service.dart       # 第三方视频API调用（HTTP请求）
│   │   ├── download_service.dart      # 下载引擎（m3u8解析、分段下载、合并、ffmpeg转码）
│   │   └── download_database.dart     # 本地SQLite数据库（任务+分段进度持久化）
│   └── repositories/
│       └── vod_repository.dart        # 视频仓库（列表缓存、分页、客户端筛选）
├── presentation/
│   ├── viewmodels/
│   │   └── home_view_model.dart       # 首页ViewModel（标签切换、分类数据、筛选）
│   ├── pages/
│   │   ├── home_page.dart             # 主页（侧边栏+内容区+下载入口）
│   │   ├── vod_detail_page.dart       # 视频详情页（播放器+剧集列表+下载编辑模式）
│   │   ├── download_list_page.dart    # 下载列表页（按视频分组展示）
│   │   └── download_detail_page.dart  # 下载详情页（单视频的剧集级进度管理）
│   └── widgets/
│       ├── top_bar.dart               # 自定义标题栏（搜索框+窗口控制按钮）
│       ├── side_tab.dart              # 侧边栏标签按钮（hover/选中态）
│       ├── home_fragment.dart         # 首页片段（Hero横幅+分类横滚列表）
│       ├── content_fragment.dart      # 内容区路由（首页/分类列表/WebView源站）
│       ├── video_card.dart            # 视频卡片组件（封面+名称+更新信息）
│       ├── video_grid.dart            # 视频网格+分页栏
│       ├── filter_bar.dart            # 分类筛选栏（年份/地区/类型）
│       ├── video_player_widget.dart   # media_kit视频播放器封装
│       ├── buffered_progress_bar.dart # 可拖拽播放进度条（支持seek）
│       └── webview_fragment.dart      # 内嵌WebView2（加载第三方视频源站）
```

---

## 逐文件说明

### 入口层

**`lib/main.dart`**
- 调用 `MediaKit.ensureInitialized()` 初始化视频播放引擎
- `doWhenWindowReady()` 设置窗口最小尺寸1920×1080、标题"雯雯影视"
- `MyApp` 返回 `MaterialApp`，home 为 `HomePage`

### Core — 常量

**`lib/core/constants/app_colors.dart`**
- 所有颜色集中定义：背景 `#141414`、卡片、主文字、次要文字、橘色强调色、绿色成功色、红色错误色、窗口按钮三态颜色

### Domain — 实体

**`lib/domain/entities/app_tab.dart`**
- `AppTab` 枚举：`home`, `tvSeries`, `movie`, `anime`, `variety`, `videoSite`
- `AppTabExtension` 扩展提供 `title`（中文名）、`icon`（Material图标）、`fragmentLabel`（页面标题）

### Data — 模型

**`lib/data/models/vod_models.dart`**
- `VodItem`：视频条目完整字段（vodId, vodName, vodPic, vodRemarks, vodPlayFrom, vodPlayUrl等），含 `fromJson` / `copyWith`
- `VodClass`：分类 typeId/typeName
- `VodFilter` / `VodFilterValue`：筛选器（key/name/values，来自API filters字段）
- `VodListResponse`：列表API响应（code, page, pagecount, list, classes, filters）
- `Episode`：剧集 label+url（从 `vodPlayUrl` 解析出）
- `PlaySource`：播放源 name + episodes 列表

**`lib/data/models/download_task.dart`**
- `DownloadStatus` 枚举：`pending → downloading → paused / completed / failed`
- `DownloadTask`：下载任务（vodId, episodeLabel, episodeUrl, status, totalSegments, downloadedSegments, savePath），含 `toMap`/`fromMap` 用于SQLite读写，`progress` 计算属性
- `DownloadSegment`：m3u8分段（taskId, segmentIndex, segmentUrl, status, retryCount），含 `toMap`/`fromMap`

### Data — API服务

**`lib/data/services/vod_api_service.dart`**
- 封装第三方视频API的HTTP请求，baseUrl 拼接 `api.php/provide/vod/`
- `fetchCategories()` → `?ac=class`
- `fetchVodList(typeId, page)` → `?ac=list&t=XX&pg=XX`，返回后调用 `_enrichListWithPics()` 批量获取封面图
- `fetchVodDetail(vodId)` → `?ac=detail&ids=XX`
- `search(keyword, page)` → `?ac=search&wd=XX`
- `_get()` 统一处理响应：状态码检查、code字段业务错误检查

### Data — 下载系统

**`lib/data/services/download_service.dart`**（单例）
- m3u8下载引擎，完整流程：解析m3u8 → 写入分段表 → 8路并发下载.ts → 二进制合并 → ffmpeg转mp4
- `_parseM3u8(url)`：递归处理主播放列表（`#EXT-X-STREAM-INF`）和媒体播放列表，提取所有.ts分段URL
- `_runDownload(taskId)`：下载循环，每批取8个待下载分段，`Future.wait` 并发下载，单段最多重试3次
- `_mergeSegments(taskId)`：二进制拼接所有.ts → 尝试 `ffmpeg -c copy` remux为mp4 → 失败则保留.ts
- `_ensureFfmpeg()`：检查系统PATH → 检查 `appDir/ffmpeg/ffmpeg.exe`
- 并发控制：最多3个任务同时下载，超出的保持pending排队
- 事件流：`StreamController<DownloadEvent>.broadcast()` 通知UI（taskAdded/Removed/statusChanged/progressChanged）
- 暂停/恢复/删除：`_pausedTasks` 集合标记，下载循环检测到后停止；删除时等待活跃future完成 + 3次重试删除临时文件

**`lib/data/services/download_database.dart`**
- 使用 `sqflite_common_ffi`（Windows FFI），数据库路径 `appDir/downloads.db`
- 两张表：`download_tasks`（主表）+ `download_segments`（分段表，外键 task_id）
- DB version 2：新增 `vod_pic` 列
- 核心方法：`insertTask`, `updateTask`, `deleteTask`, `getAllTasks`, `getTask`, `isEpisodeDownloaded`, `insertSegments`（批量）, `getPendingSegments`（过滤已完成分段）, `updateSegment`

### Data — 仓库

**`lib/data/repositories/vod_repository.dart`**
- 封装视频列表的加载、缓存、分页、筛选逻辑
- `_tabCache`：每个AppTab缓存完整列表（`_TabPageData`：fullItems + 筛选后的filteredItems + 当前页 + 活跃筛选条件）
- `loadList(typeIds, tab, page)`：缓存命中直接返回；缓存未命中→ API请求→合并多typeId结果→构建筛选器
- `loadNextPage()` / `loadPrevPage()`：追加/替换分页数据
- `applyFilter(key, value)`：客户端筛选（年份精确匹配 / 地区归一化匹配 / 类型匹配）
- `_buildFiltersFromItems()`：从已加载数据构建筛选选项（年份降序、地区归一化（中日美等合并）、类型去重）
- `_normalizeArea()`：地区名称归一化（如"香港"/"台湾"/"大陆"→"中国"）
- `_hiddenFilterKeys`：隐藏"area"筛选键（当前禁用）
- 通过 `StreamController<VodRepository>.broadcast()` 通知UI数据变化

### Presentation — ViewModel

**`lib/presentation/viewmodels/home_view_model.dart`**
- `selectedTab`：`ValueNotifier<AppTab>` 驱动侧边栏选中态
- `homeMovies/TvSeries/Variety/Anime`：首页四个分类的 `ValueNotifier<List<VodItem>>`
- `isHomeLoading` / `isInitializing`：加载状态
- `initialize()` → `_loadHomeCategories()` 并行请求4个分类各取8条
- `selectTab(tab)` → 切换 `selectedTab` + 触发 `repository.loadList()`
- Type ID映射：`movieIds=[6-12,39]`, `tvSeriesIds=[13-19,23]`, `animeIds=[29-31]`, `varietyIds=[25-28]`
- 分页代理：`goToPage()`, `loadNextPage()`, `loadPrevPage()` → 委托给repository

### Presentation — 页面

**`lib/presentation/pages/home_page.dart`**
- 主页面骨架：`TopBar`（顶部标题栏）+ `Row[Sidebar(220px) + Expanded(ContentFragment)]`
- 侧边栏：`SideTab`列表 + 底部"下载管理"按钮（`_DownloadNavButton`，push到`DownloadListPage`）
- 视频点击：`Navigator.push(VodDetailPage)`
- `kDefaultApiUrl = 'http://api.apibdzy.com/'`

**`lib/presentation/pages/vod_detail_page.dart`**
- 接收参数：`vodId`, `apiBaseUrl`, 可选的 `initialEpisode`（从下载页跳转时预选剧集）
- 布局：顶部Header栏（返回+标题+下载按钮）+ 播放器/信息面板（Row 3:2）+ 底部播放源/剧集网格
- `_parseSources(item)`：按 `$$$` / `#` / `$` 分隔符解析 `vodPlayFrom` 和 `vodPlayUrl`，构建 `PlaySource[]`
- `_selectInitialEpisode()`：遍历所有播放源查找匹配 `initialEpisode` label 的剧集
- `_playCurrentEpisode()`：优先检查本地文件（查询 `DownloadService` 中 completed 且 savePath 匹配的记录），存在则用 `file:///` URI，否则用网络URL
- `_playInitialEpisode()`：通过 `addPostFrameCallback` 延迟到首帧后才播放，确保 player widget 已挂载
- 下载编辑模式：`_isEditMode` 切换 → 剧集item显示checkbox → 底部操作栏（全选+开始下载+取消）
- `_startDownload()`：首次提示选择目录（`FilePicker.getDirectoryPath()`），批量添加下载任务并启动
- `_refreshDownloadedStatus()`：查询已完成的下载，更新 `_downloadedKeys` 集合，驱动绿点显示

**`lib/presentation/pages/download_list_page.dart`**
- 按 `vodId` 聚合下载任务为 `_VideoGroup`（vodId, vodName, vodPic, 总集数, 已完成数, 是否有活跃任务）
- 排序：活跃任务优先 → 按vodId
- 紧凑卡片：48×64封面 + 名称（14px）+ "X集 · 已下载 Y集"（12px，5px间距）
- 活跃任务：名称旁显示旋转进度指示器；全部完成：绿色文字
- 点击进入 `DownloadDetailPage`，返回时重新加载任务列表
- "清空已完成"按钮：批量删除completed/failed任务
- 事件监听：实例级更新单个task（非全量刷新）

**`lib/presentation/pages/download_detail_page.dart`**
- 接收参数：`vodName`, `tasks`, `vodId`, `apiBaseUrl`
- 按状态排序：downloading → pending → paused → failed → completed
- 每集卡片：集数图标（绿色=已完成）+ 进度条 + 状态文字 + 操作按钮（暂停/继续/删除）
- 已完成剧集可点击 → `Navigator.push(VodDetailPage)` 带 `initialEpisode` 参数
- 删除确认对话框

### Presentation — 组件

**`lib/presentation/widgets/top_bar.dart`**
- 自定义标题栏，`WindowTitleBarBox` 包裹
- `MoveWindow`（可拖拽区域）+ 搜索框（静态占位）+ 设置/历史按钮 + 最小化/最大化/关闭窗口按钮
- 窗口按钮使用 `bitsdojo_window` 的 `MinimizeWindowButton/MaximizeWindowButton/CloseWindowButton`

**`lib/presentation/widgets/side_tab.dart`**
- 侧边栏标签按钮：选中态橘色无背景，未选中态hover高亮
- `onHover` 监听改变文字/图标颜色

**`lib/presentation/widgets/home_fragment.dart`**
- 首页内容：Hero横幅（第一项，渐变叠加+播放按钮）+ 按分类横滚列表（电影/电视剧/综艺/动漫）
- 每行：标题 + "查看更多" + 130px宽的 `VideoCard` 横滚列表
- 嵌套 `ValueListenableBuilder` 监听四个分类数据

**`lib/presentation/widgets/content_fragment.dart`**
- 内容区路由：`AppTab.videoSite` → `WebViewFragment`；`AppTab.home` → `HomeFragment`；其他 → `FilterBar` + `VideoGrid`
- `_videoSourceUrl = 'http://饭太硬.top/tv'`（WebView加载的第三方源站）

**`lib/presentation/widgets/video_card.dart`**
- 视频卡片：图片（占满剩余空间）+ 底部信息区（名称13px + 更新信息11px，间距4px，底部padding 5px）
- 圆角12px，`vodRemarks` 橘色显示（如"更新第XX集"）

**`lib/presentation/widgets/video_grid.dart`**
- 响应式网格：`LayoutBuilder` 计算列数（`maxWidth/200`，范围2~8），`childAspectRatio: 0.55`
- 底部分页栏：上一页 / 第X/Y页 / 下一页，加载中显示转圈
- 空状态：加载中/错误/重试

**`lib/presentation/widgets/filter_bar.dart`**
- 筛选栏：遍历 `repository.getFilters(tab)` 生成筛选行
- 每行：标签（48px固定宽度）+ 横向滚动的筛选项chip
- 选中态橘色背景白色文字，未选中灰色
- 包含"全部"选项（value为空字符串）

**`lib/presentation/widgets/video_player_widget.dart`**
- media_kit 播放器封装：`Video` 组件 + 缓冲转圈 + 错误提示
- 监听 `player.stream.buffering` 更新缓冲状态
- `playUrl()` 方法供外部调用

**`lib/presentation/widgets/buffered_progress_bar.dart`**
- 可交互进度条：三轨（底色/缓冲/播放进度）+ 拖拽圆点
- 支持 `onTapDown` 和 `onHorizontalDragUpdate` seek
- 时间格式化：超过1小时显示 HH:mm:ss，否则 mm:ss

**`lib/presentation/widgets/webview_fragment.dart`**
- 使用 `flutter_inappwebview` 加载 `WebViewEnvironment`（WebView2运行时）
- 初始化检测：无WebView2时显示错误提示；有则创建userData目录
- 进度条：`onProgressChanged` 驱动顶部3px线性进度条
- 错误处理：`onReceivedError` 主框架错误 → 错误页面+重试按钮
- UserAgent伪装为Chrome 148 Windows

---

## 导航流程

```
HomePage
├── 侧边栏切换 → contentFragment 切换显示
├── videoCard 点击 → push VodDetailPage (播放+下载)
├── "下载管理"按钮 → push DownloadListPage
│   └── 点击视频组 → push DownloadDetailPage (剧集进度)
│       └── 点击已完成剧集 → push VodDetailPage (带initialEpisode)
└── VodDetailPage
    ├── 切换源/点击剧集 → _playCurrentEpisode (本地优先)
    └── 下载按钮 → 编辑模式 → 选择剧集 → 开始下载
```

## 数据流

```
API (apibdzy.com)
  → VodApiService (HTTP GET)
    → VodRepository (缓存+筛选+分页)
      → HomeViewModel (ValueNotifier)
        → Widget (ValueListenableBuilder)
```

```
用户点击下载
  → DownloadService.addDownload() (写入DB)
    → DownloadService._runDownload()
      → m3u8解析 → 8路并发下载.ts
        → 二进制合并 → ffmpeg remux → mp4
          → 更新DB status=completed
            → 广播 DownloadEvent → UI刷新
```

## Key Dependencies

| 包名 | 用途 |
|------|------|
| `bitsdojo_window` | 无边框窗口 + 自定义标题栏按钮 |
| `media_kit` + `media_kit_video` + `media_kit_libs_windows_video` | 视频播放（HLS/mp4/本地文件） |
| `flutter_inappwebview` | 内嵌WebView2加载第三方视频源站 |
| `sqflite_common_ffi` | Windows SQLite（下载进度持久化） |
| `file_picker` | 下载目录选择对话框 |
| `http` | HTTP请求（API调用 + m3u8/.ts下载） |
| `path_provider` | 获取app数据目录 |

## 代码约定

- 无外部状态管理库 — 使用 `ValueNotifier` + `ValueListenableBuilder`
- 服务层使用单例（`factory DownloadService()`）
- Widget文件以功能命名，私有类以 `_` 开头
- 中文UI字符串直接硬编码
- `debugPrint` 用于临时调试（如播放器错误日志）
- 静默catch仅在非关键路径（如图片加载失败）
