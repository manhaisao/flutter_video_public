import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../../core/constants/app_colors.dart';

// WebView 内嵌页面组件：支持 WebView2 初始化、加载进度条、错误重试
class WebViewFragment extends StatefulWidget {
  final String url;

  const WebViewFragment({super.key, required this.url});

  @override
  State<WebViewFragment> createState() => _WebViewFragmentState();
}

class _WebViewFragmentState extends State<WebViewFragment> {
  InAppWebViewController? _controller;
  WebViewEnvironment? _webViewEnvironment;
  // 页面加载进度（0.0 ~ 1.0）
  double _loadingProgress = 0;
  bool _hasError = false;
  // WebView 环境是否已初始化完成
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebViewEnvironment();
  }

  // 初始化 WebView2 运行环境，检测可用性并创建环境实例
  Future<void> _initWebViewEnvironment() async {
    try {
      final availableVersion = await WebViewEnvironment.getAvailableVersion();
      // 非 Web 平台且未安装 WebView2 时提示用户安装
      if (availableVersion == null && !kIsWeb) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = '未检测到 WebView2 运行时，请安装 Microsoft Edge WebView2';
          });
        }
        return;
      }

      // 设置用户数据目录到应用支持目录下
      final appDataDir = await path_provider.getApplicationSupportDirectory();
      final userDataFolder = '${appDataDir.path}/webview_data';

      _webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(userDataFolder: userDataFolder),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'WebView 初始化失败: $e';
        });
      }
    }
  }

  // 页面开始加载时重置状态
  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    setState(() {
      _loadingProgress = 0;
      _hasError = false;
      _errorMessage = null;
    });
  }

  // 监听页面加载进度（0~100）
  void _onProgressChanged(InAppWebViewController controller, int progress) {
    setState(() => _loadingProgress = progress / 100);
  }

  // 页面加载完成时隐藏进度条
  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    setState(() => _loadingProgress = 0);
  }

  // 页面加载出错时（仅主框架错误才显示错误视图）
  void _onReceivedError(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceError error,
  ) {
    if (request.isForMainFrame ?? false) {
      setState(() {
        _hasError = true;
        _errorMessage = '加载失败: ${error.description}';
      });
    }
  }

  // 重试：已创建控制器则刷新页面，否则重新初始化 WebView 环境
  void _reload() {
    if (_controller != null) {
      _controller!.reload();
    } else {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _isInitialized = false;
      });
      _initWebViewEnvironment();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 错误状态
    if (_hasError) {
      return _buildErrorView();
    }

    // 初始化中，显示加载动画
    if (!_isInitialized) {
      return _buildLoadingView();
    }

    // 正常 WebView 视图 + 顶部加载进度条
    return Stack(
      children: [
        InAppWebView(
          webViewEnvironment: _webViewEnvironment,
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36',
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onLoadStart: _onLoadStart,
          onProgressChanged: _onProgressChanged,
          onLoadStop: _onLoadStop,
          onReceivedError: _onReceivedError,
        ),
        // 顶部线性进度条，仅在加载中显示
        if (_loadingProgress > 0 && _loadingProgress < 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadingProgress,
              minHeight: 3,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orangeAccent),
            ),
          ),
      ],
    );
  }

  // WebView 初始化中的加载视图
  Widget _buildLoadingView() {
    return Container(
      color: AppColors.backgroundColor,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.orangeAccent),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '正在加载视频源...',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // WebView 错误视图：显示错误信息和重试按钮
  Widget _buildErrorView() {
    return Container(
      color: AppColors.backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.accentRed, size: 48),
            const SizedBox(height: 16),
            const Text(
              '加载失败',
              style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.tertiaryText, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
