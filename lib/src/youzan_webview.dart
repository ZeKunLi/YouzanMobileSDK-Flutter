import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youzan/src/youzan_webview_controller.dart';

/// @ClassName:YouzanWebView
///
/// @Description: 有赞原生WebView, 提供了 WebView 的所有能力，对有赞商城体系的页面做了优化。
/// @author: 李泽昆
/// @date: 2021-11-16

typedef YouzanWebViewCreatedCallback = void Function(
    YouzanWebViewController controller);

class YouzanWebView extends StatefulWidget {
  /// 有赞登录
  final YouzanWebViewCreatedCallback? onCreated;
  final String url;

  YouzanWebView({
    Key? key,
    required this.url,
    required this.onCreated,
  });

  @override
  State<YouzanWebView> createState() => _YouzanWebViewState();
}

class _YouzanWebViewState extends State<YouzanWebView> {
  @override
  Widget build(BuildContext context) {
    return nativeView();
  }

  nativeView() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'plugins.youzan_web_view/view',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: <String, dynamic>{
          "url": widget.url,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return UiKitView(
        viewType: 'plugins.youzan_web_view/view',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: <String, dynamic>{
          "url": widget.url,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
  }

  Future<void> onPlatformViewCreated(id) async {
    if (widget.onCreated == null) {
      return;
    }
    widget.onCreated!(YouzanWebViewController.init(id));
  }
}