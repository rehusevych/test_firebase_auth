import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:pedantic/pedantic.dart';
import 'package:firebase_auth_oauth/firebase_auth_oauth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runZonedGuarded(
    () => runApp(
      const MyApp(),
    ),
    (data, date) {},
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => signInWithSSO(),
        tooltip: 'Push',
        child: const Icon(Icons.add),
      ),
    );
  }

  void signInWithSSO() async {
    urlLauncher(String url) async {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        throw 'Could not launch $url';
      }
    }

    final uri = Uri.parse(
        'https://authentication-dev.theinfluencers.com/auth/realms/influencers-com');
    final scopes = List<String>.of([
      'profile',
      'openid',
      'offline_access',
    ]);
    const port = 4200;

    final issuer = await Issuer.discover(uri);
    final client = Client(issuer, 'mobile-app');

    final authenticator = Authenticator(
      client,
      scopes: scopes,
      port: port,
      urlLancher: urlLauncher,
    );

    final auth = await authenticator.authorize();
    unawaited(closeInAppWebView());
    final token = await auth.getTokenResponse();
    final info = await auth.getUserInfo();
    if (token.accessToken != null) {
      try {
        // final provider =
        //     OAuthProvider('oidc.theinfluencers-keycloak').credential(
        //   idToken: token.idToken.toCompactSerialization(),
        // );
        await FirebaseAuthOAuth().signInOAuth(
            'https://authentication-dev.theinfluencers.com/auth/realms/influencers-com',
            scopes);
      } catch (e) {
        throw Exception(e);
      }
    }
  }
}
