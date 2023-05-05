import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:youzan/youzan.dart';
import 'common/constant.dart';
import 'main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Youzan youzan = Youzan();

  @override
  void initState() {
    super.initState();
    initializeSDK();
  }

  /// https://diy.youzanyun.com/application/open/plugins/appsdk/safe
  initializeSDK()  {
    youzan.initializeSDK(
        "39d095b4054ca530f9",
        Platform.isAndroid
            ? "46de4c9073c94d5aa3d317166b81e2f0"
            : "02ba02c6f3df4f729d9d105c1144fe83");
    youzan.addYouzanSecurityCheckSucceedCallBackListener((String result) {
      Constant.youzanSecurityCheck = true;
      print(
          "addYouzanSecurityCheckSucceedCallBackListener${Constant.youzanSecurityCheck}");
    });
    youzan.addYouzanSecurityCheckFailureCallBackListener((String result) {
      Constant.youzanSecurityCheck = false;
      print(
          "addYouzanSecurityCheckSucceedCallBackListener${Constant.youzanSecurityCheck}");
    });
    print(Constant.youzanSecurityCheck);
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainPage(),
    );
  }
}
