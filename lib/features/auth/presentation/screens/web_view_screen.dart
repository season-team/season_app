import 'package:flutter/material.dart';

class WebViewScreen extends StatelessWidget {
  final String title;
  final String url;

  const WebViewScreen({super.key, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      // body: SafeArea(
      //   // child: WebViewWidget(
      //   //   controller: WebViewController()
      //   //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
      //   //     ..loadRequest(Uri.parse(url)),
      //   ),
      // ),
    );
  }
}
