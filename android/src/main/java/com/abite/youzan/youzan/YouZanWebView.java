package com.abite.youzan.youzan;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;

import com.tencent.smtt.export.external.interfaces.WebResourceResponse;
import com.tencent.smtt.sdk.ValueCallback;
import com.tencent.smtt.sdk.WebView;
import com.tencent.smtt.sdk.WebViewClient;
import com.youzan.androidsdk.event.AbsAddToCartEvent;
import com.youzan.androidsdk.event.AbsAuthEvent;
import com.youzan.androidsdk.event.AbsBuyNowEvent;
import com.youzan.androidsdk.event.AbsPaymentFinishedEvent;
import com.youzan.androidsdk.event.AbsShareEvent;
import com.youzan.androidsdk.model.goods.GoodsOfCartModel;
import com.youzan.androidsdk.model.goods.GoodsShareModel;
import com.youzan.androidsdk.model.trade.TradePayFinishedModel;
import com.youzan.androidsdkx5.YouzanBrowser;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class YouZanWebView implements PlatformView, MethodChannel.MethodCallHandler {
    private YouzanBrowser youzanBrowser;
    private final MethodChannel methodChannel;
    private final View view;

    private static final String LOGIN_INVOKE_METHOD = "login";
    private static final String SHARE_INVOKE_METHOD = "share";
    private static final String READY_INVOKE_METHOD = "ready";
    private static final String ADD_TO_CART_INVOKE_METHOD = "addToCart";
    private static final String BUY_NOW_INVOKE_METHOD = "buyNow";
    private static final String PAYMENT_FINISHED_INVOKE_METHOD = "paymentFinished";
    private static final String LOAD_URL_METHOD_CALL = "loadUrl";
    private static final String EVALUATE_JAVASCRIPT_CALL = "evaluateJavascript";

    YouZanWebView(Context context, int viewId, Object args, BinaryMessenger messenger) {
        this.view = getYouZanBrowser(context, args);
        this.methodChannel = new MethodChannel(messenger, "youzan_webview_" + viewId);
        this.methodChannel.setMethodCallHandler(this);
        authEvent();
        shareEvent();
        addToCartEvent();
        buyNowEvent();
        paymentFinishedEvent();
        youzanBrowser.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView webView, String s) {
                return super.shouldOverrideUrlLoading(webView, s);
            }

            @Override
            public void onLoadResource(com.tencent.smtt.sdk.WebView webView, String url) {
                super.onLoadResource(webView, url);
            }

            @Override
            public WebResourceResponse shouldInterceptRequest(com.tencent.smtt.sdk.WebView webView, String url) {
                return super.shouldInterceptRequest(webView, url);
            }

            @Override
            public void onPageFinished(com.tencent.smtt.sdk.WebView webView, String url) {
                super.onPageFinished(webView, url);
                methodChannel.invokeMethod(READY_INVOKE_METHOD, null);
            }
        });
    }

    private void paymentFinishedEvent() {
        youzanBrowser.subscribe(new AbsPaymentFinishedEvent() {
            @Override
            public void call(Context context, TradePayFinishedModel tradePayFinishedModel) {
                Map<String, Object> map = new HashMap<>();
                map.put("tid", tradePayFinishedModel.getTid());
                map.put("status", tradePayFinishedModel.getStatus());
                map.put("payType", tradePayFinishedModel.getPayType());
                methodChannel.invokeMethod(PAYMENT_FINISHED_INVOKE_METHOD, map);
            }
        });
    }

    private void buyNowEvent() {
        youzanBrowser.subscribe(new AbsBuyNowEvent() {
            @Override
            public void call(Context context, GoodsOfCartModel goodsOfCartModel) {
                methodChannel.invokeMethod(BUY_NOW_INVOKE_METHOD, goodsOfCartModelToMap(goodsOfCartModel));
            }
        });
    }

    private void addToCartEvent() {
        youzanBrowser.subscribe(new AbsAddToCartEvent() {
            @Override
            public void call(Context context, GoodsOfCartModel goodsOfCartModel) {
                methodChannel.invokeMethod(ADD_TO_CART_INVOKE_METHOD, goodsOfCartModelToMap(goodsOfCartModel));
            }
        });
    }

    private void shareEvent() {
        youzanBrowser.subscribe(new AbsShareEvent() {
            @Override
            public void call(Context context, GoodsShareModel goodsShareModel) {
                Map<String, Object> map = new HashMap<>();
                map.put("title", goodsShareModel.getTitle());
                map.put("link", goodsShareModel.getLink());
                map.put("imgUrl", goodsShareModel.getImgUrl());
                map.put("desc", goodsShareModel.getDesc());
                map.put("imgWidth", goodsShareModel.getImgWidth());
                map.put("imgHeight", goodsShareModel.getImgHeight());
                map.put("timeLineTitle", goodsShareModel.getTimeLineTitle());
                methodChannel.invokeMethod(SHARE_INVOKE_METHOD, map);
            }
        });
    }

    private void authEvent() {
        youzanBrowser.subscribe(new AbsAuthEvent() {
            @Override
            public void call(Context context, boolean needLogin) {
                if (needLogin) {
                    methodChannel.invokeMethod(LOGIN_INVOKE_METHOD, null);
                }
            }
        });
    }

    @Override
    public View getView() {
        return view;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case LOAD_URL_METHOD_CALL:
                String url = methodCall.arguments.toString();
                youzanBrowser.loadUrl(url);
                break;
            case EVALUATE_JAVASCRIPT_CALL:
                if (youzanBrowser != null) {
                    String command = methodCall.arguments.toString();
                    youzanBrowser.evaluateJavascript(command, new ValueCallback<String>() {
                        @Override
                        public void onReceiveValue(String s) {
                            result.success(s);
                        }
                    });
                }
                break;
            default:
                result.notImplemented();
        }

    }

    private Map<String, Object> goodsOfCartModelToMap(GoodsOfCartModel goodsOfCartModel) {
        if (goodsOfCartModel == null) {
            return null;
        }
        Map<String, Object> map = new HashMap<>();
        map.put("itemId", goodsOfCartModel.getItemId());
        map.put("skuId", goodsOfCartModel.getSkuId());
        map.put("alias", goodsOfCartModel.getAlias());
        map.put("title", goodsOfCartModel.getTitle());
        map.put("num", goodsOfCartModel.getNum());
        map.put("payPrice", goodsOfCartModel.getPayPrice());
        return map;
    }

    private View getYouZanBrowser(Context context, Object args) {
        View view = LayoutInflater.from(context).inflate(R.layout.layout_web_view, null);
        this.youzanBrowser = view.findViewById(R.id.web_view);
        Map<String, Object> arguments = (Map<String, Object>) args;
        youzanBrowser.loadUrl((String) arguments.get("url"));
        return view;
    }

    @Override
    public void dispose() {

    }
}
