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
import 'package:sizer/sizer.dart';

void main() {
  String version;

  runApp(new MaterialApp(
    home: new HomeScreen(),
    routes: <String, WidgetBuilder>{
      "playgame" : (BuildContext context) => new GameScreen(version: version),
    }
  ));
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
} 

class _HomeState extends State<HomeScreen> {
  String version = "Words"; 
  var roomID = TextEditingController()..text = "Some Room ID";

  @override
  Widget build(BuildContext context) {

    return new LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            //initialize SizerUtil()
            SizerUtil().init(constraints, orientation);
            return new MaterialApp(
              title:"Codenames - Words & Pictures",
              theme: ThemeData(
                primaryColor: Colors.white,
              ),
              home: new Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  centerTitle: true,
                  title: Text("CODENAMES", 
                    style: GoogleFonts.shojumaru(
                      color: Colors.white,
                      fontSize: 15.0.sp,
                    ), 
                  ),
                ),
                body: new InteractiveViewer(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 5.0.h),
                        Center(child: Text("Play Codenames online - Words, Pictures, or both mixed together!", 
                          style: GoogleFonts.gaegu(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15.0.sp))),
                        SizedBox(height: 6.0.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward_rounded),
                            SizedBox(width: 1.0.w),
                            Text("Start a new game:", style: GoogleFonts.gaegu(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.0.sp)),
                          ],
                        ),
                        SizedBox(height: 0.3.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DropdownButton(
                              value: version,
                              icon: Icon(Icons.arrow_downward),
                              iconSize: 9.0.sp,
                              items: <String>['Words', 'Pictures', 'Words + Pictures']
                                .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: TextStyle(fontSize: 8.0.sp)),
                                  );
                                }).toList(),
                              onChanged: (String newValue) {
                                setState(() {
                                  version = newValue;
                                });
                              }
                            ),
                            SizedBox(height: 0.5.h, width: 2.0.w),
                            RawMaterialButton(
                              fillColor: Colors.blue[300],
                              splashColor: Colors.blueAccent,
                              child: Text('Play', style: GoogleFonts.shojumaru(fontWeight: FontWeight.bold, fontSize: 8.0.sp)),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => GameScreen(version: this.version)));
                                //Navigator.of(context).pushNamed("playgame");
                              }
                            )
                        ]),
                        SizedBox(height: 6.0.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward_rounded),
                            SizedBox(width: 1.0.w),
                            Text("Join an existing game:", style: GoogleFonts.gaegu(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.0.sp)),
                          ],
                        ),
                        SizedBox(height: 0.3.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 3.0.h, 
                              width: 40.0.w, 
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: roomID, 
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 0.3.w)
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black, width: 0.3.w)
                                  ),
                                  contentPadding: EdgeInsets.only(bottom: 0.15.h),
                                )
                              )
                            ),
                            SizedBox(height: 0.5.h, width: 2.0.w),
                            RawMaterialButton(
                              fillColor: Colors.red,
                              splashColor: Colors.redAccent,
                              child: Text('Join', style: GoogleFonts.shojumaru(fontWeight: FontWeight.bold, fontSize: 8.0.sp)),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => GameScreen(version: this.version)));
                                //Navigator.of(context).pushNamed("playgame");
                              }
                            )
                        ]),
                      ]
                    )
                  )
                )
              )
            );
          }
        );
      }
    );
  }
}

class GameScreen extends StatefulWidget {
  final String version;
  GameScreen({Key key, @required this.version}) : super(key: key);

