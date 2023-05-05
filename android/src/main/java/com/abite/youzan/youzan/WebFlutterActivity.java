package com.abite.youzan.youzan;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.Nullable;

import com.tencent.smtt.export.external.interfaces.WebResourceResponse;
import com.tencent.smtt.sdk.ValueCallback;
import com.tencent.smtt.sdk.WebView;
import com.tencent.smtt.sdk.WebViewClient;
import com.youzan.androidsdk.event.AbsAuthEvent;
import com.youzan.androidsdk.event.AbsPaymentFinishedEvent;
import com.youzan.androidsdk.model.trade.TradePayFinishedModel;
import com.youzan.androidsdkx5.YouzanBrowser;

import org.json.JSONArray;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;


public class WebFlutterActivity extends Activity {
    private YouzanBrowser youzanBrowser;

    private static final String INTENT_MSG = "intent_msg";
    private static final String INTENT_ORDER_NO = "intent_order_no";
    private static final String ON_DESTROY = "onDestroy";
    private static final String URL = "url";

    private static final String PLUGIN_NOFITY = "plugin_nofity";
    private static final String LOGIN_INVOKE_METHOD = "login";
    private static final String PAYMENT_FINISHED_INVOKE_METHOD = "paymentFinished";
    private static final String EVALUATE_JAVASCRIPT_CALL = "evaluateJavascript";
    public static final String ROUTER_CHANGE = "router_change";
    public static final String SAVEADDRESS = "saveAddress";
    private String params;
    private String evaluateJavascript;
    List<JavascriptItem> jsList;
    private String webTitle;
    private String payType;
    private TextView titleView;
    private Context context;
    //用于判断提交订单时请求的URL
    private static final String PAY_ORDER_BILL = "pay/wsctrade/order/buy/v2/bill-fast.json";
    private Timer timer;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
            getWindow().setStatusBarColor(getResources().getColor(android.R.color.white));
        }
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_custom_web_view);
        getActionBar().hide();
        context = this;
        youzanBrowser = findViewById(R.id.web_view);
        titleView = findViewById(R.id.tv_title);

        paymentFinishedEvent();
        Intent intent = getIntent();
        params = intent.getStringExtra("webUrl");
        webTitle = intent.getStringExtra("webTitle");
        evaluateJavascript = intent.getStringExtra(EVALUATE_JAVASCRIPT_CALL);
        titleView.setText(webTitle);
        jsList = ToJsList(evaluateJavascript);
        authEvent();
        youzanBrowser.loadUrl(params);
        youzanBrowser.subscribe(new AbsAuthEvent() {
            @Override
            public void call(Context context, boolean needLogin) {
                sendBroadcast(new Intent(PLUGIN_NOFITY));
            }
        });
        youzanBrowser.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView webView, String s) {
                if (InterceptUrl(s)) {
                    return true;
                } else {
                    return super.shouldOverrideUrlLoading(webView, s);
                }
            }

            @Override
            public void onLoadResource(WebView webView, String url) {
                super.onLoadResource(webView, url);
            }

            @Override
            public WebResourceResponse shouldInterceptRequest(WebView webView, String url) {
                wxPayIntercept(url);
                return super.shouldInterceptRequest(webView, url);
            }

            @Override
            public void onPageFinished(WebView webView, String url) {
                loadCommand(url);
                super.onPageFinished(webView, url);
            }
        });

        findViewById(R.id.icon_back).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (youzanBrowser.canGoBack()) {
                    youzanBrowser.goBack();
                } else {
                    finish();
                }
            }
        });
    }

    void wxPayIntercept(String url) {
        /// 是否是微信支付判断
        if (url != null && url.contains("wx.tenpay.com")) {
            payType = "tenpay";
        }
        if (url != null && url.contains(PAY_ORDER_BILL)) {
            Intent notifyIntent = new Intent(PLUGIN_NOFITY);
            notifyIntent.putExtra(INTENT_MSG, ROUTER_CHANGE);
            sendBroadcast(notifyIntent);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if ("tenpay".equals(payType)) {
            if(timer != null){
                timer.cancel();
            }
            timer = new Timer();
            timer.schedule(new TimerTask() {
                @Override
                public void run() {
                    Intent intent = new Intent(context, WebFlutterActivity.class);
                    intent.putExtra("webUrl", params);
                    intent.putExtra(EVALUATE_JAVASCRIPT_CALL, evaluateJavascript);
                    intent.putExtra("webTitle", webTitle);
                    intent.putExtra("payFinishSubscribe", "NO");
                    startActivity(intent);
                    finish();
                }
            }, 600);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if(timer != null){
            timer.cancel();
        }
        Intent notifyIntent = new Intent(PLUGIN_NOFITY);
        notifyIntent.putExtra(INTENT_MSG, ON_DESTROY);
        notifyIntent.putExtra(URL, params);
        sendBroadcast(notifyIntent);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK && event.getRepeatCount() == 0) {
            if (youzanBrowser.canGoBack()) {
                youzanBrowser.goBack();
                return false;
            }
        }
        return super.onKeyDown(keyCode, event);
    }

    private void paymentFinishedEvent() {
        youzanBrowser.subscribe(new AbsPaymentFinishedEvent() {
            @Override
            public void call(Context context, TradePayFinishedModel tradePayFinishedModel) {
                Map<String, Object> map = new HashMap<>();
                map.put("tid", tradePayFinishedModel.getTid());
                map.put("status", tradePayFinishedModel.getStatus());
                map.put("payType", tradePayFinishedModel.getPayType());

                Intent notifyIntent = new Intent(PLUGIN_NOFITY);
                notifyIntent.putExtra(INTENT_MSG, PAYMENT_FINISHED_INVOKE_METHOD);
                notifyIntent.putExtra(INTENT_ORDER_NO, tradePayFinishedModel.getTid());
                sendBroadcast(notifyIntent);
                finish();
            }
        });
    }

    private void loadCommand(String url) {
        Iterator<JavascriptItem> it = jsList.iterator();
        while (it.hasNext()) {
            JavascriptItem javascriptItem = it.next();
            if (url != null && url.contains(javascriptItem.getUrl())) {
                if (youzanBrowser != null) {
                    String command = javascriptItem.getValue();
                    youzanBrowser.evaluateJavascript(command, new ValueCallback<String>() {
                        @Override
                        public void onReceiveValue(String s) {

                        }
                    });
                }
            }
        }
    }


    /***
     * @autor 容芳志
     * @param url
     * @return boolean
     * @描述 判断url是否需要跳转原生，比如订单详情页
     */
    boolean InterceptUrl(String url) {
        /// 新增地址拦截跳转
        if (params.contains("wsctrade/order/address/edit?redirect_url")) {
            if (url != null && url.contains("/wsctrade/order/address/list?switchable=false&address_id")) {
                Intent notifyIntent = new Intent(PLUGIN_NOFITY);
                notifyIntent.putExtra(INTENT_MSG, SAVEADDRESS);
                sendBroadcast(notifyIntent);
                finish();
                return false;
            }
        }

        return false;
    }


    /***
     * @autor 容芳志
     * @param
     * @return
     * @描述 注册登录回调事件
     */
    private void authEvent() {
        youzanBrowser.subscribe(new AbsAuthEvent() {
            @Override
            public void call(Context context, boolean needLogin) {
                if (needLogin) {
                    Intent notifyIntent = new Intent(PLUGIN_NOFITY);
                    notifyIntent.putExtra(INTENT_MSG, LOGIN_INVOKE_METHOD);
                    sendBroadcast(notifyIntent);
                }
            }
        });
    }

    List<JavascriptItem> ToJsList(String evaluateJavascript) {
        List<JavascriptItem> jsItemList = new ArrayList<JavascriptItem>();
        try {
            JSONArray jsJsonList = new JSONArray(evaluateJavascript);

            for (int j = 0; j < jsJsonList.length(); j++) {
                String url = jsJsonList.getJSONObject(j).getString("url");
                String value = jsJsonList.getJSONObject(j).getString("value");
                JavascriptItem javascriptItem = new JavascriptItem();
                javascriptItem.setUrl(url);
                javascriptItem.setValue(value);
                jsItemList.add(javascriptItem);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsItemList;
    }
}


class JavascriptItem {

    private String url;
    private String value;

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }
}

