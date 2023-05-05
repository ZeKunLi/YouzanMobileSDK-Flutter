//
//  WebViewFactory.m
//  youzan
//
//  Created by ZeKun Li on 2021/11/16.
//

#import "WebViewFactory.h"
#import "YouzanWebViewController.h"


@implementation WebViewFactory {
    NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                            viewIdentifier:(int64_t)viewId
                                                 arguments:(id _Nullable)args {
    YouzanWebViewController* viewController =
    [[YouzanWebViewController alloc] initWithWithFrame:frame
                                        viewIdentifier:viewId
                                             arguments:args
                                       binaryMessenger:_messenger];
    return viewController;
}

@end
