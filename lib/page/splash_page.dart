import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset('assets/bg.jpeg', fit: BoxFit.cover, height: double.infinity, width: double.infinity),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'temukan kopi terbaik\nuntuk anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text('memulai', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
