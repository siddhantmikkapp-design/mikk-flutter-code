import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikk/resources/loader.dart';

import 'package:mikk/utils/LogHelper.dart';
import 'package:mikk/values/Color.dart';
import 'package:provider/provider.dart';

import '../View_Model/FollowerFollowingViewModel.dart';
import '../View_Model/SettingsDetailViewModel/PersonalInformationViewModel.dart';


class AvatarViewerPage extends StatefulWidget {
  final String viewerUrl;
  final VoidCallback? onLoadComplete;

  const AvatarViewerPage({
    super.key,
    required this.viewerUrl,
    this.onLoadComplete,
  });

  @override
  State<AvatarViewerPage> createState() => _AvatarViewerPageState();
}

class _AvatarViewerPageState extends State<AvatarViewerPage> {
  late String viewerUrl;
  bool _hasError = false;
  bool _showWebView = false;
  bool _isWebViewLoaded = false;
  InAppWebViewController? webViewController;

  late PersonalInformationViewModel personalInfoVM;

  @override
  void initState() {
    super.initState();
    viewerUrl = widget.viewerUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        personalInfoVM = Provider.of<PersonalInformationViewModel>(context, listen: false);
        personalInfoVM.setLoading(true);
      }
    });

    // Delay WebView creation for smoother initial render
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showWebView = true;
        });
      }
    });
  }

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (viewerUrl.isEmpty || !_showWebView) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Consumer<PersonalInformationViewModel>(
      builder: (context, personalInfoVM, child) {
        return RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // WebView with optimized settings
              IgnorePointer(
                ignoring: false, // Allow WebView interactions
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    transparentBackground: true,

                    // Performance optimizations
                    cacheEnabled: true,
                    clearCache: false,
                    useHybridComposition: true, // Better Android performance
                    disableContextMenu: true,
                    supportZoom: false,
                    builtInZoomControls: false,
                    displayZoomControls: false,

                    // Disable scrolling in WebView (since we have draggable sheet)
                    disableHorizontalScroll: false,
                    disableVerticalScroll: false,

                    // Hardware acceleration
                    hardwareAcceleration: true,

                    // Reduce memory usage
                    minimumFontSize: 1,

                    // Disable features we don't need
                    safeBrowsingEnabled: false,
                    allowFileAccess: false,
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;

                    // Inject CSS to prevent WebView touch interference
                    controller.evaluateJavascript(source: """
                      (function() {
                        // Optimize rendering
                        document.body.style.webkitUserSelect = 'none';
                        document.body.style.webkitTouchCallout = 'none';
                        
                        // Prevent default touch behaviors that might interfere with drag
                        var style = document.createElement('style');
                        style.innerHTML = '* { -webkit-tap-highlight-color: transparent; }';
                        document.head.appendChild(style);
                      })();
                    """);

                    LogHelper("✅ WebView created");
                  },
                  onLoadStart: (controller, url) {
                    if (mounted) {
                      setState(() {
                        _isWebViewLoaded = false;
                      });
                    }
                    LogHelper("🔄 WebView loading started");
                  },
                  onLoadStop: (controller, url) async {
                    if (mounted) {
                      setState(() {
                        _hasError = false;
                        _isWebViewLoaded = true;
                      });

                      // Delay hiding loader for smoother experience
                      await Future.delayed(const Duration(milliseconds: 500));

                      if (mounted) {
                        personalInfoVM.setLoading(false);
                        widget.onLoadComplete?.call();
                      }
                    }
                    LogHelper("✅ WebView loaded successfully");
                  },
                  onLoadError: (controller, url, code, message) {
                    if (mounted) {
                      setState(() {
                        _hasError = true;
                        _isWebViewLoaded = false;
                      });
                      personalInfoVM.setLoading(false);
                    }
                    LogHelper("❌ WebView load error: $message");
                  },
                  onLoadHttpError: (controller, url, statusCode, description) {
                    if (mounted) {
                      setState(() {
                        _hasError = true;
                        _isWebViewLoaded = false;
                      });
                      personalInfoVM.setLoading(false);
                    }
                    LogHelper("❌ HTTP error: $statusCode - $description");
                  },
                  onProgressChanged: (controller, progress) {
                    // Optional: Show progress
                    if (progress == 100) {
                      LogHelper("✅ WebView progress: 100%");
                    }
                  },
                ),
              ),

              // Loading indicator
              if (personalInfoVM.isLoader || !_isWebViewLoaded)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Loader(),
                ),

              // Error state
              if (_hasError && !personalInfoVM.isLoader)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load avatar',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _hasError = false;
                                _showWebView = false;
                              });
                              personalInfoVM.setLoading(true);

                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) {
                                  setState(() {
                                    _showWebView = true;
                                  });
                                }
                              });
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}



