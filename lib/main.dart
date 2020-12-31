import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'apikey.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<MyApp> {

  static final String DEVELOPER_KEY = ApiDevKey.DEV_KEY;
  List<String> wordsListFull = new List<String>();
  List<String> wordsList = new List<String>();
  List imageData;
  List colorListInteractive = new List<Color>(25);
  List colorList = new List<Color>();
  List blendModeListInteractive = new List<BlendMode>(25);
  List blendModeList = new List<BlendMode>();
  List borderColorListWhiteforPlayers = new List<Color>();
  Random random = new Random();
  bool spymaster = false;
  bool restart = true;
  bool runFutures = true;
  int blueScoreCounter = 0;
  int redScoreCounter = 0;
  bool blueFirst; 
  String winner = "";
  bool displayWinner = false;
  String currentTeam = "";
  bool gameOver = false;
  String version = "Pictures";
  String versionTemp = "Pictures";
  List<String> wordsPicturesRandomOrder = new List<String>();

  @override
  void initState() {
    super.initState();
    loadWords();
    for (int i = 0; i < 25; i++) {
      blendModeList.add(BlendMode.hardLight); 
      borderColorListWhiteforPlayers.add(Colors.white);
    }
  }

  void loadWords() async {
    String wordString = await rootBundle.loadString('assets/wordlist.txt');
    LineSplitter.split(wordString).forEach((line) => wordsListFull.add(line));
  }

  Future<String> fetchImages() async {
    var fetchdata = await http.get('https://api.unsplash.com/photos/random?client_id=${DEVELOPER_KEY}&count=25');
    imageData = json.decode(fetchdata.body);
    return 'Success';
  }

  @override
  Widget build(BuildContext context) {
    if (runFutures == true) {
      return FutureBuilder(
        future: fetchImages(),
        builder: (context, data) {
          if (data.hasData == false) {
            return Center(child: CircularProgressIndicator());
          } else {
            return gameBuild();
          }
        }
      );
    } else {
      return gameBuild();
    }
  }

  Widget gameBuild() {
    
    if (restart == true) {
      _setFirstTeam();
      wordsList = new List<String>();
      _wordList();
      colorList = new List<Color>();
      _colorList();
      wordsPicturesRandomOrder = new List<String>();
      _randomizeWordsPictures();

      colorListInteractive = new List<Color>(25);
      blendModeListInteractive = new List<BlendMode>(25);
      blueScoreCounter = 0;
      redScoreCounter = 0;
      spymaster = false;
      gameOver = false;
      
      restart = false;
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
                              TextSpan(text: "$redScoreCounter  ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
                              TextSpan(text: "(Goal: ", style: TextStyle(color: Colors.black, fontSize: 20)),
                              TextSpan(text: (blueFirst == true) ? "9" : "8", style: TextStyle(color: Colors.blue, fontSize: 20)),
                              TextSpan(text: " - ", style: TextStyle(color: Colors.black, fontStyle: FontStyle.italic, fontSize: 20)),
                              TextSpan(text: (blueFirst == true) ? "8" : "9", style: TextStyle(color: Colors.red, fontSize: 20)),
                              TextSpan(text: ")", style: TextStyle(color: Colors.black, fontSize: 20)),
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
                          value: versionTemp,
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
                              versionTemp = newValue;
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
                                version = versionTemp;
                                restart = true;
                                if ((version == 'Pictures') || (version == "Words + Pictures")) {
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
                      winner = "red";
                    } else if (currentTeam == "red") {
                      currentTeam = "blue";
                      winner = "blue";
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
            child: _buildTile(index),
          )
        );
    });
    return containers;
  }

  Widget _buildTile(index) {
    if (version == "Words") {
        return _buildTileWord(index);
    } else if (version == "Pictures") {
        return _buildTilePicture(index);
    } else if (version == "Words + Pictures") {
        if (wordsPicturesRandomOrder[index] == "word") {
          return _buildTileWord(index);
        } else if (wordsPicturesRandomOrder[index] == "picture") {
          return _buildTilePicture(index);
        } 
    }
  }

  Widget _buildTileWord(index) {
    return Container(
      decoration: BoxDecoration(
        color: colorListInteractive[index],
        border: Border.all(
          color: Colors.black,
          width: 1.0,
        )
      ),
      child: Center(
        child: Text(wordsList[index].toUpperCase(), style: TextStyle(
        color: (colorListInteractive[index] != null) ? Colors.white : Colors.black, 
        fontWeight: FontWeight.bold,
        fontSize: 19)
        )
      )
    );
  }

  Widget _buildTilePicture(index) {
    return Image.network(imageData[index]['urls']['small'],
      fit: BoxFit.fill,
      color: colorListInteractive[index],
      colorBlendMode: blendModeListInteractive[index]);
  }

  void _wordList() {
    int wordIndex;
    int wordCounter = 0;
    if (wordsListFull.length > 0) {
      while (wordCounter < 25) {
          wordIndex = random.nextInt(wordsListFull.length);
        if (wordsList.contains(wordsListFull[wordIndex]) == false) {
          wordsList.add(wordsListFull[wordIndex]);
          wordCounter++;
        }
      }
    }
  }

  void _setFirstTeam() {
    int randomPick;
    randomPick = random.nextInt(2);
    if (randomPick == 0) {
      blueFirst = true;
      currentTeam = "blue";
    } else if (randomPick == 1) {
      blueFirst = false;
      currentTeam = "red";
    }
  }

  void _colorList() {

    int numBlue, numRed, numNeutral, numAssassin;

    if (blueFirst == true) {
      numBlue = 9; numRed = 8; numNeutral = 7; numAssassin = 1;
    } else {
      numBlue = 8; numRed = 9; numNeutral = 7; numAssassin = 1;
    }

    for (int b = 0; b < numBlue; b++) {
      colorList.add(Colors.blue);
    }
    for (int r = 0; r < numRed; r++) {
      colorList.add(Colors.red);
    }
    for (int n = 0; n < numNeutral; n++) {
      colorList.add(Colors.brown[200]);
    }
    for (int a = 0; a < numAssassin; a++) {
      colorList.add(Colors.grey[900]);
    }

    colorList.shuffle();

  }

  void _randomizeWordsPictures() {
    int randomPick;
    int counter = 0;
    while (counter < 25) {
      randomPick = random.nextInt(2);
      if (randomPick == 0) {
        wordsPicturesRandomOrder.add("word");
      } else if (randomPick == 1) {
        wordsPicturesRandomOrder.add("picture");
      } 
      counter++;
    }
  }

  bool isGameOver() {
    if (blueFirst == true) {
      if ((blueScoreCounter == 9) || (redScoreCounter == 8)) {
        return true;
      } 
    } else if (blueFirst == false) {
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