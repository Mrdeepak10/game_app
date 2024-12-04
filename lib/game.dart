import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:games_app/players/collision_details.dart';
import 'package:games_app/players/players.dart';
import 'package:games_app/players/players_notifier.dart';
import 'package:games_app/result/result.dart';
import 'package:games_app/result/result_notifier.dart';
import 'package:games_app/utils/colors.dart';
import 'package:provider/provider.dart';

import 'board/board.dart';
import 'board/overlay_surface.dart';
import 'dice/dice.dart';
import 'dice/dice_base.dart';
import 'dice/dice_notifier.dart';

class FludoGame extends StatefulWidget {
  @override
  _FludoGameState createState() => _FludoGameState();
}

class _FludoGameState extends State<FludoGame> with TickerProviderStateMixin {
  Animation<Color?>? _playerHighlightAnim;
  Animation<double>? _diceHighlightAnim;
  AnimationController? _playerHighlightAnimCont, _diceHighlightAnimCont;
  List<List<AnimationController>> _playerAnimContList = [];
  List<List<Animation<Offset>>> _playerAnimList = [];
  List<List<int>> _winnerPawnList = [];
  bool _provideFreeTurn = false;
  CollisionDetails _collisionDetails = CollisionDetails();

  int? _selectedPawnIndex;

  int _stepCounter = 0,
      _diceOutput = 0,
      _currentTurn = 0,
      _maxTrackIndex = 57,
      _straightSixesCounter = 0,
      _forwardStepAnimTimeInMillis = 250,
      _reverseStepAnimTimeInMillis = 60;
  List<List<List<Rect>>>? _playerTracks;
  List<Rect>? _safeSpots;
  List<List<MapEntry<int, Rect>>> _pawnCurrentStepInfo = []; //step index, rect

