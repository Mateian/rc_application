import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rc_application/pages/connect.dart';
import 'package:rc_application/pages/controller.dart';

void main() {
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, child) {
          if(!appState.isConnected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => ConnectPage()),
                (route) => false,
              );
            });
          }

          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Controller RC Boat',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Arial', colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent,)),
            home: ConnectPage(),
          );
        }
      )
        
    );
  }
}

class MyAppState extends ChangeNotifier {
  late Socket conn;
  Timer? _sendTimer;
  StreamController<String> _streamController = StreamController<String>.broadcast();
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String responseMessage = '';
  String logHistory = 'Fara Log-uri...';

  // variabile pentru retinerea textului introdus la conectare
  String lastConnectionText = '';
  bool savedText = false;

  Stream<String> get streamBuffer => _streamController.stream;

  Future<void> startConnection(String ip, int port) async {
    _streamController = StreamController<String>.broadcast();
    try {
      conn = await Socket.connect(ip, port);
      _isConnected = true;
      notifyListeners();

      conn.listen((List<int> event) {
        String rawResponse = utf8.decode(event);

        if(rawResponse.contains("\$\$LOGS:")) {
          List<String> parts = rawResponse.split('\$\$');

          // date senzori
          responseMessage = parts[0].replaceFirst("DATA:", "");

          // istoric log-uri
          logHistory = parts[1].replaceFirst("LOGS:", "");
        } else {
          responseMessage = rawResponse;
        }

        _streamController.add(responseMessage);
        notifyListeners();
      },
      onDone: () {
        _isConnected = false;
        _streamController.close();
        notifyListeners();
      },
      onError: (error) {
        _isConnected = false;
        responseMessage = 'Conexiune pierduta: $error';
        _streamController.close();
        notifyListeners();
      });

      notifyListeners();
      await Future.delayed(Duration(milliseconds: 1000));
    } catch(e) {
      responseMessage = 'Eroare la conectare la server: $e';
      notifyListeners();
    } 
  }

  void closeConnection()  {
    _isConnected = false;
    conn.write('q');
    conn.close();
    _streamController.close();
    notifyListeners();
  }

  void sendCommand(String command) {
    conn.write(command);
    notifyListeners();
  }

  void startSending(String command) {
    _sendTimer?.cancel();
    sendCommand(command);
    _sendTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      sendCommand(command);
    });
  }

  void stopSending() {
    _sendTimer?.cancel();
    _sendTimer = null;
    sendCommand('S');
  }
}

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  var selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch(selectedIndex) {
    case 0:
      page = ConnectPage();
      break;
    case 1:
      page = ControllerPage();
      break;
    default:
      throw UnimplementedError('no widgets for $selectedIndex');
  }

    return Scaffold(
      body:
        Expanded(
          child: Container(
            child: page,
          ),
        ),
    );
  }

}