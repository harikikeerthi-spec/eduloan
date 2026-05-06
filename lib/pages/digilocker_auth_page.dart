import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:crypto/crypto.dart';

class DigilockerAuthPage extends StatefulWidget {
  final String clientId;
  final String redirectUri;

  const DigilockerAuthPage({
    Key? key,
    this.clientId = 'UN64D05F18', 
    this.redirectUri = 'https://vidhyaloan.com/callback',
  }) : super(key: key);

  @override
  State<DigilockerAuthPage> createState() => _DigilockerAuthPageState();
}

class _DigilockerAuthPageState extends State<DigilockerAuthPage> {
  late final WebViewController _controller;
  late final String _codeVerifier;

  String _generateRandomString(int length) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  @override
  void initState() {
    super.initState();
    
    _codeVerifier = _generateRandomString(64);
    final codeChallenge = _generateCodeChallenge(_codeVerifier);

    // Production DigiLocker OAuth Authorize URL
    final uri = Uri.parse('https://api.digitallocker.gov.in/public/oauth2/1/authorize').replace(queryParameters: {
      'response_type': 'code',
      'client_id': widget.clientId,
      'redirect_uri': widget.redirectUri,
      'state': 'vidhyaloan_auth_state',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });
    final authUrl = uri.toString(); 
    debugPrint('DEBUG: Auth URL: $authUrl');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => debugPrint('DEBUG: WebView started loading: $url'),
          onPageFinished: (String url) => debugPrint('DEBUG: WebView finished loading: $url'),
          onWebResourceError: (WebResourceError error) => debugPrint('DEBUG: WebView Error: ${error.description}'),
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('DEBUG: WebView navigating to: ${request.url}');
            // Intercept both the production redirectUri AND the mock callback
            if (request.url.startsWith(widget.redirectUri) || request.url.contains('/api/digilocker/callback')) {
              debugPrint('DEBUG: Callback detected: ${request.url}');
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              
              if (code != null) {
                debugPrint('DEBUG: Auth code extracted: $code');
                // Return both code and verifier
                Navigator.of(context).pop({
                  'code': code,
                  'code_verifier': _codeVerifier,
                });
                return NavigationDecision.prevent;
              } else {
                debugPrint('DEBUG: No auth code found in callback: ${request.url}');
                Navigator.of(context).pop(null);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: Building DigilockerAuthPage');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify with DigiLocker'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
