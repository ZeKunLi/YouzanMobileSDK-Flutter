//
//  YouzanWebViewController.m
//  youzan
//
//  Created by ZeKun Li on 2021/11/16.
//

#import "YouzanWebViewController.h"
#import <WebKit/WebKit.h>

@interface YouzanWebViewController () <YZWebViewDelegate, YZWebViewNoticeDelegate>
@property (nonatomic, strong) YZWebView *webView;
@end


@implementation YouzanWebViewController {
    int64_t _viewId;
    FlutterMethodChannel* _channel;
}

#pragma mark - life cycle
- (instancetype)initWithWithFrame:(CGRect)frame
                   viewIdentifier:(int64_t)viewId
                        arguments:(id _Nullable)args
                  binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    if ([super init]) {
        _viewId = viewId;
        YZWebViewType type = YZWebViewTypeWKWebView;
        _webView = [[YZWebView alloc] initWithWebViewType:type];;
        NSDictionary *dic = args;
        self.webView.delegate = self;
        self.webView.noticeDelegate = self;
        NSString* channelName = [NSString stringWithFormat:@"youzan_webview_%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        __weak __typeof__(self) weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
            [weakSelf onMethodCall:call result:result];
        }];
        [self loadWithString:dic[@"url"]];
        
    }
    return self;
}

- (nonnull UIView *)view {
    return _webView;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([[call method] isEqualToString:@"loadUrl"]) {
        [self onLoadUrl:call result:result];
    } else if ([[call method] isEqualToString:@"reload"]) {
        [self onReload:call result:result];
    } else if ([[call method] isEqualToString:@"canGoBack"]) {
      [self onCanGoBack:call result:result];
    } else if ([[call method] isEqualToString:@"goBack"]) {
        [self onGoBack:call result:result];
    } else if ([[call method] isEqualToString:@"evaluateJavascript"]) {
      [self onEvaluateJavaScript:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)onLoadUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* url = [call arguments];
    if (![self loadUrl:url]) {
        result([FlutterError errorWithCode:@"loadUrl_failed"
                                   message:@"Failed parsing the URL"
                                   details:[NSString stringWithFormat:@"URL was: '%@'", url]]);
    } else {
        result(nil);
    }
}

- (void)onReload:(FlutterMethodCall*)call result:(FlutterResult)result {
  [_webView reload];
  result(nil);
}

- (void)onCanGoBack:(FlutterMethodCall*)call result:(FlutterResult)result {
  BOOL canGoBack = [_webView canGoBack];
  result(@(canGoBack));
}

- (void)onGoBack:(FlutterMethodCall*)call result:(FlutterResult)result {
  [_webView goBack];
  result(nil);
}

- (void)onEvaluateJavaScript:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* jsString = [call arguments];
  if (!jsString) {
    result([FlutterError errorWithCode:@"evaluateJavaScript_failed"
                               message:@"JavaScript String cannot be null"
                               details:nil]);
    return;
  }
  [_webView evaluateJavaScript:jsString
             completionHandler:^(_Nullable id evaluateResult, NSError* _Nullable error) {
               if (error) {
                 result([FlutterError
                     errorWithCode:@"evaluateJavaScript_failed"
                           message:@"Failed evaluating JavaScript"
                           details:[NSString stringWithFormat:@"JavaScript string was: '%@'\n%@",
                                                              jsString, error]]);
               } else {
                 result([NSString stringWithFormat:@"%@", evaluateResult]);
               }
             }];
}


- (bool)loadUrl:(NSString*)url {
    NSURL* nsUrl = [NSURL URLWithString:url];
    if (!nsUrl) {
        return false;
    }
    [self loadWithString:url];
    return true;
}

- (void)loadWithString:(NSString *)urlStr {
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    if ([NSThread isMainThread]) {
        [self.webView loadRequest:urlRequest];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView loadRequest:urlRequest];
        });
    }
}

#pragma mark - YZWebViewDelegate

- (BOOL)webView:(id<YZWebView>)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(WKNavigationType)navigationType {
    __block BOOL end = NO;
    __block BOOL isRequest = YES;
    [_channel invokeMethod:@"navigationRequest" arguments:@{@"url" : webView.URL.absoluteString} result:^(id  _Nullable result) {
        isRequest = [result[@"isRequest"] boolValue];
        if (result[@"isRequest"] == NULL) {
            isRequest = YES;
        }
        end = YES;
    }];
    while (!end) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    return isRequest;
}

- (void)webViewDidStartLoad:(id<YZWebView>)webView {
    NSLog(@"webViewDidStartLoad:%@",webView);
    [_channel invokeMethod:@"onPageStarted" arguments:@{@"url" : webView.URL.absoluteString}];
}

- (void)webViewDidFinishLoad:(id<YZWebView>)webView {
    NSLog(@"webViewDidFinishLoad:%@",webView);
    [_channel invokeMethod:@"onPageFinished" arguments:@{@"url" : webView.URL.absoluteString}];
}

- (void)webView:(id<YZWebView>)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"didFailLoadWithError:%@",error);
    if([error code] == NSURLErrorCancelled)  {

           return;

           }
}
- (void)webViewWebContentProcessDidTerminate:(id<YZWebView>)webView {
    NSLog(@"webViewWebContentProcessDidTerminate:%@",webView);
}

#pragma mark - YZWebViewNoticeDelegate

- (void)webView:(YZWebView *)webView didReceiveNotice:(YZNotice *)notice
{
    NSLog(@"didReceiveNotice%@",notice);
    switch (notice.type) {
        case YZNoticeTypeLogin: // 收到登陆请求
        {
            [_channel invokeMethod:@"login" arguments:notice.response];
            break;
        }
        case YZNoticeTypeShare: // 收到分享的回调数据
        {
            [_channel invokeMethod:@"share" arguments:notice.response];
            break;
        }
        case YZNoticeTypeReady: // Web页面已准备好
        {
            // 此时可以分享，但注意此事件并不作为是否可分享的标志事件
            [_channel invokeMethod:@"ready" arguments:notice.response];
            NSLog(@"haha%@",[webView stringByEvaluatingJavaScriptFromString:@"document.title"]);
            break;
        }
        case YZNoticeTypeAddToCart: // 加入购物车的时候调用
        {
            [_channel invokeMethod:@"addToCart" arguments:notice.response];
            break;
        }
        case YZNoticeTypeBuyNow:    // 立即购买
        {
            [_channel invokeMethod:@"buyNow" arguments:notice.response];
            break;
        }
        case YZNoticeTypeAddUp:     // 购物车结算时调用
        {
            [_channel invokeMethod:@"buyNow" arguments:notice.response];
            break;
        }
        case YZNoticeTypePaymentFinished:   // 支付成功回调结果页
        {
            [_channel invokeMethod:@"paymentFinished" arguments:notice.response];
            break;
        }
        case YZNoticeTypeAuthorizationSucceed:   // 用户操作一键授权成功
        {
            [_channel invokeMethod:@"authorizationSucceed" arguments:notice.response];
            break;
        }
        case YZNoticeTypeAuthorizationFailed:   // 用户操作一键授权失败，response 中获取一键授权失败的 code 及 msg
        {
            [_channel invokeMethod:@"authorizationFailed" arguments:notice.response];
            break;
        }

        default:
            break;
    }
}

- (void)dealloc {
    _webView.delegate = nil;
    _webView.noticeDelegate = nil;
    _webView = nil;
}

@end
