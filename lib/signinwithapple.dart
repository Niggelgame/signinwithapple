library signinwithapple;

import 'dart:convert';
import 'dart:io';

import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

/// A Calculator.
class SignInWithApple {

  /*static final SignInWithApple _instance = SignInWithApple._internal();
  factory SignInWithApple() => _instance;
  SignInWithApple._internal() {

  }

  static SignInWithApple getInstance() {
    return _instance;
  }*/



  // final Future<bool> _isAvailableFuture = AppleSignIn.isAvailable();

  getHtml(String redirectUrl) {
    return """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Grant Access to Flutter</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
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

    #icon {
      font-size: 96pt;
    }

    #text {
      padding: 2em;
      max-width: 260px;
      text-align: center;
    }

    #button a {
      display: inline-block;
      padding: 6px 12px;
      color: white;
      border: 1px solid rgba(27,31,35,.2);
      border-radius: 3px;
      background-image: linear-gradient(-180deg, #34d058 0%, #22863a 90%);
      text-decoration: none;
      font-size: 14px;
      font-weight: 600;
    }

    #button a:active {
      background-color: #279f43;
      background-image: none;
    }
  </style>
</head>
<body>
  <main>
    <div id="icon">&#x1F3C7;</div>
    <div id="text">Press the button below to sign in using your Localtest.me account.</div>
    <div id="button"><a href="$redirectUrl">Sign in</a></div>
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
        AppleIdCredential creds = await loginNative();
        return AppleUser(idToken: String.fromCharCodes(creds.identityToken), authCode: String.fromCharCodes(creds.authorizationCode));
      } on CancelledLoginException catch(e) {
        print("User cancelled login");
      } on LoginErrorException catch(e) {
        print(e.toString());
      }
      return null;
    } else {
      /// Flutter_Web_Auth Signin
      if(config != null) {
        return await loginWeb(config);
      } else {
        return null;
      }
    }
  }

  Future<void> startServer(String redirectUri) async {
    final server = await HttpServer.bind('127.0.0.1', 43823, shared: true);

    server.listen((req) async {
      ContentType contentType = req.headers.contentType;
      print("printer");
      print(req.method);
      print(req.uri.toString());
      //setState(() { _status = 'Received request!'; });
      if(req.method == 'POST') {
        print("in post");
        String content = await utf8.decoder.bind(req).join(); /*2*/
        print(content);
        //req.response.headers.add('Content-Type', 'text/html');
        print(content.length);

        //req.response.headers.add('Content-Type', 'text/html');
        req.response.write(getHtml(redirectUri + "://" + content));
        req.response.redirect(Uri.dataFromString(redirectUri + "://" + content));
        //req.response.headers.add(name, value)

        //final url = Uri.directory(redirectUri);
        //print(url);
        //req.response.redirect(url);
        req.response.close();
        server.close();
      } else {
        req.response.headers.add('Content-Type', 'text/html');
        req.response.write(getHtml((redirectUri + "://success?code=1337")));
        //final url = Uri.directory(redirectUri);
        //print(url);
        //req.response.redirect(url);
        req.response.close();
        server.close();
      }

      print("afterpost");


    });
  }

  Future<AppleUser> loginWeb(SignInWithAppleConfig config) async {
    startServer(config.urlSchemeRedirectUri);
    final url = Uri.https("appleid.apple.com", "/auth/authorize", {
      'client_id': config.clientId,
      'redirect_uri': 'http://fuf.me:43823/',
      'response_type': 'code id_token',
      'scope': 'name email',
      'response_mode': 'form_post'
    });

    print(url.toString().replaceAll("+", "%20"));

    final result = await FlutterWebAuth.authenticate(url: url.toString().replaceAll("+", "%20"), callbackUrlScheme: config.urlSchemeRedirectUri);

    final Uri uri = Uri.dataFromString(result.replaceAll("://", "://applesignin.com?"));



    String code = uri.queryParameters["code"];
    String idToken = uri.queryParameters["id_token"];
    String user = uri.queryParameters["user"];

    return AppleUser(idToken: idToken, authCode: code);
  }

  Future<AppleIdCredential> loginNative() async {
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

  SignInWithAppleConfig({
    @required this.clientId,
    @required this.urlSchemeRedirectUri
  });

}


class AppleUser {
  final String idToken;
  final String authCode;

  AppleUser({
    @required this.idToken,
    @required this.authCode
  });
}