  @override
  _GameState createState() => _GameState(this.version);
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
  bool enforceTimersSwitch = false;
  bool enforceTimersSwitchTemp = false;
  bool restart = true;
  bool runFutures = true;
  int blueScoreCounter = 0;
  int redScoreCounter = 0;
  bool blueFirst; 
  String winner = "";
  bool displayWinner = false;
  String currentTeam = "";
  bool gameOver = false;
  String version;
  String versionTemp;
  List<String> wordsPicturesRandomOrder = new List<String>();
  Timer _timer;
  int _minuteLimitBlue;
  int _secondLimitBlue;
  int _minuteLimitRed;
  int _secondLimitRed;
  int _currentTime;
  int _currentMinutesRemaining;
  int _currentSecondsRemaining;
  bool timerSwitchBlue = false;
  bool timerSwitchTempBlue = false;
  bool timerSwitchRed = false;
  bool timerSwitchTempRed = false;
  var minuteSettingInputBlue = TextEditingController()..text = '2';
  var secondSettingInputBlue = TextEditingController()..text = '0';
  var minuteSettingInputRed = TextEditingController()..text = '2';
  var secondSettingInputRed = TextEditingController()..text = '0';
  bool errorMinuteSettingInputBlue = false;
  bool errorSecondSettingInputBlue = false;
  bool errorMinuteSettingInputRed = false;
  bool errorSecondSettingInputRed = false;

