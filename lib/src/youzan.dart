import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// @ClassName:Youzan
///
/// @Description: 有赞云 AppSDK 通用信息管理。以及 cookie 和 token 的设置。
/// @author: 李泽昆
/// @date: 2021-11-16

// 有赞通用回调监听
typedef YouzanCallBackListener = void Function(String result);


class YouzanEventHandlers {
  static final YouzanEventHandlers _instance = YouzanEventHandlers._internal();

  YouzanEventHandlers._internal();

  factory YouzanEventHandlers() => _instance;

  YouzanCallBackListener? youzanSecurityCheckSucceedCallBackListener;
  YouzanCallBackListener? youzanSecurityCheckFailureCallBackListener;
  YouzanCallBackListener? youzanAndroidLoginCallBackListener;
  YouzanCallBackListener? youzanAndroidPayFinishCallBackListener;
  YouzanCallBackListener? youzanAndroidSaveAddressCallBackListener;
  YouzanCallBackListener? youzanAndroidOnDestoryCallBackListener;
  YouzanCallBackListener? youzanAndroidRouterChageCallBackListener;
}

class Youzan {
  factory Youzan() => _instance;

  final MethodChannel _channel;

  final YouzanEventHandlers _eventHanders = YouzanEventHandlers();

  @visibleForTesting
  Youzan.private(MethodChannel channel) : _channel = channel;

  static final _instance = Youzan.private(const MethodChannel("youzan"));

  /// 有赞安全校验成功通知
  addYouzanSecurityCheckSucceedCallBackListener(YouzanCallBackListener callback) {
    _eventHanders.youzanSecurityCheckSucceedCallBackListener = callback;
  }

  /// 有赞安全校验失败通知
  addYouzanSecurityCheckFailureCallBackListener(YouzanCallBackListener callback) {
    _eventHanders.youzanSecurityCheckFailureCallBackListener = callback;
  }

  /// 有赞安卓登录回调
  addYouzanAndroidLoginCallBackListener(YouzanCallBackListener callback) {
    _eventHanders.youzanAndroidLoginCallBackListener = callback;
  }

  /// 有赞安卓支付完成回调
  addYouzanAndroidPayFinishCallBackListener(YouzanCallBackListener callback) {
    _eventHanders.youzanAndroidPayFinishCallBackListener = callback;
  }

  /// 有赞安卓保存地址回调
  addYouzanAndroidSaveAddressCallBackListener(YouzanCallBackListener callback) {
    _eventHanders.youzanAndroidSaveAddressCallBackListener = callback;
  }

  /// 有赞安卓正在被销毁地址回调
  addYouzanAndroidOnDestroyCallBackListener(YouzanCallBackListener callback) {
    _eventHanders.youzanAndroidOnDestoryCallBackListener = callback;
  }

  addYouzanAndroidRouterChangeCallBackListener(YouzanCallBackListener callback){
    _eventHanders.youzanAndroidRouterChageCallBackListener = callback;
  }

  /// 初始化 SDK
  ///
  /// [clientId] 必传，从有赞云申请的 clientId
  /// [appKey] 必传，从有赞云申请的 appKey
  void initializeSDK(String clientId, String appKey) async {
    _channel.setMethodCallHandler(_handlerMethod);
    _channel.invokeMethod(
        'initializeSDK', {"clientId": clientId, "appKey": appKey});
  }

  /// 用户登录
  ///
  /// [openUserId] 必传，开发者自身系统的用户ID，是三方App账号在有赞的唯一标识符，如更换将导致原用户数据丢失
  /// [avatar] 非必传，用户头像，建议传https的url
  /// [extra] 非必传，用户的额外信息
  /// [nickName] 非必传，用户昵称
  /// [gender] 非必传，性别 0(保密)、1(男)、2(女)
  /// [completion] 将返回 [isSuccess] 登录是否成功，[yzOpenId] 成功后返回的有赞openId
  Future login(String openUserId,
      {String? avatar,
        String? extra,
        String? nickName,
        int? gender,
        required Function(bool isSuccess, String? yzOpenId) completion}) async {
    final Map result = await _channel.invokeMethod('login', {
      "openUserId": openUserId,
      "avatar": avatar ?? "",
      "extra": extra ?? "",
      "nickName": nickName ?? "",
      "gender": gender ?? 0,
    });
    completion(result['isSuccess'], result['yzOpenId']);
  }

  Future jumpNative(String webUrl,String evaluateJavascript,String webTitle) async {
    final Map result = await _channel.invokeMethod('JumpActivity', {
      "webUrl": webUrl,
      "evaluateJavascript": evaluateJavascript,
      "webTitle": webTitle
    });
    return result;
  }

  /// App用户登出，清除token及cookie等
  ///
  /// [completion] 清除token的成功回调，一般推荐在[completion]里执行webview的刷新操作
  Future logout({Function? completion}) async {
    final bool logout = await _channel.invokeMethod('logout');
    if (completion != null) {
      completion();
    }
    return logout;
  }

  /// 重试安全校验
  securityCheck() {
    _channel.invokeMethod('securityCheck');
  }

  Future<void> _handlerMethod(MethodCall call) async {
    // print("handleMethod method&arg = ${call.method} + ${call.arguments}");

    switch (call.method) {
      case 'youzanSecurityCheckSucceed':
        {
          if (_eventHanders.youzanSecurityCheckSucceedCallBackListener !=
              null) {
            _eventHanders.youzanSecurityCheckSucceedCallBackListener!(call.arguments);
          }
        }
        break;
      case 'youzanSecurityCheckFailure':
        {
          if (_eventHanders.youzanSecurityCheckFailureCallBackListener !=
              null) {
            _eventHanders.youzanSecurityCheckFailureCallBackListener!(call.arguments);
          }
        }
        break;
      case 'login':
        {
          if (_eventHanders.youzanAndroidLoginCallBackListener !=
              null) {
            _eventHanders.youzanAndroidLoginCallBackListener!(call.arguments);
          }
        }
        break;
      case 'paymentFinished':
        {
          if (_eventHanders.youzanAndroidPayFinishCallBackListener !=
              null) {
            _eventHanders.youzanAndroidPayFinishCallBackListener!(call.arguments);
          }
        }
        break;
      case 'saveAddress':
        {
          if (_eventHanders.youzanAndroidSaveAddressCallBackListener !=
              null) {
            _eventHanders.youzanAndroidSaveAddressCallBackListener!('save');
          }
        }
        break;
      case 'onDestroy':
        {
          if (_eventHanders.youzanAndroidOnDestoryCallBackListener !=
              null) {
            _eventHanders.youzanAndroidOnDestoryCallBackListener!(call.arguments);
          }
        }
        break;
      case 'routerChange':
        {
          if (_eventHanders.youzanAndroidRouterChageCallBackListener !=
              null) {
            _eventHanders.youzanAndroidRouterChageCallBackListener!("pay");
          }
        }
        break;
      default:
        throw UnsupportedError("Unrecognized Event");
    }
    return;
  }
}
