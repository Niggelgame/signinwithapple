library signinwithapple;

import 'dart:convert';
import 'dart:io';

import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

/// A Calculator.
class SignInWithApple {

  getHtml(String redirectUrl) {
    return """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>REDIRECTING</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv = "refresh" content = "1; url = $redirectUrl" />
  <script>
    document.write("You will get redirected in a few seconds");
    windows.setTimeout(function() {
      // Move to url Scheme
      windows.location.href = $redirectUrl;
    }, 500);
  </script>
  <style>
    html, body { margin: 0; padding: 0; }

    main {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      font-family: -apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol;
    }

    #text {
      padding: 2em;
      max-width: 260px;
      text-align: center;
    }
  </style>
</head>
<body>
  <main>
    <div id="text">Continue to App.</div>
  </main>
</body>
</html>
""";
  }

  String errorMessage;

  Future<AppleUser> signIn({@required SignInWithAppleConfig config}) async {
    if(await AppleSignIn.isAvailable()){
      /// Native Apple iOS 13 Login
      try{
        AppleIdCredential creds = await _loginNative();
        return AppleUser(idToken: String.fromCharCodes(creds.identityToken), authCode: String.fromCharCodes(creds.authorizationCode), user: creds.user);
      } on CancelledLoginException catch(e) {
        print("User cancelled login");
      } on LoginErrorException catch(e) {
        print(e.toString());
      }
      return null;
    } else {
      /// Flutter_Web_Auth Signin
      if(config != null) {
        if(!await available){
          return null;
        }
        return await _loginWeb(config);
      } else {
        return null;
      }
    }
  }

  Future<void> _startServer(String redirectUri) async {
    final server = await HttpServer.bind('127.0.0.1', 43823, shared: true);
    server.listen((req) async {
      if(req.method == 'POST') {
        String content = await utf8.decoder.bind(req).join();
        //print(content);
        req.response.headers.add('Content-Type', 'text/html');
        req.response.write(getHtml(redirectUri + "://" + content));
        /// Redirect currently not working because of insecure redirect error on Android / Chrome
        /// So we use Meta Refresh to redirect after one second, or on iOS using the Javascript method, which isn't executed on Android
        req.response.close();
        server.close();
      }
    });
  }

  Future<AppleUser> _loginWeb(SignInWithAppleConfig config) async {
    Uri url;
    if(config.useOwnRedirectServer && config.redirectServerURL.isNotEmpty) {
      url = Uri.https("appleid.apple.com", "/auth/authorize", {
        'client_id': config.clientId,
        'redirect_uri': config.redirectServerURL,
        'response_type': 'code id_token',
        'scope': 'name email',
        'response_mode': 'form_post'
      });
    } else {
      _startServer(config.urlSchemeRedirectUri);
      url = Uri.https("appleid.apple.com", "/auth/authorize", {
        'client_id': config.clientId,
        'redirect_uri': 'http://fuf.me:43823/',
        'response_type': 'code id_token',
        'scope': 'name email',
        'response_mode': 'form_post'
      });
    }

    final result = await FlutterWebAuth.authenticate(url: url.toString().replaceAll("+", "%20"), callbackUrlScheme: config.urlSchemeRedirectUri);

    final Uri uri = Uri.dataFromString(result.replaceAll("://", "://applesignin.com?"));

    String code = uri.queryParameters["code"];
    String idToken = uri.queryParameters["id_token"];
    String user = uri.queryParameters["user"];


    // The user is only provided the first time a user uses his Apple-ID to sign in to your service
    if(user != null){
      return AppleUser(idToken: idToken, authCode: code, user: user);
    } else {
      return AppleUser(idToken: idToken, authCode: code);
    }
  }

  Future<AppleIdCredential> _loginNative() async {
    final AuthorizationResult result = await AppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);

    switch (result.status){
      case AuthorizationStatus.authorized:
        return result.credential;
        break;
      case AuthorizationStatus.cancelled:
        throw CancelledLoginException();
        break;
      case AuthorizationStatus.error:
        throw LoginErrorException(result.error.localizedDescription);
        break;
    }
  }

  Future<bool> get available async {
    if(Platform.isIOS) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      String version = iosInfo.systemVersion;
      print(version);
      List<String> split = version.split(".");
      int versionNumber = int.parse(split[0]);
      if(versionNumber >= 11) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  int addOne(int value) => value + 1;
}

class CancelledLoginException implements Exception{}

class LoginErrorException implements Exception {
  String errorMessage;
  LoginErrorException(this.errorMessage);
}

class SignInWithAppleConfig {
  final String clientId;
  final String urlSchemeRedirectUri;
  final bool useOwnRedirectServer;
  final String redirectServerURL;

  SignInWithAppleConfig({
    @required this.clientId,
    @required this.urlSchemeRedirectUri,
    @required this.useOwnRedirectServer,
    this.redirectServerURL
  });
}

class AppleUser {
  final String idToken;
  final String authCode;
  final String user;

  AppleUser({
    @required this.idToken,
    @required this.authCode,
    this.user
  });
}