   _GameState(version) {
    this.version = version;
    this.versionTemp = version;
  } 

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
      return new WillPopScope(
        onWillPop: () async => Navigator.push(context, MaterialPageRoute(builder: (context) => new HomeScreen())),
        child: FutureBuilder(
          future: fetchImages(),
          builder: (context, data) {
            //Needs more testing, but this new line appears to better than "if (data.hasData == false) {" which sometimes can cause "Index Out of Range" issues
            //the Unsplash API image list calls
            if (data.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {         
              return gameBuild();
            }
          }
        )
      );
    } else {
      return new WillPopScope(
        onWillPop: () async => Navigator.push(context, MaterialPageRoute(builder: (context) => new HomeScreen())),
        child: gameBuild()
      );
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
          _currentTime = _minuteLimitBlue * 60 + _secondLimitBlue;
          _currentMinutesRemaining = _currentTime ~/ 60;
          _currentSecondsRemaining = _currentTime % 60;
        }
      } else if (currentTeam == "red") {
        if (timerSwitchRed == true) {
          _currentTime = _minuteLimitRed * 60 + _secondLimitRed;
          _currentMinutesRemaining = _currentTime ~/ 60;
          _currentSecondsRemaining = _currentTime % 60;
        }
      } 
    }

    return new MaterialApp(
      title:"Codenames - Words & Pictures",
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Scaffold(
        drawer: MenuDrawer(),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.black, 
          centerTitle: true,
          title: Text("CODENAMES: ${version.toUpperCase()}", 
            style: GoogleFonts.shojumaru(
              color: Colors.white,
              fontSize: 24.0,
            ),
          ),
        ),
        body: new InteractiveViewer(
          child: SingleChildScrollView(
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
                                  TextSpan(text: (currentTimerSwitch() == true && gameOver == false) ? " (${_currentMinutesRemaining}:" 
                                    + ((_currentSecondsRemaining < 10) ? "0" : "") + "${_currentSecondsRemaining})" : "", 
                                    style: TextStyle(color: _teamColor(), fontWeight: FontWeight.bold, fontSize: 20))
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
                          startTimer(_minuteLimitBlue * 60 + _secondLimitBlue);
                        }
                      }
                    }
                  } else if (colorList[index] == Colors.red) {
                    if (colorListInteractive[index] != colorList[index]) {
                      redScoreCounter++;
                      if (currentTeam == "blue") {
                        currentTeam = "red";
                        if(timerSwitchRed == true) {
                          startTimer(_minuteLimitRed * 60 + _secondLimitRed);
                        }
                      }
                    }
                  } else if (colorList[index] == Colors.brown[300]) {
                      if (colorListInteractive[index] != colorList[index]) {
                        if (currentTeam == "blue") {
                          currentTeam = "red";
                          if (timerSwitchRed == true) {
                            startTimer(_minuteLimitRed * 60 + _secondLimitRed);
                          }
                        } else if (currentTeam == "red") {
                          currentTeam = "blue";
                          if (timerSwitchBlue == true) {
                            startTimer(_minuteLimitBlue * 60 + _secondLimitBlue);
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
        minWidth: 130.0,
        height: 35.0,
        child: new RaisedButton(
          onPressed: () {
            setState(() {
              if (currentTeam == "blue") {
                currentTeam = "red";
                if(timerSwitchRed == true) {
                  startTimer(_minuteLimitRed * 60 + _secondLimitRed);
                }     
              } else if (currentTeam == "red") {
                currentTeam = "blue";
                if(timerSwitchBlue == true) {
                  startTimer(_minuteLimitBlue * 60 + _secondLimitBlue);
                }  
              }
            });
          },
          color: Colors.grey[350],
          child: Container(
            margin: const EdgeInsets.only(top: 5.0),
            child: new Text("End $currentTeam's turn", style: TextStyle(fontSize: 20))
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

  Widget MenuDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.link, color: Colors.grey[700]),
            title: Text('Room Link'),
            onTap: () {
              showDialog(context: context,
                builder: (context) => _dialogBuilderRoomLink(context)
              );              
            }
          ),
          ListTile(
            leading: Icon(Icons.menu_book, color: Colors.grey[700]),
            title: Text('How to Play'),
            onTap: () {
              showDialog(context: context,
                builder: (context) => _dialogBuilderRules(context)
              );
            }
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.grey[700]),
            title: Text('Settings'),
            onTap: () {
              showDialog(context: context,
                builder: (context) => _dialogBuilderSettings(context)
              );
            }              
          ),
          ListTile(
            leading: Icon(Icons.assignment_outlined, color: Colors.grey[700]),
            title: Text('Notes'),
            onTap: () {
              showDialog(context: context,
                builder: (context) => _dialogBuilderNotes(context)
              );
            }              
          ),
        ] 
      )
    );
  }

  Widget _dialogBuilderRoomLink(BuildContext context) {
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
      Align(
        alignment: Alignment.center,
        child: Center(child: Text("ROOM LINK", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20))),
      ),
      SizedBox(height: 20.0),
      Align(
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Invite friends to this room with this link: ', style: TextStyle(color: Colors.black, fontSize: 18)),
          Link(url: 'https://www.google.com/', 
            child: Text('https://www.google.com/',
              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 18), 
            )
          )
        ]),
      ),
      SizedBox(height: 20.0)   
    ]);
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
          height: 640,
          width: 1000,
          child: Column(children: [
            Center(child: Text("TYPICAL RULES", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20))),
            SizedBox(height: 20.0),
            Container(
              padding: EdgeInsets.only(left: 25.0),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, 
                  child: Text("Setup", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Players self-organize into 2 teams (1 red team and 1 blue team).',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Each team selects one Spymaster. The Spymaster clicks the "Spymaster" tab on the bottom left of the game screen.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The rest of the players on each team are Operatives. They remain on the "Operative" tab for the whole game.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The top of the game screen indicates the score for each team and which team\'s turn it is.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} To create a timer for each team\'s turn, adjust the game settings.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),

                SizedBox(height: 20.0),

                Align(alignment: Alignment.centerLeft, 
                  child: Text("Gameplay", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Each team\'s turn consists of two phases:',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('             (1) Spymaster gives a clue consisting of one Word and one Number.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('             (2) Operatives work together to try guessing (one at a time) the words/pictures associated with the Word.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Outside of the clues at the start of each turn, the Spymaster should not communicate with anyone.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The Operatives may communicate with each other as much as they want.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} On each turn, the Operatives have up to (Number + 1) attempts to guess words/pictures associated with the clue.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Example turn:',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('             (1) Spymaster gives the clue: "Animal, 3."',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('             (2) Operatives have up to 4 attempts to guess words/pictures associated with animals.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} If the Operatives correctly click a word/picture, they continue guessing.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} If the Operatives click a wrong word/picture (Neutral or Opposing team\'s), their turn immediately ends.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} If the Operatives ever click the Assassin word/picture, that team automatically loses!',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} At any point during a team\'s turn, the Operatives have the option to end their turn.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),

                SizedBox(height: 20.0),

                Align(alignment: Alignment.centerLeft, 
                  child: Text("End of Game", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 18))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} Unless the Assassin word/picture is ever guessed, the first team to guess all their words/pictures wins!',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} The team that goes first has 9 words/pictures to guess, while the second team has 8.',
                    style: TextStyle(color: Colors.black, fontSize: 16))),
                Align(alignment: Alignment.centerLeft,
                  child: Text('    ${String.fromCharCode(0x2014)} To start a new game, select the game version at the bottom of the screen and click "Next Game."',
                    style: TextStyle(color: Colors.black, fontSize: 16))),   
              ])
            )
          ])
        )
    ]);
  }

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
          height: 300,
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
                _timeSettingInputContainerBlue(),
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
                _timeSettingInputContainerRed(),
              ])
            ),
            Container(
              padding: EdgeInsets.only(left: 25.0),
              child: Row(children: [
                Text("Enforce Timers", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(width: 15.0),
                Switch(
                  value: enforceTimersSwitchTemp,
                  onChanged: (bool newValue) {
                    setState(() {
                      enforceTimersSwitchTemp = newValue;
                    });
                  },
                  activeTrackColor: Colors.grey,
                  activeColor: Colors.grey[800],
                ), 
              ])
            ),
            Container(
              padding: EdgeInsets.only(left: 25.0),
              child: Row(children: [
                Text("Spymaster Can Guess", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
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
                  errorMinuteSettingInputBlue = false;
                  errorSecondSettingInputBlue = false;
                } else {
                  try {
                    _minuteLimitBlue = int.parse(minuteSettingInputBlue.text);
                    errorMinuteSettingInputBlue = false;
                  } catch (e) {
                    setState(() {
                      errorMinuteSettingInputBlue = true;
                    });
                  }
                  try {
                    _secondLimitBlue = int.parse(secondSettingInputBlue.text);
                    errorSecondSettingInputBlue = false;
                  } catch (e) {
                    setState(() {
                      errorSecondSettingInputBlue = true;
                    });
                  }
                } 

                if (timerSwitchTempRed == false) {
                  errorMinuteSettingInputRed = false;
                  errorSecondSettingInputRed = false;
                } else {
                  try {
                    _minuteLimitRed = int.parse(minuteSettingInputRed.text);
                    errorMinuteSettingInputRed = false;
                  } catch (e) {
                    setState(() {
                      errorMinuteSettingInputRed = true;
                    });
                  }
                  try {
                    _secondLimitRed = int.parse(secondSettingInputRed.text);
                    errorSecondSettingInputRed = false;
                  } catch (e) {
                    setState(() {
                      errorSecondSettingInputRed = true;
                    });
                  }
                } 
                
                if (errorMinuteSettingInputBlue == false && errorSecondSettingInputBlue == false
                && errorMinuteSettingInputRed == false && errorSecondSettingInputRed == false) {
                  Navigator.of(context).pop();
                  setState(() {
                    timerSwitchBlue = timerSwitchTempBlue;
                    timerSwitchRed = timerSwitchTempRed;
                    enforceTimersSwitch = enforceTimersSwitchTemp;
                    spymasterEnableSwitch = spymasterEnableSwitchTemp;
                    if (currentTeam == "blue" && timerSwitchBlue == true) {
                      startTimer(_minuteLimitBlue * 60 + _secondLimitBlue);
                    } else if (currentTeam == "red" && timerSwitchRed == true) {
                      startTimer(_minuteLimitRed * 60 + _secondLimitRed);
                    }
                  });
                }
              }
            ))
          ])
        )
      ]);
    });
  }

  Widget _dialogBuilderNotes(BuildContext context) {
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
          height: 230,
          width: 1000,
          child: Column(children: [
            Center(child: Text("NOTES", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20))),
            SizedBox(height: 20.0),
            Container(
              padding: EdgeInsets.only(left: 25.0),
              child: Column(children: [
                Row(children: [
                  Text('${String.fromCharCode(0x2014)} Based on the actual ', style: TextStyle(color: Colors.black, fontSize: 18)),
                  Link(url: 'https://czechgames.com/en/codenames/', 
                    child: Text('board game',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 18), 
                    )
                  ),
                  Text(' by Vlaada Chv${String.fromCharCode(0x00E1)}til.', style: TextStyle(color: Colors.black, fontSize: 18)),
                ]),
                SizedBox(height: 20.0),                
                Row(children: [
                  Text('${String.fromCharCode(0x2014)} Thanks to ', style: TextStyle(color: Colors.black, fontSize: 18)),
                  Link(url: 'https://www.horsepaste.com/', 
                    child: Text('horsepaste',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 18), 
                    )
                  ),
                  Text(' for the inspiration and ideas for formatting behind this website.', style: TextStyle(color: Colors.black, fontSize: 18)),
                ]),
                SizedBox(height: 20.0),
                Row(children: [
                  Text('${String.fromCharCode(0x2014)} Words in the "Words" and "Words + Pictures" versions were sourced from ', style: TextStyle(color: Colors.black, fontSize: 18)),
                  Link(url: 'https://github.com/seanlyons/codenames/blob/master/wordlist.txt', 
                    child: Text('here',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 18), 
                    )
                  ),
                  Text('.', style: TextStyle(color: Colors.black, fontSize: 18)),
                ]),
                SizedBox(height: 20.0),
                Row(children: [
                  Text('${String.fromCharCode(0x2014)} Images in the "Pictures" and "Words + Pictures" versions were sourced from ', style: TextStyle(color: Colors.black, fontSize: 18)),
                  Link(url: 'https://unsplash.com/', 
                    child: Text('Unsplash',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 18), 
                    )
                  ),
                  Text('.', style: TextStyle(color: Colors.black, fontSize: 18)),
                ]),
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
    }

      _currentTime = timeLimit;
      _currentMinutesRemaining = _currentTime ~/ 60;
      _currentSecondsRemaining = _currentTime % 60;

    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_currentTime == 0) {
          setState(() {
            timer.cancel();
            if (enforceTimersSwitch == true) {
              if (currentTeam == "blue") {
                currentTeam = "red";
                if (timerSwitchRed == true) {
                  startTimer(_minuteLimitRed * 60 + _secondLimitRed);
                }
              } else if (currentTeam == "red") {
                currentTeam = "blue";
                if (timerSwitchBlue == true) {
                  startTimer(_minuteLimitBlue * 60 + _secondLimitBlue);
                }
              }
            }
          });
        } else {
          setState(() {
            _currentTime--;
            _currentMinutesRemaining = _currentTime ~/ 60;
            _currentSecondsRemaining = _currentTime % 60;
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

  bool currentTimerSwitch() {
    if (currentTeam == "blue") {
      return timerSwitchBlue;
    } else if (currentTeam == "red") {
      return timerSwitchRed;
    }
  }

  Widget _timeSettingInputContainerBlue() {
    if (timerSwitchTempBlue == true) {
      return Row(children: [
        Container(
          height: 30.0, 
          width: 40.0, 
          child: TextField(
            textAlign: TextAlign.center,
            controller: minuteSettingInputBlue, 
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(bottom: 15.0),
            )
          )
        ),
        Text((timerSwitchTempBlue == true && errorMinuteSettingInputBlue == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 5.0),
        Text(" m", style: TextStyle(color: Colors.black, fontSize: 18)),
        SizedBox(width: 5.0),
        Container(
          height: 30.0, 
          width: 40.0, 
          child: TextField(
            textAlign: TextAlign.center,
            controller: secondSettingInputBlue, 
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(bottom: 15.0),
            )
          )
        ),
        Text((timerSwitchTempBlue == true && errorSecondSettingInputBlue == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 5.0),
        Text(" s", style: TextStyle(color: Colors.black, fontSize: 18)),
      ]);
    } else {
      return Container();
    }
  }

  Widget _timeSettingInputContainerRed() {
    if (timerSwitchTempRed == true) {
      return Row(children: [
        Container(
          height: 30.0, 
          width: 40.0, 
          child: TextField(
            textAlign: TextAlign.center,
            controller: minuteSettingInputRed, 
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(bottom: 15.0),
            )
          )
        ),
        Text((timerSwitchTempRed == true && errorMinuteSettingInputRed == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 5.0),
        Text(" m", style: TextStyle(color: Colors.black, fontSize: 18)),
        SizedBox(width: 5.0),
        Container(
          height: 30.0, 
          width: 40.0, 
          child: TextField(
            textAlign: TextAlign.center,
            controller: secondSettingInputRed, 
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(bottom: 15.0),
            )
          )
        ),
        Text((timerSwitchTempRed == true && errorSecondSettingInputRed == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 5.0),
        Text(" s", style: TextStyle(color: Colors.black, fontSize: 18)),
      ]);
    } else {
      return Container();
    }
  }

}