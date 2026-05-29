// import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rc_application/main.dart';
import 'package:rc_application/pages/controller.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:http/http.dart' as http;
import 'dart:io';


class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});
  

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final TextEditingController _text = TextEditingController();
  late Socket socket;
  String responseMessage = '';

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 228, 215, 250),
      appBar: AppBar(
        title: Text(
          'Connect',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Colors.deepPurpleAccent,
        toolbarHeight: 60,
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StrokeText(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold
            ),
            strokeColor: Colors.deepPurpleAccent,
            strokeWidth: 5,
            textAlign: TextAlign.center,
            text: 'Insert Address',
          ),
          Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.purple,
                  blurRadius: 1,
                  spreadRadius: 0.0,
                ),
              ],
            ),
            child: TextField(
              controller: _text,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(15),
                hintText: 'ex. 123.456.789.012:8080',
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.search),
            label: Text('Connect'),
            onPressed: () async {
              String url = _text.text.trim();

              // camp gol
              if(url.isEmpty) {
                showErrorSnackBar(context, "Introduceti adresa IP si portul.");
                return;
              }

              // exista caracter ':'
              if(!url.contains(':')) {
                showErrorSnackBar(context, "Format invalid. Incercati IP:PORT (ex. 1.2.3.4:1234)");
                return;
              }

              var array = url.split(':');
              // format corect
              if(array.length != 2) {
                showErrorSnackBar(context, "Formatul trebuie sa fie strict. IP:PORT (ex. 1.2.3.4:1234)");
                return;
              }

              var ip = array[0];
              var portString = array[1];
              int? port = int.tryParse(portString);
              if(port == null) {
                showErrorSnackBar(context, 'Portul "$portString" nu este un numar valid.');
                return;
              }

              setState(() {
                appState.savedText = true;
                appState.lastConnectionText = _text.text.trim();
              });

              try {
                await appState.startConnection(ip, port).timeout(
                  const Duration(seconds: 3),
                  onTimeout: () {
                    throw 'Timeout: Serverul nu raspunde';
                  },
                );

                if(!mounted) return;

                if(appState.responseMessage.trim() == 'CONNECTED') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ControllerPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eroare: ${appState.responseMessage}')),
                  );
                }
              } catch(e) {
                if(!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          if(appState.savedText)
            ElevatedButton(
              child: Text('Paste last text'),
              onPressed: () {
                _text.text = appState.lastConnectionText;
              },
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: 
              StreamBuilder<String>(
                stream: appState.streamBuffer,
                builder: (context, snapshot) {
                  if(snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if(snapshot.hasData) {
                    return Text(
                      'Raspuns de la server:\n\n${snapshot.data}',
                    );
                  } else {
                    return Text(
                      'Gol..'
                    );
                  }
                },
              ),
          ),
        ],
      ),

    );
  }

  // for http purpose
  Future<void> sendRequest(String ip) async {
    try {
      String url = "http://$ip";
      final response = await http.get(Uri.parse(url));

      if(response.statusCode == 200) {
        print('succes: ${response.body}');
      } else {
        print('eroare: ${response.statusCode}');
      }
    } catch(e) {
      print('eroare raspuns: $e');
    }
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}