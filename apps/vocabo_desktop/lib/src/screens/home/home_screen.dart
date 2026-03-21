import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VocaboColors.surface,
      body: const Center(
        child: Text('Vocabo Library'),
      ),
    );
  }
}
