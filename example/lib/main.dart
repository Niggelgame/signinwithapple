import 'package:flutter/material.dart';
import 'package:signinwithapple/signinwithapple.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign in with Apple',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Sign in with Apple"),
        ),
        body: Center(
            child: FlatButton(
              onPressed: () async {
                print(await SignInWithApple().available);
                AppleUser t = await SignInWithApple().signIn(config: SignInWithAppleConfig(clientId: "com.kedil.examplesignin", urlSchemeRedirectUri: "com.kedil.signin", useOwnRedirectServer: false));
                print(t.idToken);
                print(t.authCode);
              },
              child: Text("Sign in with apple..."),
            )
        ),
      )
    );
  }
}
