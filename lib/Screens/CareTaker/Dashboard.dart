import 'package:flutter/material.dart';

class CareTakerDashboard extends StatelessWidget {
  const CareTakerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CARETAKER DASHBOARD',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: Text("CARE TAKER DASHBOARD"),
        ),
      ),
    );
  }
}
