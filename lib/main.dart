import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'apikey.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<MyApp> {

  static final String DEVELOPER_KEY = ApiDevKey.DEV_KEY;
  List data;
  List colorListInteractive = new List<Color>(25);
  List colorList = new List<Color>();
  List blendModeListInteractive = new List<BlendMode>(25);
  List blendModeList = new List<BlendMode>();
  List borderColorListWhiteforPlayers = new List<Color>();
  Random random = new Random();
  int firstColor;
  bool spymaster = false;
  bool runFutures = true;
  int blueScoreCounter = 0;
  int redScoreCounter = 0;
  bool blueFirst; 
  String winner = "";
  bool displayWinner = false;
  String currentTeam = "";
  bool gameOver = false;
  String version = "Pictures";

  @override
  void initState() {
    super.initState();
  
    for (int i = 0; i < 25; i++) {
      blendModeList.add(BlendMode.hardLight); 
      borderColorListWhiteforPlayers.add(Colors.white);
    }
  }

  Future<String> fetchImages() async {
    var fetchdata = await http.get('https://api.unsplash.com/photos/random?client_id=${DEVELOPER_KEY}&count=25');

    setState(() {
      data = json.decode(fetchdata.body);
    });
    return 'Success';
  }

  @override
  Widget build(BuildContext context) {
    if (runFutures == true) {
      fetchImages();
      _colorList();

      colorListInteractive = new List<Color>(25);
      blendModeListInteractive = new List<BlendMode>(25);
      blueScoreCounter = 0;
      redScoreCounter = 0;
      blueFirst = true;
      spymaster = false;
      gameOver = false;
      
      runFutures = false;

    }
    return MaterialApp(
      title:"Codenames - Play Online",
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("CODENAMES: ${version.toUpperCase()}", 
            style: GoogleFonts.shojumaru(
              fontSize: 24.0,
            ), //GoogleFonts
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.0),
              Center(
                child: Container(
                  height: 30,
                  width: 740,
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 5,
                        bottom: 5,
                        child: new RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(text: "$blueScoreCounter  ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20)),
                              TextSpan(text: "${String.fromCharCode(0x2014)}  ", style: TextStyle(color: Colors.black)),
                              TextSpan(text: "$redScoreCounter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
                            ]
                          )
                        )
                      ),
                      Positioned(
                        left: 325,
                        bottom: 5, 
                        child: new Text("$currentTeam's turn", style: TextStyle(color: _teamColor(), fontSize: 20))),
                      Positioned(
                        right: 5,
                        bottom: 0,
                        child: _turnWidget(),
                      )
                    ]
                  )
                )
              ),
              Center(
                child: Container(
                  width: 750, 
                  height: 750,
                  padding: const EdgeInsets.all(10.0),
                  child: new GridView.count(
                    crossAxisCount: 5, 
                    crossAxisSpacing: 10.0, 
                    mainAxisSpacing: 10.0,
                    children: _buildGridTiles(25),
                  ),
                ),
              ),
              SizedBox(height: 5.0),
              Center(
                child: Container(
                  height: 40,
                  width: 740, 
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 5,
                        bottom: 1,
                        child: ButtonTheme(
                          minWidth: 125.0,
                          height: 35.0,
                          child: new RaisedButton(
                            shape: spymaster == false ? RoundedRectangleBorder(side: BorderSide(color: Colors.black)) : null,
                            onPressed: () {
                              setState(() {
                                spymaster = false;
                              });
                            },
                            color: Colors.grey[350],
                            child: const Text('Player',
                              style: TextStyle(fontSize: 20)
                            ),
                          )
                        )
                      ),
                      Positioned(
                        left: 125,
                        bottom: 1,
                        child: ButtonTheme(
                          minWidth: 125.0,
                          height: 35.0,
                          child: new RaisedButton(
                            shape: spymaster == true ? RoundedRectangleBorder(side: BorderSide(color: Colors.black)) : null,
                            onPressed: () {
                              setState(() {
                                spymaster = true;
                              });
                            },
                            color: Colors.grey[350],
                            child: const Text('Spymaster',
                              style: TextStyle(fontSize: 20)
                            ),
                          )
                        )
                      ),   
                      Positioned(
                        right: 130,
                        bottom: 0,
                        child: DropdownButton(
                          value: version,
                          icon: Icon(Icons.arrow_downward),
                          iconSize: 15,
                          items: <String>['Words', 'Pictures', 'Words + Pictures']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: TextStyle(fontSize: 18)),
                              );
                            }).toList(),
                          onChanged: (String newValue) {
                            setState(() {
                              version = newValue;
                            });
                          }
                        )
                      ),
                      Positioned(
                        right: 5,
                        bottom: 1,
                        child: ButtonTheme(
                          minWidth: 125.0,
                          height: 35.0,
                          child: new RaisedButton(
                            onPressed: () {
                              setState(() {
                                if ((version == 'Pictures') || (version == "Words & Pictures")) {
                                  runFutures = true;
                                } else {
                                  runFutures = false;
                                }
                              });
                            },
                            color: Colors.indigo[800],
                            textColor: Colors.white,
                            child: const Text('Next Game',
                              style: TextStyle(fontSize: 20)
                            ),
                          )
                        ),
                      ) 
                    ]
                  )
                )
              ),
              SizedBox(height: 10.0)
            ] 
          )
        )
      )
    );
  }

  List<Widget> _buildGridTiles(int numberOfTiles) {
    List<Container> containers = new List<Container>.generate(numberOfTiles, (int index) {
        return new Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: (spymaster == true || gameOver == true) ? colorList[index] : borderColorListWhiteforPlayers[index],
              width: (spymaster == true || gameOver == true) ? 10.0 : 0.0,
            ),
          ),
          child: new InkWell(
            onTap: () {
              if ((spymaster == false) && (gameOver == false)) {
                setState(() {
                  
                  if (colorList[index] == Colors.blue) {
                    if (colorListInteractive[index] != colorList[index]) {
                      blueScoreCounter++;
                    }
                    if (currentTeam == "red") {
                      currentTeam = "blue";
                    }
                  } else if (colorList[index] == Colors.red) {
                    if (colorListInteractive[index] != colorList[index]) {
                      redScoreCounter++;
                    }
                    if (currentTeam == "blue") {
                      currentTeam = "red";
                    }
                  } else if (colorList[index] == Colors.brown[200]) {
                      if (colorListInteractive[index] != colorList[index]) {
                        if (currentTeam == "blue") {
                          currentTeam = "red";
                        } else if (currentTeam == "red") {
                          currentTeam = "blue";
                        }   
                      }
                  } else if (colorList[index] == Colors.grey[900]) {
                    gameOver = true;
                    if (currentTeam == "blue") {
                      currentTeam = "red";
                      winner = "Red";
                    } else if (currentTeam == "red") {
                      currentTeam = "blue";
                      winner = "Blue";
                    }
                  }

                  colorListInteractive[index] = colorList[index];
                  blendModeListInteractive[index] = blendModeList[index];

                  if (isGameOver() == true) {
                    if (colorList[index] == Colors.blue) {
                      winner = "blue";
                    } else if (colorList[index] == Colors.red) {
                      winner = "red";
                    }

                    gameOver = true;
                    displayWinner = true;
                  }
                });
              }
            },
            child: Image.network(data[index]['urls']['small'],
              fit: BoxFit.fill,
              color: colorListInteractive[index],
              colorBlendMode: blendModeListInteractive[index],
          )
        )
      );
    });
    return containers;
  }

  void _colorList() {

    int numBlue, numRed, numNeutral, numDeath;
    int counterBlue = 0, counterRed = 0, counterNeutral = 0, counterDeath = 0;

    int randomPick;

    firstColor = random.nextInt(2);

    if (firstColor == 0) {
      blueFirst = true;
      currentTeam = "blue";
      numBlue = 9; numRed = 8; numNeutral = 7; numDeath = 1;
    } else if (firstColor == 1) {
      blueFirst = false;
      currentTeam = "red";
      numBlue = 8; numRed = 9; numNeutral = 7; numDeath = 1;
    }

    while ((counterBlue < numBlue) || (counterRed < numRed) || (counterNeutral < counterNeutral) || (counterDeath < numDeath)) {

      randomPick = random.nextInt(4);

      if (randomPick == 0) {
        if (counterBlue < numBlue) {
          colorList.add(Colors.blue);
          counterBlue++;
        }
      } else if (randomPick == 1) {
        if (counterRed < numRed) {
          colorList.add(Colors.red);
          counterRed++;
        }
      } else if (randomPick == 2) {
        if (counterNeutral < numNeutral) {
          colorList.add(Colors.brown[200]);
          counterNeutral++;
        }
      } else if (randomPick == 3) {
        if (counterDeath < numDeath) {
          colorList.add(Colors.grey[900]);
          counterDeath++;
        }
      }
    }

    colorList.shuffle();

  }

  bool isGameOver() {
    if (blueFirst == true) {
      if ((blueScoreCounter == 9) || (redScoreCounter == 8)) {
        return true;
      } 
    } else {
      if ((redScoreCounter == 9) || (blueScoreCounter == 8)) {
        return true;
      }
    }

    return false;

  }

  Widget _turnWidget() {
    if (gameOver == true) {
      return new Text("$winner wins!", style: TextStyle(color: _teamColor(), fontSize: 20));
    } else {
      return new ButtonTheme(
        minWidth: 125.0,
        height: 35.0,
        child: new RaisedButton(
          onPressed: () {
            setState(() {
              if (currentTeam == "blue") {
                currentTeam = "red";
              } else if (currentTeam == "red") {
                currentTeam = "blue";
              }         
            });
          },
          color: Colors.grey[350],
          child: new Text("End $currentTeam's turn",
            style: TextStyle(fontSize: 20)
          ),
        )
      );
    }
  }

  Color _teamColor() {
    if (currentTeam == "blue") {
      return Colors.blue;
    } else if (currentTeam == "red") {
      return Colors.red;
    }
  }

}