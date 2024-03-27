import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const CardsView(title: 'FCard'),
    );
  }
}

class CardsView extends StatefulWidget {
  const CardsView({super.key, required this.title});

  final String title;

  @override
  State<CardsView> createState() => CardsState();
}

class CardsState extends State<CardsView> {
  final _flashcards = [
    {'Question': '', 'Answer': '', 'Image' : ''},
  ];

  bool _showAnswer = false;
  int _currentIndex = 0;
  String _addr = "";

  void _toggleAnswer() => setState(() => _showAnswer = !_showAnswer);

  void _navigateCard(bool isNext) => setState(() {
    _currentIndex = (_currentIndex + (isNext ? 1 : -1)) % _flashcards.length;
    _showAnswer = false;
  });

  void _randNavCard() => setState(() {
    _currentIndex = Random().nextInt(_flashcards.length);
    _showAnswer = false;
  });

  void _openFile() async {
    if (Platform.isAndroid && await Permission.storage.request().isDenied) {
      exit(1);
    }
    final result = await FilePicker.platform.getDirectoryPath(lockParentWindow: true);
    if (result != null) {
      _addr = result;
      final csvString = await File("$_addr/index.csv").readAsString();
      setState(() {
        _flashcards.clear();
        _flashcards.addAll(csvString.split('\n').where((line) => line.isNotEmpty).map((line) {
          final fields = line.split(',');
          fields[1] = fields[1].replaceAll("^n", "\n");
          final p = fields[1].split("^p");
          if (p.length > 1) {
            return {'Question': fields[0], 'Answer': p[0], 'Image' : p.last};
          }
          return {'Question': fields[0], 'Answer': fields[1]};
        }));
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardText = _showAnswer ? _flashcards[_currentIndex]['Answer'] ?? "" : _flashcards[_currentIndex]['Question'] ?? "";
    final answerImage = _showAnswer ? _flashcards[_currentIndex]['Image'] ?? "" : "";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(child: Text(widget.title)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width > 200 ? MediaQuery.of(context).size.width : 200,
                height: 200,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: answerImage.isNotEmpty
                        ? Image.file(
                        File("$_addr/$answerImage"),
                        errorBuilder: (context, error, stackTrace) => const Text('Image not found'))
                        : const Text(""),
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width > 200 ? MediaQuery.of(context).size.width : 200,
                child: GestureDetector(
                  onTap: _toggleAnswer,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          cardText,
                          style: TextStyle(fontSize: MediaQuery.of(context).textScaler.scale(16)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () => _navigateCard(false),
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () => _randNavCard(),
                      child: const Text("Random"),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () => _navigateCard(true),
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 10.0,
        onPressed: _openFile,
        child: const Icon(Icons.file_open_outlined),
      ),
    );
  }
}