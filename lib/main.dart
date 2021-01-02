import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'apikey.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:link/link.dart';
import 'dart:async';

void main() {
  runApp(new MaterialApp(
    home: new HomeScreen(),
    routes: <String, WidgetBuilder>{
      "playgame" : (BuildContext context) => new GameScreen(),
    }
  ));
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
} 

class _HomeState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:"Codenames - Play Online",
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: new Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("CODENAMES", 
            style: GoogleFonts.shojumaru(
              fontSize: 24.0,
            ), 
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: new RawMaterialButton(
                  fillColor: Colors.blue[300],
                  splashColor: Colors.redAccent,
                  child: Text('PLAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                  onPressed: () {
                    Navigator.of(context).pushNamed("playgame");
                  }
                )
              )
            ]
          )
        )
      )
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
 }

class _GameState extends State<GameScreen> {

  static final String DEVELOPER_KEY = ApiDevKey.DEV_KEY;
  List<String> wordsListFull = new List<String>();
  List<String> wordsList = new List<String>();
  List imageData;
  List colorListInteractive = new List<Color>(25);
  List colorList = new List<Color>();
  List blendModeListInteractive = new List<BlendMode>(25);
  List blendModeList = new List<BlendMode>();
  List borderColorListWhiteforOperatives = new List<Color>();
  Random random = new Random();
  bool spymaster = false;
  bool spymasterEnableSwitch = false;
  bool spymasterEnableSwitchTemp = false;
  bool restart = true;
  bool runFutures = true;
  int blueScoreCounter = 0;
  int redScoreCounter = 0;
  bool blueFirst; 
  String winner = "";
  bool displayWinner = false;
  String currentTeam = "";
  bool gameOver = false;
  String version = "Words";
  String versionTemp = "Words";
  List<String> wordsPicturesRandomOrder = new List<String>();
  Timer _timer;
  int _timeLimitBlue;
  int _timeLimitRed;
  int _currentTime;
  bool timerSwitchBlue = false;
  bool timerSwitchTempBlue = false;
  bool timerSwitchRed = false;
  bool timerSwitchTempRed = false;
  var timeSettingInputBlue = TextEditingController();
  var timeSettingInputRed = TextEditingController();
  bool errorTimeSettingInputBlue = false;
  bool errorTimeSettingInputRed = false;

