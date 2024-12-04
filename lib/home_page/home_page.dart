import 'package:flutter/material.dart';
import 'package:games_app/home_page/game.dart';

import '../pages/entry_page.dart';
import '../snack_page.dart';
import '../tic_tac_toy.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("WelCome"),
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
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicToi(
                        title: 'Tic Tac Toe',
                      ),
                    ),
                  );
                },
                child: const Text("Tic Tac Toe")),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SnackGamePage(),
                    ),
                  );
                },
                child: const Text("Snack Game")),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EntryPage(),
                    ),
                  );
                },
                child: const Text("Truth & Dare")),
           
           /*  SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FludoGame(),
                  ),
                );
              },
              child:
                  const Text("LUDO"),
            ),*/
            SizedBox(
              height: 20,
            ),
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
