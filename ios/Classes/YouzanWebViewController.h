//
//  YouzanWebViewController.h
//  youzan
//
//  Created by ZeKun Li on 2021/11/16.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <YZBaseSDK/YZBaseSDK.h>
NS_ASSUME_NONNULL_BEGIN

@interface YouzanWebViewController : UIViewController <FlutterPlatformView>

- (instancetype)initWithWithFrame:(CGRect)frame
                   viewIdentifier:(int64_t)viewId
                        arguments:(id _Nullable)args
                  binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

@end

NS_ASSUME_NONNULL_END