  PlayersNotifier? _playerPaintNotifier;
  ResultNotifier? _resultNotifier;
  DiceNotifier? _diceNotifier;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: []); //full screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]); //force portrait mode

    _playerPaintNotifier = PlayersNotifier();
    _resultNotifier = ResultNotifier();
    _diceNotifier = DiceNotifier();

    _playerHighlightAnimCont =
        AnimationController(duration: Duration(milliseconds: 700), vsync: this);
    _diceHighlightAnimCont =
        AnimationController(duration: Duration(seconds: 5), vsync: this);

    _playerHighlightAnim =
        ColorTween(begin: Colors.black12, end: Colors.black45)
            .animate(_playerHighlightAnimCont!);
    _diceHighlightAnim =
        Tween(begin: 0.0, end: 2 * pi).animate(_diceHighlightAnimCont!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure that the necessary data is initialized before calling _initData
      if (_playerTracks != null) {
        _initData();
      } else {
        // Handle the situation where _playerTracks or _forwardStepAnimTimeInMillis is not initialized
        print("Initialization error: _playerTracks or _forwardStepAnimTimeInMillis is null.");
      }
      _playerPaintNotifier!.rebuildPaint();

      _highlightCurrentPlayer();
      _highlightDice();
    });
  }

  @override
  void dispose() {
    _playerAnimContList.forEach((controllerList) {
      controllerList.forEach((controller) {
        controller.dispose();
      });
    });
    _playerHighlightAnimCont!.dispose();
    _diceHighlightAnimCont!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayersNotifier?>(
              create: (_) => _playerPaintNotifier),
          ChangeNotifierProvider<ResultNotifier?>(
              create: (_) => _resultNotifier),
          ChangeNotifierProvider<DiceNotifier?>(create: (_) => _diceNotifier),
        ],
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
                child: Container(
                  color: const Color(0xff1f0d67),
                )),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    margin: const EdgeInsets.all(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: <Widget>[
                          SizedBox.expand(
                            child: CustomPaint(
                              painter: BoardPainter(
                                  trackCalculationListener: (playerTracks) {
                                    _playerTracks = playerTracks;
                                  }),
                            ),
                          ),
                          SizedBox.expand(
                              child: AnimatedBuilder(
                                animation: _playerHighlightAnim!,
                                builder: (_, __) => CustomPaint(
                                  painter: OverlaySurface(
                                      highlightColor: _playerHighlightAnim!.value!,
                                      selectedHomeIndex: _currentTurn,
                                      clickOffset: (clickOffset) {
                                        _handleClick(clickOffset);
                                      }),
                                ),
                              )),
                          Consumer<PlayersNotifier>(builder: (_, notifier, __) {
                            if (notifier.shoulPaintPlayers)
                              return SizedBox.expand(
                                child: Stack(
                                  children: _buildPawnWidgets(),
                                ),
                              );
                            else
                              return Container();
                          }),
                          Consumer<ResultNotifier>(builder: (_, notifier, __) {
                            return SizedBox.expand(
                                child: CustomPaint(
                                  painter: ResultPainter(notifier.ranks),
                                ));
                          })
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_diceHighlightAnimCont!.isAnimating) {
                        _playerHighlightAnimCont!.reset();
                        _diceHighlightAnimCont!.reset();
                        _diceNotifier!.rollDice();
                      }
                    },
                    child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(children: [
                          SizedBox.expand(
                            child: AnimatedBuilder(
                              animation: _diceHighlightAnim!,
                              builder: (_, __) => CustomPaint(
                                painter:
                                DiceBasePainter(_diceHighlightAnim!.value),
                              ),
                            ),
                          ),
                          Consumer<DiceNotifier>(builder: (_, notifier, __) {
                            if (notifier.isRolled) {
                              _highlightCurrentPlayer();
                              _diceOutput = notifier.output;
                              if (_diceOutput == 6) _straightSixesCounter++;
                              _checkDiceResultValidity();
                            }
                            return SizedBox.expand(
                              child: CustomPaint(
                                painter: DicePaint(notifier.output),
                              ),
                            );
                          })
                        ])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPawnWidgets() {
    List<Widget> playerPawns = [];

    // Ensure _playerAnimList is properly populated
    if (_playerAnimList.isEmpty || _playerAnimList.length < 4) {
      print("Error: _playerAnimList is not populated or doesn't have enough data.");
      return playerPawns; // Return an empty list or a placeholder
    }

    for (int playerIndex = 0; playerIndex < 4; playerIndex++) {
      Color playerColor;
      switch (playerIndex) {
        case 0:
          playerColor = AppColors.player1;
          break;
        case 1:
          playerColor = AppColors.player2;
          break;
        case 2:
          playerColor = AppColors.player3;
          break;
        default:
          playerColor = AppColors.player4;
      }

      // Ensure each player's animation list is also properly populated
      if (_playerAnimList[playerIndex].isEmpty || _playerAnimList[playerIndex].length < 4) {
        print("Error: _playerAnimList for player $playerIndex is not populated correctly.");
        continue; // Skip to the next player if there's an issue
      }

      for (int pawnIndex = 0; pawnIndex < 4; pawnIndex++) {
        playerPawns.add(SizedBox.expand(
          child: AnimatedBuilder(
            builder: (_, child) => CustomPaint(
                painter: PlayersPainter(
                    playerCurrentSpot: _playerAnimList[playerIndex][pawnIndex].value,
                    playerColor: playerColor)),
            animation: _playerAnimList[playerIndex][pawnIndex],
          ),
        ));
      }
    }

    return playerPawns;
  }

  _initData() {
    // Ensure _playerTracks is not null before proceeding
    if (_playerTracks == null) {
      print("Error: _playerTracks is null.");
      return;
    }

    // Ensure _playerTracks has data for the expected number of players
    if (_playerTracks!.length != 4) {
      print("Error: _playerTracks does not have data for 4 players.");
      return;
    }

    // Initialize lists
    _playerAnimContList.clear();
    _playerAnimList.clear();
    _pawnCurrentStepInfo.clear();
    _winnerPawnList.clear();

    for (int playerIndex = 0; playerIndex < _playerTracks!.length; playerIndex++) {
      List<Animation<Offset>> currentPlayerAnimList = [];
      List<AnimationController> currentPlayerAnimContList = [];
      List<MapEntry<int, Rect>> currentStepInfoList = [];

      for (int pawnIndex = 0; pawnIndex < _playerTracks![playerIndex].length; pawnIndex++) {
        AnimationController currentAnimCont = AnimationController(
            duration: Duration(milliseconds: _forwardStepAnimTimeInMillis),
            vsync: this)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (!_collisionDetails.isReverse) _stepCounter++;
              _movePawn();
            }
          });

        currentPlayerAnimContList.add(currentAnimCont);
        currentPlayerAnimList.add(Tween(
            begin: _playerTracks![playerIndex][pawnIndex][0].center,
            end: _playerTracks![playerIndex][pawnIndex][1].center)
            .animate(currentAnimCont));
        currentStepInfoList
            .add(MapEntry(0, _playerTracks![playerIndex][pawnIndex][0]));
      }

      _playerAnimContList.add(currentPlayerAnimContList);
      _playerAnimList.add(currentPlayerAnimList);
      _pawnCurrentStepInfo.add(currentStepInfoList);
      _winnerPawnList.add([]);

      // Debugging statement to check the initialization
      print("Initialized player $playerIndex with ${currentPlayerAnimList.length} pawns.");
    }

    // Fetch all safe spot rects
    var playerTrack = _playerTracks![0][0];

    _safeSpots = [
      playerTrack[1],
      playerTrack[9],
      playerTrack[14],
      playerTrack[22],
      playerTrack[27],
      playerTrack[35],
      playerTrack[40],
      playerTrack[48]
    ];

    // Debugging statement to check safe spots
    print("Safe spots initialized: $_safeSpots");
  }

  _handleClick(Offset clickOffset) {
    // Check if the dice is not rolling and stepCounter is 0
    if (!_diceHighlightAnimCont!.isAnimating && _stepCounter == 0) {
      // Ensure that current turn data is available
      if (_pawnCurrentStepInfo.isEmpty) {
        print("Error: _pawnCurrentStepInfo is empty.");
        return;
      }

      if (_currentTurn < 0 || _currentTurn >= _pawnCurrentStepInfo.length) {
        print("Error: _currentTurn is out of bounds.");
        return;
      }

      // Get the pawns for the current player
      var playerPawns = _pawnCurrentStepInfo[_currentTurn];

      // Ensure playerPawns has data
      if (playerPawns.isEmpty) {
       // print("Error: Player $(_currentTurn) has no pawns.");
        return;
      }

      // Iterate over the pawns to find the one that was clicked
      for (int pawnIndex = 0; pawnIndex < playerPawns.length; pawnIndex++) {
        // Check if the click offset is within the pawn's area
        if (playerPawns[pawnIndex].value.contains(clickOffset)) {
          var clickedPawnIndex = playerPawns[pawnIndex].key;

          // Check if the pawn is in the house or if moving is allowed
          if (clickedPawnIndex == 0) {
            if (_diceOutput == 6) {
              _diceOutput = 1; // Move pawn out of the house when 6 is rolled
            } else {
              return; // Disallow pawn selection if 6 is not rolled
            }
          } else if (clickedPawnIndex + _diceOutput > _maxTrackIndex) {
            return; // Disallow pawn selection if dice number exceeds steps left
          }

          // Reset the player highlight animation
          _playerHighlightAnimCont!.reset();

          // Set the selected pawn index
          _selectedPawnIndex = pawnIndex;

          // Move the pawn
          _movePawn(considerCurrentStep: true);

          // Break the loop once the correct pawn is found
          break;
        }
      }
    }
  }

  void _checkDiceResultValidity() {
    var isValid = false;

    // Ensure _pawnCurrentStepInfo is properly initialized and has elements
    if (_pawnCurrentStepInfo.isEmpty || _currentTurn >= _pawnCurrentStepInfo.length) {
      print("Error: _pawnCurrentStepInfo is not properly initialized or _currentTurn is out of bounds.");
      _changeTurn(); // Change turn if the current player's data is invalid
      return;
    }

    for (var stepInfo in _pawnCurrentStepInfo[_currentTurn]) {
      if (_diceOutput == 6) {
        if (_straightSixesCounter == 3) {
          // Change turn in case of 3 straight sixes
          break;
        } else if (stepInfo.key + _diceOutput > _maxTrackIndex) {
          // Ignore pawn if it can't move 6 steps
          continue;
        }

        _provideFreeTurn = true;
        isValid = true;
        break;
      } else if (stepInfo.key != 0) {
        if (stepInfo.key + _diceOutput <= _maxTrackIndex) {
          isValid = true;
          break;
        }
      }
    }

    if (!isValid) _changeTurn();
  }

  _movePawn({bool considerCurrentStep = false}) {
    int playerIndex, pawnIndex, currentStepIndex;

    if (_collisionDetails.isReverse) {
      playerIndex = _collisionDetails.targetPlayerIndex;
      pawnIndex = _collisionDetails.pawnIndex;
      currentStepIndex = max(
          _pawnCurrentStepInfo[playerIndex][pawnIndex].key -
              (considerCurrentStep ? 0 : 1),
          0);
    } else {
      playerIndex = _currentTurn;
      pawnIndex = _selectedPawnIndex!;
      currentStepIndex = min(
          _pawnCurrentStepInfo[playerIndex][pawnIndex].key +
              (considerCurrentStep
                  ? 0
                  : 1), //condition to avoid incrementing key for initial step
          _maxTrackIndex);
    }

    //update current step info in the [_pawnCurrentStepInfo] list
    var currentStepInfo = MapEntry(currentStepIndex,
        _playerTracks![playerIndex][pawnIndex][currentStepIndex]);
    _pawnCurrentStepInfo[playerIndex][pawnIndex] = currentStepInfo;

    var animCont = _playerAnimContList[playerIndex][pawnIndex];

    if (_collisionDetails.isReverse) {
      if (currentStepIndex > 0) {
        //animate one step reverse
        _playerAnimList[_collisionDetails.targetPlayerIndex]
        [_collisionDetails.pawnIndex] = Tween(
            begin: currentStepInfo.value.center,
            end: _playerTracks![_collisionDetails.targetPlayerIndex]
            [_collisionDetails.pawnIndex][currentStepIndex - 1]
                .center)
            .animate(animCont);
        animCont.forward(from: 0.0);
      } else {
        _playerAnimContList[playerIndex][pawnIndex].duration =
            Duration(milliseconds: _forwardStepAnimTimeInMillis);
        _collisionDetails.isReverse = false;
        _provideFreeTurn = true; //free turn for collision
        _changeTurn();
      }
    } else if (_stepCounter != _diceOutput) {
      //animate one step forward
      _playerAnimList[playerIndex][pawnIndex] = Tween(
          begin: currentStepInfo.value.center,
          end: _playerTracks![playerIndex][pawnIndex]
          [min(currentStepIndex + 1, _maxTrackIndex)]
              .center)
          .animate(CurvedAnimation(
          parent: animCont,
          curve: Interval(0.0, 0.5, curve: Curves.easeOutCubic)));
      animCont.forward(from: 0.0);
    } else {
      if (_checkCollision(currentStepInfo))
        _movePawn(considerCurrentStep: true);
      else {
        if (currentStepIndex == _maxTrackIndex) {
          _winnerPawnList[_currentTurn]
              .add(_selectedPawnIndex!); //add pawn to [_winnerPawnList]

          if (_winnerPawnList[_currentTurn].length < 4)
            _provideFreeTurn =
            true; //if player has remaining pawns, provide free turn for reaching destination
          else {
            _resultNotifier!.rebuildPaint(_currentTurn);
            _provideFreeTurn =
            false; //to discard free turn if he completes the game
          }
        }

        _changeTurn();
      }
    }
  }

  bool _checkCollision(MapEntry<int, Rect> currentStepInfo) {
    var currentStepCenter = currentStepInfo.value.center;

    if (currentStepInfo.key <
        52) //no need to check if the pawn has entered destination lane
      if (!_safeSpots!.any((safeSpot) {
        //avoid checking if it has landed on a safe spot
        return safeSpot.contains(currentStepCenter);
      })) {
        List<CollisionDetails> collisions = [];
        for (int playerIndex = 0;
        playerIndex < _pawnCurrentStepInfo.length;
        playerIndex++) {
          for (int pawnIndex = 0;
          pawnIndex < _pawnCurrentStepInfo[playerIndex].length;
          pawnIndex++) {
            if (playerIndex != _currentTurn ||
                pawnIndex != _selectedPawnIndex) if (_pawnCurrentStepInfo[
            playerIndex][pawnIndex]
                .value
                .contains(currentStepCenter)) {
              collisions.add(CollisionDetails()
                ..pawnIndex = pawnIndex
                ..targetPlayerIndex = playerIndex);
            }
          }
        }

        /**
         * Check if collision is valid
         */
        if (collisions.isEmpty ||
            collisions.any((collision) {
              return collision.targetPlayerIndex == _currentTurn;
            }) ||
            collisions.length >
                1) //conditions to no collision and group collisions
          _collisionDetails.isReverse = false;
        else {
          _collisionDetails = collisions.first;
          _playerAnimContList[_collisionDetails.targetPlayerIndex]
          [_collisionDetails.pawnIndex]
              .duration = Duration(milliseconds: _reverseStepAnimTimeInMillis);

          _collisionDetails.isReverse = true;
        }
      }
    return _collisionDetails.isReverse;
  }

  void _changeTurn() {
    if (_winnerPawnList.where((playerPawns) => playerPawns.length == 4).length != 3) {
      // Ensure _winnerPawnList is properly initialized
      if (_winnerPawnList.isEmpty || _winnerPawnList.length < 4) {
        print("Error: _winnerPawnList is not properly initialized or doesn't have enough players.");
        return; // Exit the function if the list is not valid
      }

      _highlightDice();

      _stepCounter = 0; // Reset step counter for next turn

      if (!_provideFreeTurn) {
        do {
          // Change turn, ignoring winners
          _currentTurn = (_currentTurn + 1) % 4;

          // Ensure _currentTurn is valid
          if (_currentTurn < 0 || _currentTurn >= _winnerPawnList.length) {
            print("Error: _currentTurn is out of bounds.");
            return; // Exit the function if _currentTurn is invalid
          }

          // Select player if they are not yet a winner
          if (_winnerPawnList[_currentTurn].length != 4) {
            break;
          }
        } while (true);

        _straightSixesCounter = 0;
      } else if (_diceOutput != 6) {
        _straightSixesCounter = 0; // Reset 6s counter if a free turn is provided by other means
      }

      if (!_playerHighlightAnimCont!.isAnimating) {
        _highlightCurrentPlayer();
      }

      _provideFreeTurn = false;
    }
  }

  _highlightCurrentPlayer() {
    _playerHighlightAnimCont!.repeat(reverse: true);
  }

  _highlightDice() {
    _diceHighlightAnimCont!.repeat();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AnimationController>(
        '_diceHighlightAnimCont', _diceHighlightAnimCont));
  }
}