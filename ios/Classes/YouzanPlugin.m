#import "YouzanPlugin.h"
#import "WebViewFactory.h"
#import <YZBaseSDK/YZBaseSDK.h>

static NSString *const SCHEME = @"ayouzan";/**< demo 的 scheme */

@interface YouzanPlugin () <YZSDKDelegate>
@property FlutterMethodChannel *channel;
@end

@implementation YouzanPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"youzan"
                                     binaryMessenger:[registrar messenger]];
    YouzanPlugin* instance = [[YouzanPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
    WebViewFactory* factory =[[WebViewFactory alloc] initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:factory withId:@"plugins.youzan_web_view/view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initializeSDK" isEqualToString:call.method]) {
        // 初始化sdk
        YZConfig *config = [[YZConfig alloc] initWithClientId:call.arguments[@"clientId"] andAppKey:call.arguments[@"appKey"]];
        config.enableLog = YES; // 关闭 sdk 的 log 输出
        config.scheme = SCHEME; // 配置 scheme 以便微信支付完成后跳转
        [YZSDK.shared initializeSDKWithConfig:config];
        YZSDK.shared.delegate = self; // 必须设置代理方法，保证 SDK 在需要 token 的时候可以正常运行
    } else if([@"login" isEqualToString:call.method]) {
        [YZSDK.shared loginWithOpenUserId:call.arguments[@"openUserId"] avatar:call.arguments[@"openUserId"] extra:call.arguments[@"extra"] nickName:call.arguments[@"nickName"] gender:[call.arguments[@"gender"] intValue] andCompletion:^(BOOL isSuccess, NSString * _Nullable yzOpenId) {
            result(@{@"isSuccess":[NSNumber numberWithBool:isSuccess],@"yzOpenId":yzOpenId!= NULL ? yzOpenId : [NSNull null]});
        }];
    } else if([@"logout" isEqualToString:call.method]) {
        [YZSDK.shared logoutWithCompletion:^{
            result([NSNumber numberWithBool:YES]);
        }];
    } else if([@"securityCheck" isEqualToString:call.method]) {
        [YZSDK.shared securityCheck];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)yzsdkSecurityCheckFaild:(YZSDK *)sdk {
    [self.channel invokeMethod:@"youzanSecurityCheckFailure" arguments:nil];
    NSLog(@"yzsdkSecurityCheckFaild%ld",sdk.connectState);
}

- (void)yzsdkSecurityCheckSucceed:(YZSDK *)sdk {
    [self.channel invokeMethod:@"youzanSecurityCheckSucceed" arguments:nil];
    NSLog(@"yzsdkSecurityCheckSucceed%ld",sdk.connectState);
}

@end

