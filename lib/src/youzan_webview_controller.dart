import 'package:flutter/services.dart';

/// @ClassName: YouzanWebViewController
///
/// @Description:
/// @author: 李泽昆
/// @date: 2021-11-25

class YouzanWebViewController {
  late MethodChannel _channel;

  ///有赞 WebView 方法回调
  late Function webViewMethodCall;

  YouzanWebViewController.init(int id) {
    _channel = MethodChannel('youzan_webview_$id');
    _channel.setMethodCallHandler(_nativeMethodCallHandler);
  }

  Future<dynamic> _nativeMethodCallHandler(MethodCall methodCall) async {
    final result = await webViewMethodCall(methodCall);
    return result;
  }

  Future<void> loadUrl(String url) async {
    return _channel.invokeMethod('loadUrl', url);
  }

  Future<void> reload() async {
    return _channel.invokeMethod('reload');
  }

  Future<bool> canGoBack() async {
    return await _channel.invokeMethod('canGoBack', null);
  }

  Future<void> goBack() async {
    return _channel.invokeMethod('goBack', null);
  }

  Future<String> evaluateJavascript(String javascriptString) async {
    return await _channel.invokeMethod('evaluateJavascript', javascriptString);
  }
}
