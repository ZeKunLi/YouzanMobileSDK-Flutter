package com.abite.youzan.youzan;


import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class WebViewFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;

    public WebViewFactory(BinaryMessenger binaryMessenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = binaryMessenger;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        return new YouZanWebView(context, viewId, args, messenger);
    }
}