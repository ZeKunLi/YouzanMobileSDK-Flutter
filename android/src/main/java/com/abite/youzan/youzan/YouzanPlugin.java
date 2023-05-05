package com.abite.youzan.youzan;

import static com.abite.youzan.youzan.WebFlutterActivity.ROUTER_CHANGE;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.youzan.androidsdk.YouzanSDK;
import com.youzan.androidsdk.YouzanToken;
import com.youzan.androidsdk.YzLoginCallback;
import com.youzan.androidsdkx5.YouZanSDKX5Adapter;
import com.youzan.androidsdkx5.YouzanBrowser;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * @Description:
 * @Author: xingguo.lei@abite.tech
 * @Date: 2021/11/17 13:07
 */
@SuppressWarnings("PMD")
public class YouzanPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private static final String INITIALIZE_SDK = "initializeSDK";
    //登录成功回调
    private static final String LOGIN = "login";
    //通知登录回调
    private static final String LOGOUT = "logout";
    private static final String INIT_CALL_SUCCESS = "youzanSecurityCheckSucceed";
    private static final String INIT_CALL_FAIL = "youzanSecurityCheckFailure";
    private static final String SECURITY_CHECK = "securityCheck";
    private static final String JUMP_ACTIVITY = "JumpActivity";

    private static final String PLUGIN_NOFITY = "plugin_nofity";

    private static final String LOGIN_INVOKE_METHOD = "login";
    private static final String PAYMENT_FINISHED_INVOKE_METHOD = "paymentFinished";
    private static final String SAVEADDRESS = "saveAddress";
    private static final String ON_DESTROY = "onDestroy";
    private static final String URL = "url";
    private static final String EVALUATE_JAVASCRIPT_CALL = "evaluateJavascript";

    private static final String INTENT_MSG = "intent_msg";
    private static final String INTENT_ORDER_NO = "intent_order_no";


    private YzLoginReceiver yBroadCastReceiver;
    private MethodChannel channel;
    private Context context;
    private Handler handler;
    private String clientId;
    private String appKey;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        handler = new Handler();
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "youzan");
        channel.setMethodCallHandler(this);
        binding.getPlatformViewRegistry()
                .registerViewFactory("plugins.youzan_web_view/view",
                        new WebViewFactory(binding.getBinaryMessenger()));

        yBroadCastReceiver = new YzLoginReceiver();
        //实例化过滤器并设置要过滤的广播
        IntentFilter intentFilter = new IntentFilter(PLUGIN_NOFITY);
        //注册广播
        context.registerReceiver(yBroadCastReceiver, intentFilter);
    }

    public class YzLoginReceiver extends BroadcastReceiver {
        private static final String TAG = "yzLoginReceiver";

        @Override
        public void onReceive(Context context, Intent intent) {
            String intentMethod = intent.getStringExtra(INTENT_MSG);
            String orderNo = intent.getStringExtra(INTENT_ORDER_NO);
            String url = intent.getStringExtra(URL);
            if (LOGIN_INVOKE_METHOD.equals(intentMethod)) {
                channel.invokeMethod(LOGIN_INVOKE_METHOD, null);
            } else if (PAYMENT_FINISHED_INVOKE_METHOD.equals(intentMethod)) {
                channel.invokeMethod(PAYMENT_FINISHED_INVOKE_METHOD, orderNo);
            } else if (SAVEADDRESS.equals(intentMethod)) {
                channel.invokeMethod(SAVEADDRESS, null);
            } else if (ROUTER_CHANGE.equals(intentMethod)) {
                channel.invokeMethod("routerChange", null);
            } else if (ON_DESTROY.equals(intentMethod)) {
                channel.invokeMethod(ON_DESTROY, url);
            }
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        handler.removeMessages(0);
        context.unregisterReceiver(yBroadCastReceiver);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case INITIALIZE_SDK:
                Map<String, String> map = call.arguments();
                this.clientId = map.get("clientId");
                this.appKey = map.get("appKey");
                init();
                break;
            case LOGIN:
                login(call, result);
                break;
            case LOGOUT:
                logout(result);
                break;
            case SECURITY_CHECK:
                init();
                break;
            case JUMP_ACTIVITY:
                Intent intent = new Intent(context, WebFlutterActivity.class);
                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                Map<String, String> map_url = call.arguments();
                String webUrl = map_url.get("webUrl");
                String webTitle = map_url.get("webTitle");
                String evaluateJavascript = map_url.get(EVALUATE_JAVASCRIPT_CALL);

                intent.putExtra("webUrl", webUrl);
                intent.putExtra(EVALUATE_JAVASCRIPT_CALL, evaluateJavascript);
                intent.putExtra("webTitle", webTitle);
                context.startActivity(intent);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void init() {
        handler.removeMessages(0);
        new Thread(() -> initializeSDK(0)).start();
    }

    private void initializeSDK(int index) {
        index++;
        if (YouzanSDK.isReady()) {
            new Handler(Looper.getMainLooper()).post(() -> channel.invokeMethod(INIT_CALL_SUCCESS, null));
        } else {
            int finalIndex = index;
            YouzanSDK.init(context, clientId, appKey, new YouZanSDKX5Adapter());
            YouzanSDK.isDebug(false);
            handler.postDelayed(() -> {
                if (finalIndex >= 3) {
                    new Handler(Looper.getMainLooper()).post(() -> channel.invokeMethod(INIT_CALL_FAIL, null));
                } else {
                    initializeSDK(finalIndex);
                }
            }, 2000);
        }
    }

    private void login(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> map = call.arguments();
        String openUserId = String.valueOf(map.get("openUserId"));
        String avatar = String.valueOf(map.get("avatar"));
        String extra = String.valueOf(map.get("extra"));
        String nickName = String.valueOf(map.get("nickName"));
        String gender = String.valueOf(map.get("gender"));
        if (TextUtils.isEmpty(openUserId)) {
            result.error("-1", "openUserId 不能为空", "");
            return;
        }
        avatar = checkNull(avatar);
        extra = checkNull(extra);
        nickName = checkNull(nickName);
        gender = checkNull(gender);
        YouzanSDK.yzlogin(openUserId, avatar, extra, nickName, gender, new YzLoginCallback() {
            @Override
            public void onSuccess(YouzanToken youzanToken) {
                Map<String, Object> map = new HashMap<>();
                map.put("isSuccess", true);
                map.put("yzOpenId", youzanToken.getYzOpenId());
                new Handler(Looper.getMainLooper()).post(() -> {
                    YouzanBrowser youzanBrowser = new YouzanBrowser(context);
                    youzanBrowser.sync(youzanToken);
                    result.success(map);
                });
            }

            @Override
            public void onFail(String s) {
                new Handler(Looper.getMainLooper()).post(() -> result.error("0", s, ""));
            }
        });
    }

    private String checkNull(String argument) {
        return argument == null ? "" : argument;
    }

    private void logout(MethodChannel.Result result) {
        YouzanSDK.userLogout(context);
        result.success(true);
    }
}
