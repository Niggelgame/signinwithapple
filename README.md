# signinwithapple

A new Flutter package to use platform-wide Apple-Sign-In!

It is only usable by Participants of the Apple Developer Program!

In the background it uses [`flutter_web_auth`][flutter_web_auth] for all devices except iOS devices with iOS 13 or higher, where it uses [`apple_sign_in`][apple_sign_in] to provide a native look. 
[flutter_web_auth]: https://pub.dev/packages/flutter_web_auth
[apple_sign_in]: https://pub.dev/packages/apple_sign_in
## Setup

The setup works like the most other Flutter Plugins, but you need to add the custom URL-Schemes to iOS and Android:

### Android

In order to capture the callback url, the following `activity` needs to be added to your `AndroidManifest.xml`. Be sure to relpace `YOUR_CALLBACK_URL_SCHEME_HERE` with your actual callback url scheme.

```xml
<manifest>
  <application>

    <activity android:name="com.linusu.flutter_web_auth.CallbackActivity" >
      <intent-filter android:label="flutter_web_auth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="YOUR_CALLBACK_URL_SCHEME_HERE" />
      </intent-filter>
    </activity>

  </application>
</manifest>
```

### iOS

In order to capture the callback url, the following part needs to be added to your `Info.plist` in the iOS-Folder. Be sure to replace `YOUR_CALLBACK_URL_SCHEME_HERE` with your actual callback url scheme.

```
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>YOUR_CALLBACK_URL_SCHEME_HERE</string>
		</array>
	</dict>
</array>

```


## Usage

You have to follow some steps first before using this Plugin:

### Apple Developer Console

First open your `Runner.xcodeworkspace` on your MacOS-Device, go to `Runner` and select the `Runner`-Target. Change your Bundle identifier to your own one, then choose `Signin & Capabilities`, where you need to select your Team, that is part of the Apple Developer Program. Recheck your Bundle Identifier, then add the `Sign in with Apple` Capability.

In your [`Apple-Developer-Console`][Apple-Developer-Console] go to your `Certificates, IDs & Profiles`, navigate to `Keys` and register a new Key with the `Sign in with Apple` capability. When you configure it, select the Primary-App-ID you previously set as you Bundle Identifier.
[Apple-Developer-Console]: https://developer.apple.com/account/#/overview/

Now choose `Identifiers` in the left column, and add a new Service ID. Set your Description and Identifier (needs to be different from your Bundle Identifier). This identifier will be your `clientID`. After creation, open it up again and enable `Sign in with Apple`. 
If you want to use your own server to handle the redirect back to the app, you put your own domain and redirect ULR in (the url you will specify later in the app, that handles the redirect). 
If you don't want to use you own server, put `fuf.me` as the domain, and `http://fuf.me:43823/` as the redirect url in, then save. 
_You can't just put your URL-Scheme here, because Sign-In-With-Apple Redirect-URLs need to have the http / https Scheme._

### In the code


```  
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
                AppleUser t = await SignInWithApple().signIn(config: SignInWithAppleConfig(clientId: "your.client.id", urlSchemeRedirectUri: "your.redirect.url.scheme", useOwnRedirectServer: false));
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
```


## One more thing...

If you want to have a native-looking Button, check out [`flutter_signin_button`][flutter_signin_button].

[flutter_signin_button]: https://pub.dev/packages/flutter_signin_button
