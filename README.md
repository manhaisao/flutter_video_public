# 雯雯影视

Windows 桌面视频播放器，无边框窗口 + 自定义标题栏，支持在线播放和本地下载。

## 功能

- 视频浏览：按分类浏览电影、电视剧、综艺、动漫
- 在线播放：m3u8/HLS 流媒体播放
- 本地下载：批量下载、断点续传（m3u8 分段级进度记录）
- 下载管理：暂停/继续/删除，已下载剧集本地播放

## 安装

从 [Releases](https://github.com/manhaisao/flutter_video/releases) 页面下载最新安装包 `wenwen_video_setup_v*.exe`，双击运行即可安装。

## 从源码构建

```bash
# 安装依赖
flutter pub get

# 运行
flutter run -d windows

# 构建 Release
flutter build windows

# 打包安装程序 (需要 Inno Setup 6)
cd installer && iscc setup.iss
```

## 技术栈

| 包 | 用途 |
|---|---|
| Flutter | UI 框架 |
| media_kit | 视频播放（HLS/mp4/本地文件） |
| sqflite_common_ffi | 本地 SQLite（下载进度持久化） |
| bitsdojo_window | 无边框窗口 |
| flutter_inappwebview | 内嵌 WebView2 |

## 免责声明

**本项目仅供学习交流使用，严禁用于商业用途。**

- 本软件不存储、不提供任何视频内容，所有内容均来自第三方 API 接口
- 本软件仅为技术学习目的开发，展示 Flutter 桌面开发、流媒体播放、下载引擎等技术实现
- 使用者应遵守当地法律法规，不得将本软件用于非法用途
- 使用本软件产生的任何版权纠纷或法律风险由使用者自行承担
- 开发者不对因使用本软件而产生的任何直接或间接损失负责

## License

仅限个人学习使用。禁止商用。
