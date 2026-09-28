import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AvatarCreatorPage extends StatefulWidget {
  @override
  State<AvatarCreatorPage> createState() => _AvatarCreatorPageState();
}

class _AvatarCreatorPageState extends State<AvatarCreatorPage> {
  InAppWebViewController? webViewController;
  String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Avatar")),
      body: Column(
        children: [
          if (avatarUrl != null) ...[
            Text("✅ Avatar Created!"),
            SizedBox(height: 8),
            Image.network(avatarUrl!),
            SelectableText(avatarUrl!),
          ],
          Expanded(
            child: InAppWebView(
              initialFile: "assets/avatar_creator.html",
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                ),
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onConsoleMessage: (controller, consoleMessage) {
                try {
                  final text = consoleMessage.message;
                  if (text.contains("Avatar URL:")) {
                    final url = text.split("Avatar URL:")[1].trim();
                    setState(() {
                      avatarUrl = url;
                    });
                    print('🚀 avatar created: success');



                    
                  }
                } catch (_) {}



              },
            ),
          ),
        ],
      ),
    );
  }
}





/*class AvatarCreatorPage extends StatefulWidget {
  @override
  State<AvatarCreatorPage> createState() => _AvatarCreatorPageState();
}

class _AvatarCreatorPageState extends State<AvatarCreatorPage> {
  final AppLinks _appLinks = AppLinks();
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _startListeningForDeepLinks();
    _openReadyPlayerMe();
  }

  void _startListeningForDeepLinks() async {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.scheme == 'myapp' && uri.host == 'avatar') {
        final url = uri.queryParameters['url'];
        if (url != null) {
          setState(() {
            avatarUrl = url;
          });
        }
      }
    });
  }

  Future<void> _openReadyPlayerMe() async {
    final redirectUri = Uri.encodeComponent("myapp://avatar");
    final avatarCreatorUrl =
        "https://mikkapp.readyplayer.me/avatar?frameApi&redirectUrl=$redirectUri";

    final uri = Uri.parse(avatarCreatorUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Could not launch creator.")));
    }
  }*/

/*  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Avatar")),
      body: Center(
        child: avatarUrl == null
            ? Text("Waiting for avatar redirect...")
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("✅ Avatar Created!"),
            SizedBox(height: 16),
            Image.network(avatarUrl!),
            SizedBox(height: 8),
            SelectableText(avatarUrl!),
          ],
        ),
      ),
    );
  }
}*/
