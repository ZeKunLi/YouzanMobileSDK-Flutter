import 'package:flutter/material.dart';
import 'package:youzan/youzan.dart';
import 'package:youzan_example/youzan_webview_page.dart';

/// @ClassName: MainPage
///
/// @Description: 主页面
/// @author: 李泽昆
/// @date: 2021-12-02

class MainPage extends StatefulWidget {

  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late YouzanWebViewController webViewController;
  // https://cashier.youzan.com/pay/wsctrade_buy?kdt_id=&book_key=2021120410015561aacc13acf7930927
  String jumpUrl =
      // "https://h5.youzan.com/v2/showcase/homepage?alias=xUTE3DNiZp";
     "https://shop101622017.youzan.com/wsctrade/order/address/list?switchable=false&kdt_id=101429849";
  // "https://shop101619445.m.youzan.com/v2/showcase/homepage?kdt_id=101427277";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Youzan Plugin example"),
        leading: GestureDetector(
          child: const Center(
            child: Text(
              "退出登录",
            ),
          ),
          onTap: () async {
            Youzan().logout();
          },
        ),
        actions: [
          GestureDetector(
            child: const Center(
              child: Text(
                "登录",
              ),
            ),
            onTap: () async {
              Youzan().login("55555", nickName: "yummy",
                  completion: (bool isSuccess, String? yzOpenId) {
                    if (!isSuccess) {
                      print("登录失败");
                    } else {
                      print("登录成功，有赞登录接口返回的 yz_open_id = $yzOpenId");
                    }
                  });
            },
          ),
        ],
      ),
      body: Center(
          child: RaisedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return YouZanVebViewPage(
                    url: jumpUrl,
                  );
                }),
              );
            },
            child: Text("点击跳转"),
          )),
    );
  }
}