import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AvatarView extends StatefulWidget {
  final Color? color;
  final Function(dynamic isLoader) loading;
  const AvatarView({super.key,this.color, required this.loading});

  @override
  State<AvatarView> createState() => _AvatarViewState();
}





class _AvatarViewState extends State<AvatarView> {
  double screenHeight = 0.0;
  double screenWidth = 0.0;
  late final WebViewController _controller;
  final String postername = "your_poster_url_here";
  final String user = "https://models.readyplayer.me/6813614e7d3bdc863ca281a6.glb";
  bool _hasError = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
            onPageFinished: (String url) {
              widget.loading(false);
              setState(() {
                _hasError = false;
              });

              _injectJavaScript();
            },
            onWebResourceError: (WebResourceError error){
              widget.loading(false);
              setState(() {
                _hasError = true;
              });
              debugPrint("WebView Error: ${error.description}");

            }


        ),
      );

    _loadWebView();
    // ..loadFlutterAsset('assets/AvatarView.html');

  }




  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        height: screenHeight.h,
        width: screenWidth.w,
        child: _hasError
            ? _buildErrorView()
            :WebViewWidget(controller: _controller),
      ),
    );
  }

  avatarLatest() async {
    await _controller.runJavaScript(
      'GetPoster("$postername"); GetSource("$user");',
    );
  }

  Future<void> _injectJavaScript() async {
    await _controller.runJavaScript(
      'GetPoster("$postername"); GetSource("$user");',
    );
  }

  void _loadWebView() {
    widget.loading(true);
    _controller.loadFlutterAsset('assets/AvatarView.html');
  }

  Widget  _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text("Failed to load the viewer.", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
              });
              _loadWebView(); // retry
            },
            child: Text("Retry"),
          ),
        ],
      ),
    );



  }

}
