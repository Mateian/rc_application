// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rc_application/main.dart';
import 'package:rc_application/pages/connect.dart';
import 'package:provider/provider.dart';

class ControllerPage extends StatefulWidget {
  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  bool showGraph = false;
  bool showDebug = false;
  List<double> sonarData = [];
  static const int maxDistances = 20;
  bool isStarted = false;
  bool isStopped = false;
  bool isGoing = false;
  bool showLogs = false;

  int detectedFish = 0;

  late final StreamSubscription<String> _subscription;
  late Timer _updateTimer;

  Queue<double> _buffer = Queue();
  @override
  void initState() {
    super.initState();
    final appState = context.read<MyAppState>();

    _subscription = appState.streamBuffer.listen((raw) {
      final sonarValue = extractSonar(raw);
      if(sonarValue != null) {
        _buffer.add(sonarValue);
      }
    });

    _updateTimer = Timer.periodic(Duration(milliseconds: 200), (_) {
      if(!mounted) return;
      if(_buffer.isNotEmpty) {
        final newValues = List<double>.from(_buffer);
        _buffer.clear();

        setState(() {
          for(var value in newValues) {
            addSonarValue(value);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Scaffold(
      appBar: 
        AppBar(
          title: Row(
            children: [
              IconButton(
                icon: Icon(Icons.show_chart, color: showGraph ? Colors.blue : Colors.grey),
                onPressed: () => setState(() => showGraph = !showGraph),
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: Icon(Icons.bug_report, color: showDebug ? Colors.orange : Colors.grey),
                onPressed: () => setState(() => showDebug = !showDebug),
              ),
              const SizedBox(width: 5,),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8)),
                onPressed: () => setState(() => showLogs = !showLogs),
                icon: const Icon(Icons.list_alt, size: 18),
                label: Text('Logs'),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  _updateTimer.cancel();
                  await _subscription.cancel();

                  appState.closeConnection();
                  if(!context.mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder:(context) => ConnectPage(),));
                },
                child:
                  Text('Disconnect')
                ),
            )
          ]
        ),
      body:
        Stack(
          children: [
            if(showGraph)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color.fromARGB(255, 202, 239, 255), Colors.blue, const Color.fromARGB(255, 23, 102, 122)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
                // color: const Color.fromARGB(255, 36, 127, 172),
                child: SonarGraph(data: sonarData),
              ),
           
            const SizedBox(height: 10),
            Text(
              "Pesti: $detectedFish",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black
              )
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTapDown: (_) => appState.startSending('F'),
                    onTapUp: (_) => appState.stopSending(),
                    onTapCancel: () => appState.stopSending(),
                    child: 
                      Text(
                          '⬆️',
                          style: TextStyle(
                            fontSize: 50,
                          ),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      // crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTapDown: (_) => appState.startSending('L'),
                          onTapUp: (_) => appState.stopSending(),
                          onTapCancel: () => appState.stopSending(),
                          child:
                            Text(
                              '⬅️',
                              style: TextStyle(
                                fontSize: 50,
                              ),
                            ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            appState.sendCommand('COMMAND:DROP');
                          }, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            fixedSize: Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("DROP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),)
                          ),
                        GestureDetector(
                          onTapDown: (_) => appState.startSending('R'),
                          onTapUp: (_) => appState.stopSending(),
                          onTapCancel: () => appState.stopSending(),
                          child:
                            Text(
                              '➡️',
                              style: TextStyle(
                                fontSize: 50,
                              ),
                            ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (_) => appState.startSending('B'),
                    onTapUp: (_) => appState.stopSending(),
                    onTapCancel: () => appState.stopSending(),
                    child: 
                      Text(
                        '⬇️',
                        style: TextStyle(
                          fontSize: 50,
                        ),
                      ),
                  ),
                  SizedBox(height: 50,),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed:
                        () {
                          appState.sendCommand('COMMAND:START');
                          setState(() {
                            isStarted = true;
                            isStopped = false;
                            isGoing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                        ),
                         child: const Text("Start", style: TextStyle(color: Colors.black)),
                      ),
                      SizedBox(width: 10,),
                      ElevatedButton(
                        onPressed: () {
                          appState.sendCommand('COMMAND:STOP');
                          setState(() {
                            isStarted = true;
                            isStopped = true;
                            isGoing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text("Stop", style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(width: 10,),
                      ElevatedButton(
                        onPressed: !(isStarted && isStopped) ?
                        null :
                        () {
                          appState.sendCommand('COMMAND:GO');
                          setState(() {
                            isStarted = true;
                            isStopped = false;
                            isGoing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Go", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 10,),
                      ElevatedButton(
                        onPressed:
                        () {
                          appState.sendCommand('COMMAND:CLEAR');
                          setState(() {
                            isStarted = false;
                            isStopped = false;
                            isGoing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.black),
                        ),
                        child: const Text("Clear", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
            if(showDebug)
              Positioned(
                bottom: 20,
                left: 20,
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: 
                      StreamBuilder<String>(
                        stream: appState.streamBuffer,
                        builder: (context, snapshot) {
                          if(snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if(snapshot.hasData) {
                            final raw = snapshot.data!;
                            
                            return Text(raw);
                          } else {
                            return Text(
                              'Gol...'
                            );
                          }
                        },
                      ),
                  ),
              ),
              if(showLogs)
              Container(
                color: Colors.black.withAlpha(85),
                width: double.infinity,
                height: double.infinity,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("SERVER LOGS", style: TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white, size: 30),
                              onPressed: () => setState(() => showLogs = false),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.greenAccent.withAlpha(50)),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            appState.logHistory,
                            style: TextStyle(
                              color: Colors.lightGreenAccent,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ),
          ],
        ),
    );
  }

  double? extractSonar(String data) {
    final regex = RegExp(r"Sonar:\s*([0-9]*\.?[0-9]+)");
    final match = regex.firstMatch(data);

    if(match != null) {
      print("match: ${match.group(1)}");
      return double.tryParse(match.group(1)!);
    }

    print("no match");

    return null;
  }

  void addSonarValue(double value) {
    
    if(isFish(value)) {
      detectedFish++;
    }

    if(sonarData.length >= maxDistances) {
      sonarData.removeAt(0);
    }

    sonarData.add(value);
  }

  bool fishDetected = false;

  bool isFish(double data) {
    if(sonarData.length < 3) return false;

    double baseline = (sonarData[sonarData.length - 1] + sonarData[sonarData.length - 2] + sonarData[sonarData.length - 3]) / 3;

    const double sensitivityThreshold = 8.0;

      print("Current: $data");
  print("Baseline: $baseline");
  print("Difference: ${baseline - data}");
    if(data < baseline - sensitivityThreshold) {
      if(!fishDetected) {
        fishDetected = true;
        return true;
      }
    } else if(data >= baseline - 5) {
      fishDetected = false;
    }

    return false;
  }
}

class SonarGraph extends StatelessWidget {
  final List<double> data;
  
  const SonarGraph({super.key, required this.data});

  Color getColor(double value, double minY, double maxY) {
    if(maxY == minY) return Colors.lightGreen;
    double percent = (value - minY) / (maxY - minY);
    if(percent > 0.8) return Colors.red;
    else if(percent > 0.50) return Colors.orange;
    else if(percent > 0.30) return Colors.yellow;
    else return Colors.lightGreen;
  }

  @override
  Widget build(BuildContext context) {
    double minY = data.isEmpty ? 0 : data.reduce((a , b) => a < b ? a : b);
    double maxY = data.isEmpty ? 100 : data.reduce((a, b) => a > b ? a : b);
    minY = minY - 5 < 0 ? 0 : minY - 5;
    maxY += 5;

    List<Color> gradientColors = data.map((v) => getColor(v, minY, maxY)).toList();

    if(gradientColors.isEmpty) {
      gradientColors = [Colors.lightGreen, Colors.lightGreen];
    } else if(gradientColors.length == 1) {
      gradientColors.add(gradientColors.first);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          padding: EdgeInsets.all(5),
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,

              clipData: FlClipData.all(),
              lineTouchData: LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.2,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                )
              ],
              
            ),
          ),
        );
      },
    );
  }
}