  @override
  void initState() {
    super.initState();
    loadWords();
    for (int i = 0; i < 25; i++) {
      blendModeList.add(BlendMode.hardLight); 
      borderColorListWhiteforOperatives.add(Colors.white);
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

      if (currentTeam == "blue") {
        if (timerSwitchBlue == true) {
          startTimer(_timeLimitBlue);
        }
      } else if (currentTeam == "red") {
        if (timerSwitchRed == true) {
          startTimer(_timeLimitRed);
        }
      }
    }

    return MaterialApp(
      title:"Codenames - Play Online",
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            child: new Icon(Icons.settings, color: Colors.grey[700]),
            onTap: () => 
              showDialog(context: context,
                builder: (context) => _dialogBuilderSettings(context)
              )
          ),
          centerTitle: true,
          title: Text("CODENAMES: ${version.toUpperCase()}", 
            style: GoogleFonts.shojumaru(
              fontSize: 24.0,
            ),
          ),
          actions: <Widget> [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: GestureDetector(
                child: new Icon(Icons.menu, color: Colors.grey[700]),
                onTap: () =>
                  showDialog(context: context,
                    builder: (context) => _dialogBuilderRules(context)
                  )
              )
            )
          ]
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
                              TextSpan(text: "${String.fromCharCode(0x2014)}  ", style: TextStyle(color: Colors.black, fontSize: 17)),
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
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: new RichText(
                            text: TextSpan(
                              children: <TextSpan>[
                                TextSpan(text: "$currentTeam's turn", style: TextStyle(color: _teamColor(), fontSize: 20)),
                                if (currentTeam == "blue") (
                                  TextSpan(text: (timerSwitchBlue == true && gameOver == false) ? " (${_currentTime} sec)" : "", style: TextStyle(color: _teamColor(), fontWeight: FontWeight.bold, fontSize: 20))
                                ) else if (currentTeam == "red")
                                  TextSpan(text: (timerSwitchRed == true && gameOver == false) ? " (${_currentTime} sec)" : "", style: TextStyle(color: _teamColor(), fontWeight: FontWeight.bold, fontSize: 20))
                              ]
                            )
                          )
                        )
                      ),
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
              Center(
                child: Container(
                  height: 20,
                  width: 740,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 5,
                        child: Row( 
                          children: [
                            Text(((version == 'Pictures') || (version == "Words + Pictures")) ? "Source of images: " : "", 
                              style: TextStyle(color: Colors.black, fontStyle: FontStyle.italic, fontSize: 15)
                            ),
                            Link(url: 'https://unsplash.com/', 
                              child: Text(((version == 'Pictures') || (version == "Words + Pictures")) ? "https://unsplash.com/" : "",
                                style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic, decoration: TextDecoration.underline, fontSize: 15), 
                              )
                            )
                          ]
                        )
                      )
                    ]
                  )
                )
              ),
              SizedBox(height: 3.0),
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
                            child: const Text('Operative',
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
              color: (spymaster == true || gameOver == true) ? colorList[index] : borderColorListWhiteforOperatives[index],
              width: (spymaster == true || gameOver == true) ? 10.0 : 0.0,
            ),
          ),
          child: new InkWell(
            onTap: () {
              if (((spymaster == false || spymasterEnableSwitch == true) && (gameOver == false))) {
                setState(() {
                  
                  if (colorList[index] == Colors.blue) {
                    if (colorListInteractive[index] != colorList[index]) {
                      blueScoreCounter++;
                      if (currentTeam == "red") {
                        currentTeam = "blue";
                        if(timerSwitchBlue == true) {
                          startTimer(_timeLimitBlue);
                        }
                      }
                    }
                  } else if (colorList[index] == Colors.red) {
                    if (colorListInteractive[index] != colorList[index]) {
                      redScoreCounter++;
                      if (currentTeam == "blue") {
                        currentTeam = "red";
                        if(timerSwitchRed == true) {
                          startTimer(_timeLimitRed);
                        }
                      }
                    }
                  } else if (colorList[index] == Colors.brown[300]) {
                      if (colorListInteractive[index] != colorList[index]) {
                        if (currentTeam == "blue") {
                          currentTeam = "red";
                          if (timerSwitchRed == true) {
                            startTimer(_timeLimitRed);
                          }
                        } else if (currentTeam == "red") {
                          currentTeam = "blue";
                          if (timerSwitchBlue == true) {
                            startTimer(_timeLimitBlue);
                          }
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

                  if (_isGameOver() == true) {
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
      colorList.add(Colors.brown[300]);
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

  bool _isGameOver() {
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
                if(timerSwitchRed == true) {
                  startTimer(_timeLimitRed);
                }     
              } else if (currentTeam == "red") {
                currentTeam = "blue";
                if(timerSwitchBlue == true) {
                  startTimer(_timeLimitBlue);
                }  
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

  bool isSwitched = false;

  Widget _dialogBuilderSettings(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return SimpleDialog(children: [
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: (){
                Navigator.of(context).pop();
            },
            child: Align(
                alignment: Alignment(0.95, 1),
                child: Icon(Icons.close, color: Colors.black)
            ),
          ),
        ),
        Container(
          height: 250,
          width: 500,
          child: Column(children: [
            Center(child: Text("SETTINGS", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20))),
            SizedBox(height: 20.0),
            Container(
              padding: EdgeInsets.only(left: 25.0),
              child: Row(children: [
                Text("Blue Timer", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(width: 15.0),
                Switch(
                  value: timerSwitchTempBlue,
                  onChanged: (bool newValue) {
                    setState(() {
                      timerSwitchTempBlue = newValue;
                    });
                  },
                  activeTrackColor: Colors.lightBlueAccent,
                  activeColor: Colors.blue,
                ), 
                SizedBox(width: 15.0),
                Container(
                  height: 30.0, 
                  width: 50.0, 
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: timeSettingInputBlue, 
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(bottom: 15.0),
                    )
                  )
                ),
                Text((timerSwitchTempBlue == true && errorTimeSettingInputBlue == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(width: 5.0),
                Text(" sec", style: TextStyle(color: Colors.black, fontSize: 18)),
              ])
            ),
            Container(
              padding: EdgeInsets.only(left: 25.0),
              child: Row(children: [
                Text("Red Timer", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(width: 15.0),
                Switch(
                  value: timerSwitchTempRed,
                  onChanged: (bool newValue) {
                    setState(() {
                      timerSwitchTempRed = newValue;
                    });
                  },
                  activeTrackColor: Colors.redAccent,
                  activeColor: Colors.red,
                ), 
                SizedBox(width: 15.0),
                Container(
                  height: 30.0, 
                  width: 50.0, 
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: timeSettingInputRed, 
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(bottom: 15.0),
                    )
                  )
                ),
                Text((timerSwitchTempRed == true && errorTimeSettingInputRed == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(width: 5.0),
                Text(" sec", style: TextStyle(color: Colors.black, fontSize: 18)),
              ])
            ),
            Container(
              padding: EdgeInsets.only(left: 25.0),
              child: Row(children: [
                Text("Spymaster Guessing", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(width: 15.0),
                Switch(
                  value: spymasterEnableSwitchTemp,
                  onChanged: (bool newValue) {
                    setState(() {
                      spymasterEnableSwitchTemp = newValue;
                    });
                  },
                  activeTrackColor: Colors.grey,
                  activeColor: Colors.grey[800],
                ), 
              ])
            ),
            SizedBox(height: 20),
            Center(child: new RawMaterialButton(
              fillColor: Colors.blue[800],
              splashColor: Colors.blue[900],
              child: Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              onPressed: () {
                
                if (timerSwitchTempBlue == false) {
                  errorTimeSettingInputBlue = false;
                } else {
                  try {
                    _timeLimitBlue = int.parse(timeSettingInputBlue.text);
                    errorTimeSettingInputBlue = false;
                  } catch (e) {
                    setState(() {
                      errorTimeSettingInputBlue = true;
                    });
                  }
                } 

                if (timerSwitchTempRed == false) {
                  errorTimeSettingInputRed = false;
                } else {
                  try {
                    _timeLimitRed = int.parse(timeSettingInputRed.text);
                    errorTimeSettingInputRed = false;
                  } catch (e) {
                    setState(() {
                      errorTimeSettingInputRed = true;
                    });
                  }
                } 
                
                if (errorTimeSettingInputBlue == false && errorTimeSettingInputRed == false) {
                  Navigator.of(context).pop();
                  setState(() {
                    timerSwitchBlue = timerSwitchTempBlue;
                    timerSwitchRed = timerSwitchTempRed;
                    spymasterEnableSwitch = spymasterEnableSwitchTemp;
                    if (currentTeam == "blue" && timerSwitchBlue == true) {
                      _currentTime = _timeLimitBlue;
                      startTimer(_timeLimitBlue);
                    } else if (currentTeam == "red" && timerSwitchRed == true) {
                      _currentTime = _timeLimitRed;
                      startTimer(_timeLimitRed);
                    }
                    errorTimeSettingInputBlue = false;
                    errorTimeSettingInputRed = false;
                  });
                }
              }
            ))
          ])
        )
      ]);
    });
  }

  Widget _dialogBuilderRules(BuildContext context) {
    return SimpleDialog(children: [
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: (){
                Navigator.of(context).pop();
            },
            child: Align(
                alignment: Alignment(0.95, 1),
                child: Icon(Icons.close, color: Colors.black)
            ),
          ),
        ),
        Container(
          height: 650,
          width: 1000,
          child: Column(children: [
            Center(child: Text("TYPICAL RULES", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20))),
            SizedBox(height: 20.0),
            Container(
              padding: EdgeInsets.only(left: 25.0),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, 
                  child: Text("Setup", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 20))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Players self-organize into 2 teams (1 red team and 1 blue team).',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Each team selects one Spymaster. The Spymaster clicks the "Spymaster" tab on the bottom left of the game screen.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The rest of the players on each team are Operatives. They remain on the "Operative" tab for the whole game.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The top left of the game screen indicates the score for each team.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The top center of the game screen indicates at the top which team\'s turn it is.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} To create a timer for each team\'s turn, adjust the game settings in the top left corner of screen.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),

                SizedBox(height: 20.0),

                Align(alignment: Alignment.centerLeft, 
                  child: Text("Gameplay", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 20))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Each team\'s turn consists of two phases:',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('             (1) Spymaster gives a clue consisting of one word and one number.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('             (2) Operatives work together to try guessing (one at a time) the words/pictures associated with the word clue.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Outside of these clues at the start of each turn, the Spymaster should not communicate with anyone.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The Operatives have up to (number + 1) attempts to guess.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} If the Operatives correctly click a word/picture, they continue guessing.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} If the Operatives click a wrong word/picture (Neutral or opposite team\'s), their turn immediately ends.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} If the Operatives ever click the Assassin word/picture, that team automatically loses!',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} At any point during a team\'s turn, the Operatives have the option to end their turn.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),

                SizedBox(height: 20.0),

                Align(alignment: Alignment.centerLeft, 
                  child: Text("End of Game", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 20))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Unless the Assassin word/picture is ever guessed, the first team to guess all their words and/or pictures wins!',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The team that goes first has 9 words/pictures to guess, while the secnod team has 8.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} For more of a challenge, try playing the "Pictures" or "Pictures + Words" versions.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} To start a new game, simply select the game version and click "Next Game" at the bottom right of the game screen.',
                    style: TextStyle(color: Colors.black, fontSize: 18))),   

                SizedBox(height: 40.0),
                
                Row(children: [
                  Text('Special thanks to ', style: TextStyle(color: Colors.black, fontStyle: FontStyle.italic, fontSize: 18)),
                  Link(url: 'https://www.horsepaste.com/', 
                    child: Text('https://www.horsepaste.com/',
                      style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic, decoration: TextDecoration.underline, fontSize: 18), 
                    )
                  ),
                  Text(' for the inspiration and ideas for formatting behind this website!', style: TextStyle(color: Colors.black, fontStyle: FontStyle.italic, fontSize: 18)),
                ])
              ])
            )
          ])
        )
    ]);
  }

  void startTimer(int timeLimit) {
    
    const oneSec = const Duration(seconds: 1);
    
    if (_timer != null) {
      _timer.cancel();
      _currentTime = timeLimit;
    }

    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_currentTime == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _currentTime--;
          });
        }
      }
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

}