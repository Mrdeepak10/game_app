import 'package:flutter/material.dart';
import 'package:games_app/home_page/game.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text("WelCome Game World"),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GamePage(
                        gameLink: 'https://pinball.flutter.dev/#/',
                      ),
                    ),
                  );
                },
                child: const Text("Pin Ball")),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GamePage(
                      gameLink: 'https://www.gamesgames.com/game/sky-balls-3d',
                    ),
                  ),
                );
              },
              child: const Text("Game Hub"),
            ),
          ],
        ),
      ),
    );
  }
}
