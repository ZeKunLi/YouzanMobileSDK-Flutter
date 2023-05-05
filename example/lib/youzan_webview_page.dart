import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youzan/youzan.dart';
import 'package:youzan_example/common/constant.dart';

/// @ClassName:YouzanWebViewPage
///
/// @Description:有赞 WebView 页面
/// @author: 李泽昆
/// @date: 2021-12-02

class YouZanVebViewPage extends StatefulWidget {
  final String url;
  const YouZanVebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  _YouZanVebViewPageState createState() => _YouZanVebViewPageState();
}

class _YouZanVebViewPageState extends State<YouZanVebViewPage> {
  late YouzanWebViewController webViewController;
  final Youzan youzan = Youzan();
  String url = ''; // 默认传递的有赞 url

  @override
  void initState() {
    print("跳转的url====== ---${widget.url}");
    print("是否校验成功====== ---${Constant.youzanSecurityCheck}");
    if (Constant.youzanSecurityCheck == false) {
      youzan.securityCheck();
      youzan.addYouzanSecurityCheckSucceedCallBackListener((String result) {
        setState(() {
          Constant.youzanSecurityCheck = true;
        });
        print(
            "addYouzanSecurityCheckSucceedCallBackListener${Constant.youzanSecurityCheck}");
      });
      youzan.addYouzanSecurityCheckFailureCallBackListener((String result) {
        Constant.youzanSecurityCheck = false;
        print(
            "addYouzanSecurityCheckSucceedCallBackListener${Constant.youzanSecurityCheck}");
      });
    }
    setState(() {
      url = widget.url;
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    YouzanWebView webView = YouzanWebView(
      url: url,
      onCreated: onWebViewCreated,
    );

    return Center(
      child: !Constant.youzanSecurityCheck
          ? webView
          : Container(
              color: Colors.white,
            ),
    );
  }

  void onWebViewCreated(YouzanWebViewController viewPlayerController) {
    webViewController = viewPlayerController;
    webViewController.webViewMethodCall = webViewMethodCall;
  }

  Future<dynamic> webViewMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case "navigationRequest":
        print("是否应该请求 ---${methodCall.arguments}");
        return {'isRequest': true};
      case "login":
        print("收到登陆请求 ---${methodCall.arguments}");
        Youzan().login('666666',
            completion: (bool isSuccess, String? yzOpenId) {
          if (isSuccess) {
            print('---==========静默登录成功=========$yzOpenId');
            webViewController.reload();
          } else {
            print('---==========静默登录失败');
          }
        });
        break;
      case "share":
        print("收到分享的回调数据 ---${methodCall.arguments}");
        break;
      case "ready":
        print("Web页面已准备好 ---${methodCall.arguments}");
        String javascript =
            await webViewController.evaluateJavascript('document.title');
        print('获取页面 title========== $javascript');
        break;
      case "addToCart":
        print("加入购物车的时候调用 ---${methodCall.arguments}");
        break;
      case "buyNow":
        print("立即购买时调用 ---${methodCall.arguments}");
        break;
      case "paymentFinished":
        print("支付成功回调结果页 ---${methodCall.arguments}");
        break;
      case "authorizationSucceed":
        print("用户操作一键授权成功 ---${methodCall.arguments}");
        break;
      case "authorizationFailed":
        print("用户操作一键授权失败 ---${methodCall.arguments}");
        break;
    }
  }
}