/*class AvatarViewerPage extends StatefulWidget {
  final String viewerUrl;

  const AvatarViewerPage({
    super.key,
    required this.viewerUrl,
  });

  @override
  State<AvatarViewerPage> createState() => _AvatarViewerPageState();
}

class _AvatarViewerPageState extends State<AvatarViewerPage> {
  late String viewerUrl;
  bool _hasError = false;
  bool _showWebView = false;
  late InAppWebViewController webViewController;

  late PersonalInformationViewModel personalInfoVM;

  @override
  void initState() {
    super.initState();
    viewerUrl = widget.viewerUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      personalInfoVM = Provider.of<PersonalInformationViewModel>(context, listen: false);
      personalInfoVM.setLoading(true);
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWebView = true;
        });
      }
    });

    //  _scheduleReload();
  }

  *//*void _scheduleReload() {
    Timer(const Duration(seconds: 15), () {
      if (viewerUrl.isNotEmpty && webViewController != null) {
        webViewController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(viewerUrl)),
        );
      }
    });
  }*//*

  @override
  Widget build(BuildContext context) {
    return viewerUrl.isNotEmpty && _showWebView
        ? Consumer<PersonalInformationViewModel>(
        builder: (context, personalInfoVM, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    transparentBackground: true,
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                    personalInfoVM.setLoading(false);
                    LogHelper("✅ WebView loaded successfully onWebViewCreated");
                  },
                  onLoadStop: (controller, url) {
                    _hasError = false;
                    personalInfoVM.setLoading(false);
                    LogHelper("✅ WebView loaded successfully");
                  },
                  onLoadError: (controller, url, code, message) {
                    _hasError = true;
                    personalInfoVM.setLoading(false);
                    LogHelper("❌ WebView load error: $message");
                  },
                  onLoadHttpError: (controller, url, statusCode, description) {
                    _hasError = true;
                    personalInfoVM.setLoading(false);
                    LogHelper("❌ HTTP error: $statusCode - $description");
                  },
                ),
                personalInfoVM.isLoader ? Loader() : Container()
              ],
            );
          },
    )
        : Container(color: Colors.black);
  }
}*/

/*
class AvatarViewerPage extends StatefulWidget {
  // final String avatarUrl;
  final String viewerUrl;

  const AvatarViewerPage({
    super.key,
    required this.viewerUrl,
    // this.avatarUrl = "https://models.readyplayer.me/682e1240092177c0ba355fde.glb",
  });

  @override
  State<AvatarViewerPage> createState() => _AvatarViewerPageState();
}

class _AvatarViewerPageState extends State<AvatarViewerPage> {
  String viewerUrl = "";
  // double screenHeight = 0.0;
  // double screenWidth = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fillData();
  }

  fillData() {
    viewerUrl = widget.viewerUrl;
    //     Uri.encodeFull(
    //   'https://optimus-prime-cd.github.io/readyplayerme-viewer/?modelUrl=${widget.avatarUrl}',
    // );
    LogHelper("viewerUrl $viewerUrl");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // screenHeight = MediaQuery.of(context).size.height;
    // screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: blackColor,
      body: Container(
        // height: screenHeight.h,
        // width: screenWidth.w,
        color: Colors.transparent,
        child: viewerUrl.isNotEmpty
            ? InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                  ),
                ),
              )
            : Container(color: Colors.transparent),
      ),
    );
  }
}
*/
