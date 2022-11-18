import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:pedantic/pedantic.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => signInWithSSO(),
        tooltip: 'Push',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
        final provider =
            OAuthProvider('oidc.theinfluencers-keycloak').credential(
          idToken: token.idToken.toCompactSerialization(),
        );
        await FirebaseAuth.instance.signInWithCredential(provider);
      } catch (e) {
        throw Exception(e);
      }
    }
  }
}
