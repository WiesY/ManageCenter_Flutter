import 'package:flutter/material.dart';

class OperatorScreen extends StatelessWidget {
  const OperatorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель оператора'),
      ),
      body: const Center(
        child: Text('Экран оператора'),
      ),
    );
  }
}