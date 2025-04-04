import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WebView extends StatefulWidget {
  final String websiteLink;
  final String title;
  const WebView({
    super.key, 
    required this.websiteLink,
    required this.title,
  });

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  InAppWebViewController? webViewController;
  final GlobalKey webViewKey = GlobalKey();
  double progress = 0.0;
  String currentUrl = '';
  bool _isLoading = true;
  final FocusNode _focusNode = FocusNode();
  Timer? _inactivityTimer;

  // WebView options
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      supportZoom: true,
      transparentBackground: false,
      disableContextMenu: true,
      javaScriptEnabled: true,
      cacheEnabled: true,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
      builtInZoomControls: false, // Disabled for TV
      mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      useWideViewPort: true,
      loadWithOverviewMode: true,
      domStorageEnabled: true,
      databaseEnabled: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
      disallowOverScroll: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    webViewController?.stopLoading();
    _focusNode.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 20), () {
      // Prevent screen timeout by reloading
      webViewController?.reload();
    });
  }

  // Handle TV remote control
  void _handleKeyEvent(RawKeyEvent event) {
    _resetInactivityTimer();
    
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          // Simulate a click at the center of the screen
          _simulateClick();
          break;
        case LogicalKeyboardKey.arrowLeft:
          webViewController?.goBack();
          break;
        case LogicalKeyboardKey.arrowRight:
          webViewController?.goForward();
          break;
        case LogicalKeyboardKey.arrowUp:
          _scrollUp();
          break;
        case LogicalKeyboardKey.arrowDown:
          _scrollDown();
          break;
        case LogicalKeyboardKey.backspace:
        case LogicalKeyboardKey.escape:
          Navigator.of(context).pop();
          break;
        case LogicalKeyboardKey.pageUp:
          _scrollPageUp();
          break;
        case LogicalKeyboardKey.pageDown:
          _scrollPageDown();
          break;
      }
    }
  }

  Future<void> _simulateClick() async {
    try {
      await webViewController?.evaluateJavascript(source: """
        var event = new MouseEvent('click', {
          'view': window,
          'bubbles': true,
          'cancelable': true
        });
        
        // Find the focused element or default to body
        var target = document.activeElement || document.body;
        target.dispatchEvent(event);
      """);
    } catch (e) {
      debugPrint('Error simulating click: $e');
    }
  }

  Future<void> _scrollUp() async {
    await webViewController?.evaluateJavascript(source: """
      window.scrollBy({top: -100, behavior: 'smooth'});
    """);
  }

  Future<void> _scrollDown() async {
    await webViewController?.evaluateJavascript(source: """
      window.scrollBy({top: 100, behavior: 'smooth'});
    """);
  }

  Future<void> _scrollPageUp() async {
    await webViewController?.evaluateJavascript(source: """
      window.scrollBy({top: -window.innerHeight * 0.8, behavior: 'smooth'});
    """);
  }

  Future<void> _scrollPageDown() async {
    await webViewController?.evaluateJavascript(source: """
      window.scrollBy({top: window.innerHeight * 0.8, behavior: 'smooth'});
    """);
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black, // Better for TV
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: Uri.parse(widget.websiteLink)),
                initialOptions: options,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  // Add any JavaScript handlers you need
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _isLoading = true;
                    currentUrl = url?.toString() ?? '';
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  if (!["http", "https", "file", "chrome", "data", "javascript", "about"]
                      .contains(uri.scheme)) {
                    // if (await canLaunchUrl(uri)) {
                    //   await launchUrl(uri);
                    //   return NavigationActionPolicy.CANCEL;
                    // }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _isLoading = false;
                    currentUrl = url?.toString() ?? '';
                  });
                  
                  // Optimize for TV
                  await controller.evaluateJavascript(source: """
                    // Disable text selection
                    document.body.style.userSelect = 'none';
                    document.body.style.webkitUserSelect = 'none';
                    
                    // Make links more TV-friendly
                    const links = document.getElementsByTagName('a');
                    for (let link of links) {
                      link.style.outline = 'none';
                      link.setAttribute('tabindex', '0');
                    }
                    
                    // Add focus styles for better navigation visibility
                    const style = document.createElement('style');
                    style.innerHTML = `
                      *:focus {
                        outline: 2px solid #4CAF50 !important;
                        outline-offset: 2px !important;
                      }
                    `;
                    document.head.appendChild(style);
                  """);
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    this.progress = progress / 100;
                  });
                },
                onUpdateVisitedHistory: (controller, url, androidIsReload) {
                  setState(() {
                    currentUrl = url?.toString() ?? '';
                  });
                },
              ),
              
              // Loading indicator
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    value: progress < 1.0 ? progress : null,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}