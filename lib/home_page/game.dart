import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GamePage extends StatefulWidget {
  String gameLink;
   GamePage({super.key, required this.gameLink});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  WebViewController controller = WebViewController();
  int loadingBar = 0;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
           onProgress: (int progress) {
            setState(() {
              loadingBar = progress;
            });
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
          Uri.parse(widget.gameLink));
  }


  @override
  Widget build(BuildContext context) {

    return
      loadingBar < 100
          ? const Center(child: CircularProgressIndicator())
          :
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: WebViewWidget(controller: controller),
      );
  }
}
