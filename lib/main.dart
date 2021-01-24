import 'apikey.dart';
import 'game_route_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:link/link.dart';
import 'dart:async';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showGame = false;
  String roomId;
  String version = "Words";
  static List<String> ROOM_LIST;
  
  // Create the initialization Future outside of 'build':
  //final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');

  @override
  /* Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          print('Error initializing FlutterFire');
          return Text('Something went wrong!');
        }
        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return new MaterialApp.router(
            title:"Codenames - Words & Pictures",
            theme: ThemeData(
              primaryColor: Colors.white,
            ),
            routerDelegate: GameRouterDelegate(showGame, roomId, version),
            routeInformationParser: GameRouteInformationParser(),
          );
        } else {
          // Otherwise, show something whilst waiting for initialization to complete
          return Center(child: CircularProgressIndicator());
        }
      }
    );
  } */

  Widget build(BuildContext context) {
    return new MaterialApp.router(
      title:"Codenames - Words & Pictures",
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      routerDelegate: GameRouterDelegate(showGame, roomId, version),
      routeInformationParser: GameRouteInformationParser(),
    );
  }
  
  Future<void> addRoom(String roomId) async {
    return rooms
      .doc(roomId)
      .set({
        'Success': true,
      })
      .then((value) => print("Room Added"))
      .catchError((error) => print("Failed to add room: $error"));
  }

  void _handlePlayButtonTapped(String version) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    UserCredential userCredential = await auth.signInAnonymously();

    if (auth.currentUser != null) {
      this.roomId = auth.currentUser.uid;
      print(this.roomId);
      addRoom(this.roomId);
    }

    setState(() {
      this.version = version;
      showGame = true;
    });
  }

}

class GameRouteInformationParser extends RouteInformationParser<GameRoutePath> {

  @override
  Future<GameRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location);
    
    // Handle home screen route ('/')
    if (uri.pathSegments.length == 0) {
      return GameRoutePath.home();
    }
    
    final id = uri.pathSegments.elementAt(0);
    return GameRoutePath.game(id);

  }
    
  @override
  RouteInformation restoreRouteInformation(GameRoutePath path) {
    if (path.isUnknown) {
      print("Unknown");
      return RouteInformation(location: '/404');
    }
    if (path.isHomePage) {
      print("Home");
      return RouteInformation(location: '/');
    }
    if (path.isGamePage) {
      print("Game");
      return RouteInformation(location: '/${path.roomId}');
    }
    return null;
  }
}

class GameRouterDelegate extends RouterDelegate<GameRoutePath> with ChangeNotifier, PopNavigatorRouterDelegateMixin<GameRoutePath>{
  bool showGame;
  bool show404 = false;
  String roomId;
  String version;

  GameRouterDelegate(showGame, roomId, version) {
    this.showGame = showGame;
    this.roomId = roomId;
    this.version = version;
  }



  // Initilialize game variables
  String versionTemp;
  List<String> wordsListFull = new List<String>();
  List<String> wordsList = new List<String>();
  List imageData;
  List colorListInteractive = new List<Color>(25);
  List colorList = new List<Color>();
  List blendModeListInteractive = new List<BlendMode>(25);
  List blendModeList = new List<BlendMode>();
  List borderColorListWhiteforOperatives = new List<Color>();
  bool spymaster = false;
  bool spymasterEnableSwitch = false;
  bool spymasterEnableSwitchTemp = false;
  bool enforceTimersSwitch = false;
  bool enforceTimersSwitchTemp = false;
  bool restart = true;
  bool runFutures = true;
  int blueScoreCounter = 0;
  int redScoreCounter = 0;
  int blueScore;
  int redScore;
  bool blueFirst; 
  String winner = "";
  bool displayWinner = false;
  String currentTeam = "";
  bool gameOver = false;
  List<String> wordsPicturesRandomOrder = new List<String>();
  //Timer _timer;
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

  //var minuteSettingInputBlue = TextEditingController()..text = '2';
  //var secondSettingInputBlue = TextEditingController()..text = '0';
  //var minuteSettingInputRed = TextEditingController()..text = '2';
  //var secondSettingInputRed = TextEditingController()..text = '0';
  String minuteSettingInputBlue = '2';
  String secondSettingInputBlue = '0';
  String minuteSettingInputRed = '2';
  String secondSettingInputRed = '0';

  bool errorMinuteSettingInputBlue = false;
  bool errorSecondSettingInputBlue = false;
  bool errorMinuteSettingInputRed = false;
  bool errorSecondSettingInputRed = false;

      
    
  @override
  GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();

  CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');

  Future<void> addRoom(String roomId) async {
    return rooms
      .doc(roomId)
      .set({
        'versionTemp': versionTemp,
        'wordsListFull': wordsListFull, 
        'wordsList': wordsList, 
        'imageData': imageData,
        //'colorListInteractive': colorListInteractive, // Create boolean arrays for these
        //'colorList': colorList,
        //'blendModeListInteractive': blendModeListInteractive,
        //'blendModeList': blendModeList,
        //'borderColorListWhiteforOperatives': borderColorListWhiteforOperatives,
        'spymaster': spymaster,
        'spymasterEnableSwitch': spymasterEnableSwitch,
        'spymasterEnableSwitchTemp': spymasterEnableSwitchTemp,
        'enforceTimersSwitch': enforceTimersSwitch,
        'enforceTimersSwitchTemp': enforceTimersSwitchTemp,
        'restart': restart,
        'runFutures': runFutures,
        'blueScoreCounter': blueScoreCounter,
        'redScoreCounter': redScoreCounter,
        'blueScore': blueScore,
        'redScore': redScore,
        'blueFirst': blueFirst,
        'winner': winner,
        'displayWinner': displayWinner,
        'currentTeam': currentTeam,
        'gameOver': gameOver,
        'wordsPicturesRandomOrder': wordsPicturesRandomOrder,
        '_minuteLimitBlue': _minuteLimitBlue,
        '_secondLimitBlue': _secondLimitBlue,
        '_minuteLimitRed': _minuteLimitRed,
        '_secondLimitRed': _secondLimitRed,
        '_currentTime': _currentTime,
        '_currentMinutesRemaining': _currentMinutesRemaining,
        '_currentSecondsRemaining': _currentSecondsRemaining,
        'timerSwitchBlue': timerSwitchBlue,
        'timerSwitchTempBlue': timerSwitchTempBlue,
        'timerSwitchRed': timerSwitchRed,
        'timerSwitchTempRed': timerSwitchTempRed,
        'minuteSettingInputBlue': minuteSettingInputBlue,
        'secondSettingInputBlue': secondSettingInputBlue,
        'minuteSettingInputRed': minuteSettingInputRed,
        'secondSettingInputRed': secondSettingInputRed,
        'errorMinuteSettingInputBlue': errorMinuteSettingInputBlue,
        'errorSecondSettingInputBlue': errorSecondSettingInputBlue,
        'errorMinuteSettingInputRed': errorMinuteSettingInputRed,
        'errorSecondSettingInputRed': errorSecondSettingInputRed
      })
      .then((value) => print("Room Added"))
      .catchError((error) => print("Failed to add room: $error"));
  }
  
  void _handlePlayButtonTapped(String version) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    UserCredential userCredential = await auth.signInAnonymously();

    if (auth.currentUser != null) {
      this.roomId = auth.currentUser.uid;
      print(this.roomId);
      addRoom(this.roomId);
    }

    this.version = version;
    showGame = true;
    notifyListeners();
  }

  @override
  GameRoutePath get currentConfiguration {
    if (show404) return GameRoutePath.unknown();
    if (showGame == false) return GameRoutePath.home();
    return GameRoutePath.game(roomId);
  }

  @override
  Widget build(BuildContext context) {
    return new Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          child: new HomeScreen(
            version: this.version,
            onTapPlay: _handlePlayButtonTapped,
          ),
        ),
        if (show404) 
          MaterialPage(key: ValueKey('UnknownKey'), child: UnknownPage())
        else if (showGame == true) 
          MaterialPage(
            child: new GameScreen(roomId: this.roomId, version: this.version),
          ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        showGame = false;
        show404 = false;
        notifyListeners();

        return true;
      }
    );
  }
  
  //This function takes user input for the URL and displays the appropriate page.
  @override
  Future<void> setNewRoutePath(GameRoutePath path) async {
    if (path.isUnknown) {
      showGame = false;
      show404 = true;
      return;
    }

    if (path.isGamePage) {
      this.roomId = path.roomId;
      showGame = true;
      //print(this.roomId);
    } else {
      showGame = false;
    }
    show404 = false;
  }
}

/* class UnknownPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('Not found - 404'),
      )
    );
  }
} */

class HomeScreen extends StatefulWidget {
  
  String version;
  ValueChanged<String> onTapPlay;

  HomeScreen({Key key, @required this.version, @required this.onTapPlay}) : super(key: key);
  
  @override
  _HomeState createState() => _HomeState(this.version, this.onTapPlay);
} 

class _HomeState extends State<HomeScreen> {
  String version;
  var roomID = TextEditingController()..text = "Some Room ID";
  ValueChanged<String> onTapPlay;

  _HomeState(version, onTapPlay) {
    this.version = version;
    this.onTapPlay = onTapPlay;
  }

  // Create the initialization Future outside of 'build':
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');

  @override
  /* Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          print('Error initializing FlutterFire');
          return Text('Something went wrong!');
        }
        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return new MaterialApp.router(
            title:"Codenames - Words & Pictures",
            theme: ThemeData(
              primaryColor: Colors.white,
            ),
            routerDelegate: GameRouterDelegate(showGame, roomId, version),
            routeInformationParser: GameRouteInformationParser(),
          );
        } else {
          // Otherwise, show something whilst waiting for initialization to complete
          return Center(child: CircularProgressIndicator());
        }
      }
    );
  } */


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          print('Error initializing FlutterFire');
          return Text('Something went wrong!');
        }
        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
    
          return new LayoutBuilder(
            builder: (context, constraints) {
              return OrientationBuilder(
                builder: (context, orientation) {
                  //initialize SizerUtil()
                  SizerUtil().init(constraints, orientation);
                  return new /* MaterialApp(
                    title:"Codenames - Words & Pictures",
                    theme: ThemeData(
                      primaryColor: Colors.white,
                    ),
                    home: new */ Scaffold(
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        centerTitle: true,
                        title: SelectableText("CODENAMES", 
                          style: GoogleFonts.shojumaru(
                            color: Colors.white,
                            fontSize: 12.0.sp,
                          ), 
                        ),
                      ),
                      body: new InteractiveViewer(
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              SizedBox(height: 10.0.w),
                              Center(
                                child: Container(
                                  height: 12.0.w,
                                  width: 90.0.w,
                                  child: SelectableText("Play Codenames online - Words, Pictures, or both mixed together!", textAlign: TextAlign.center,
                                    style: GoogleFonts.gaegu(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15.0.sp)
                                  )
                                )
                              ),
                              SizedBox(height: 13.0.w),
                              Center(
                                child: Container(
                                  height: 5.0.w,
                                  width: 90.0.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        height: 5.0.w,
                                        child: Icon(Icons.arrow_forward_rounded)
                                      ),
                                      Container(
                                        height: 5.0.w,
                                        child: SizedBox(width: 1.0.w)
                                      ),
                                      Container(
                                        height: 5.0.w,
                                        child: SelectableText("Start a new game:", style: GoogleFonts.gaegu(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.0.sp)),
                                      )
                                    ]
                                  )
                                )
                              ),
                            
                              SizedBox(height: 1.0.w),

                              Center(
                                child: Container(
                                  height: 9.0.w,
                                  width: 90.0.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        padding: EdgeInsets.only(top: 1.0.w),
                                        height: 9.0.w,
                                        child: SizedBox(
                                          height: 9.0.w,  
                                          child: DropdownButton(
                                            value: version,
                                            icon: Icon(Icons.arrow_downward),
                                            iconSize: 9.0.sp,
                                            items: <String>['Words', 'Pictures', 'Words + Pictures']
                                              .map<DropdownMenuItem<String>>((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value, style: TextStyle(fontSize: 9.0.sp)),
                                                );
                                              }).toList(),
                                            onChanged: (String newValue) {
                                              setState(() {
                                                version = newValue;
                                              });
                                            }
                                          ),
                                        )
                                      ),
                                      Container(
                                        height: 7.0.w,
                                        child: SizedBox(
                                          height: 7.0.w,
                                          width: 2.0.w,
                                        )
                                      ),
                                      Container(
                                        height: 7.0.w,
                                        child: SizedBox(
                                          height: 7.0.w,
                                          width: 12.0.w, 
                                          child: RawMaterialButton(
                                            fillColor: Colors.blue[300],
                                            splashColor: Colors.blueAccent,
                                            child: Text('Play', style: GoogleFonts.shojumaru(fontWeight: FontWeight.bold, fontSize: 10.0.sp)),
                                            onPressed: () => onTapPlay(version),
                                          )
                                        )
                                      )
                                    ]
                                  )
                                )
                              ),

                              SizedBox(height: 10.0.w),
                              Center(
                                child: Container(
                                  height: 5.0.w,
                                  width: 90.0.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        height: 5.0.w,
                                        child: Icon(Icons.arrow_forward_rounded)
                                      ),
                                      Container(
                                        height: 5.0.w,
                                        child: SizedBox(width: 1.0.w)
                                      ),
                                      Container(
                                        height: 5.0.w,
                                        child: SelectableText("Join an existing game:", style: GoogleFonts.gaegu(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.0.sp)),
                                      )
                                    ]
                                  )
                                )
                              ),

                              SizedBox(height: 1.0.w),

                              Center(
                                child: Container(
                                  height: 7.0.w,
                                  width: 90.0.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        height: 7.0.w,
                                        child: SizedBox(
                                          height: 7.0.w, 
                                          width: 40.0.w, 
                                          child: TextField(
                                            expands: true,
                                            maxLines: null,
                                            minLines: null,
                                            style: TextStyle(color: Colors.black, fontSize: 10.0.sp),
                                            textAlign: TextAlign.center,
                                            controller: roomID, 
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.all(0),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.black, width: 0.3.w)
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.black, width: 0.3.w)
                                              )
                                            )
                                          )
                                        )
                                      ),
                                      Container(
                                        height: 7.0.w,
                                        child: SizedBox(
                                          height: 7.0.w,
                                          width: 2.0.w,
                                        )
                                      ),
                                      Container(
                                        height: 7.0.w,
                                        child: SizedBox(
                                          height: 7.0.w,
                                          width: 12.0.w, 
                                          child: RawMaterialButton(
                                            fillColor: Colors.red,
                                            splashColor: Colors.redAccent,
                                            child: Text('Join', style: GoogleFonts.shojumaru(fontWeight: FontWeight.bold, fontSize: 10.0.sp)),
                                            onPressed: () {
                                              //Navigator.push(context, MaterialPageRoute(builder: (context) => GameScreen(version: this.version)));
                                            }
                                          )
                                        )
                                      )
                                    ]
                                  )
                                )
                              ),
                            ]
                          )
                        )
                      )
                    //)
                  );
                }
              );
            }
          );
        } else {
          // Otherwise, show something whilst waiting for initialization to complete
          return Center(child: CircularProgressIndicator());
        }
      }
    );
  }
}

class GameScreen extends StatefulWidget {
  final String roomId;
  final String version;
  GameScreen({Key key, @required this.roomId, @required this.version}) : super(key: key);

  @override
  _GameState createState() => _GameState(this.roomId, this.version);
 }

class _GameState extends State<GameScreen> {

  String roomId;
  String version;
  String versionTemp;
  
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
  int blueScore;
  int redScore;
  bool blueFirst; 
  String winner = "";
  bool displayWinner = false;
  String currentTeam = "";
  bool gameOver = false;
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
  //final _scrollController = ScrollController();

  bool roomExists = false;

   _GameState(roomId, version) {
    this.roomId = roomId;
    this.version = version;
    this.versionTemp = version;
  } 


  @override
  void initState() {
    super.initState();
    loadWords();
    fetchImages(); // Testing whether this line needs to be here to avoid having the game fail to load the first time
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

  Future<void> getDoc() async {
    final document = await FirebaseFirestore.instance
      .collection("rooms")
      .doc(this.roomId)
      .get();

    if (document.exists) {
      roomExists = true;
      print("Room exists!");
    } else {
      print("Room doesn't exist!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getDoc(),
      builder: (context, data) {
        if (data.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          if (!roomExists) {
            return UnknownPage();
          } else { 
            if (runFutures == true) {
              return FutureBuilder(
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
              );
            } else {
              return gameBuild();
            }
          }
        }
      }
    );
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

    if (blueFirst == true) {
      blueScore = 9 - blueScoreCounter;
      redScore = 8 - redScoreCounter;
    } else {
      blueScore = 8 - blueScoreCounter;
      redScore = 9 - redScoreCounter;
    }

    return new LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            //initialize SizerUtil()
            SizerUtil().init(constraints, orientation);
            return new /* MaterialApp(
              title:"Codenames - Words & Pictures",
              theme: ThemeData(
                primaryColor: Colors.white,
              ),
              home: */ Scaffold(
                drawer: MenuDrawer(),
                appBar: AppBar(
                  iconTheme: IconThemeData(color: Colors.white),
                  backgroundColor: Colors.black, 
                  centerTitle: true,
                  title: SelectableText("CODENAMES: ${version.toUpperCase()}", 
                    style: GoogleFonts.shojumaru(
                      color: Colors.white,
                      fontSize: 12.0.sp,
                    ),
                  ),
                ),
                body: new InteractiveViewer(
                  //new Scrollbar(
                  //controller: _scrollController,
                  //isAlwaysShown: true,
                  //child: SingleChildScrollView(
                    //controller: _scrollController,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 3.0.w),
                        Center(
                          child: Container(
                            height: 5.0.w,
                            width: 75.0.w,
                            child: Row(
                              children: <Widget>[
                                Container(
                                  height: 5.0.w,
                                  width: 25.0.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 2.0.w),                                  
                                      RichText(
                                        text: TextSpan(
                                          children: <TextSpan>[
                                            TextSpan(text: "Score:  ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8.0.sp)),
                                            TextSpan(text: "$blueScore  ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 8.0.sp)),
                                            TextSpan(text: "${String.fromCharCode(0x2014)}  ", style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                                            TextSpan(text: "$redScore  ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 8.0.sp)),
                                          ]
                                        )
                                      )
                                    ]
                                  )
                                ),
                                Container(
                                  height: 5.0.w,
                                  width: 25.0.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: <TextSpan>[
                                            TextSpan(text: "$currentTeam's turn", style: TextStyle(color: _teamColor(), fontSize: 8.0.sp)),
                                            TextSpan(text: (currentTimerSwitch() == true && gameOver == false) ? " (${_currentMinutesRemaining}:" 
                                              + ((_currentSecondsRemaining < 10) ? "0" : "") + "${_currentSecondsRemaining})" : "", 
                                              style: TextStyle(color: _teamColor(), fontWeight: FontWeight.bold, fontSize: 8.0.sp))
                                          ]
                                        )
                                      )
                                    ]
                                  )
                                ),
                                Container(
                                  height: 6.0.w,
                                  width: 25.0.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _turnWidget(),
                                      SizedBox(width: 2.0.w)
                                    ]
                                  )
                                )
                              ]
                            )
                          )
                        ),
                        Center(
                          child: Container(
                            height: 75.0.w,
                            width: 75.0.w, 
                            padding: EdgeInsets.all(1.0.h),
                            child: new GridView.count(
                              crossAxisCount: 5, 
                              crossAxisSpacing: 1.0.w, 
                              mainAxisSpacing: 1.0.w,
                              children: _buildGridTiles(25),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            height: 6.0.w,
                            width: 75.0.w, 
                            child: Row(
                              children: <Widget>[
                                Container(
                                  height: 5.0.w, 
                                  width: 37.5.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 2.0.w),
                                      ButtonTheme(
                                        height: 5.0.w,
                                        minWidth: 12.0.w,
                                        padding: EdgeInsets.zero,
                                        child: new RaisedButton(
                                          shape: spymaster == false ? RoundedRectangleBorder(side: BorderSide(color: Colors.black)) : null,
                                          onPressed: () {
                                            setState(() {
                                              spymaster = false;
                                            });
                                          },
                                          color: Colors.grey[350],
                                          child: Text('Operative',
                                            style: TextStyle(fontSize: 6.5.sp)
                                          ),
                                        )
                                      ),
                                      SizedBox(width: 0.5.w),
                                      ButtonTheme(
                                        height: 5.0.w,
                                        minWidth: 12.0.w,
                                        padding: EdgeInsets.zero,
                                        child: new RaisedButton(
                                          shape: spymaster == true ? RoundedRectangleBorder(side: BorderSide(color: Colors.black)) : null,
                                          onPressed: () {
                                            setState(() {
                                              spymaster = true;
                                            });
                                          },
                                          color: Colors.grey[350],
                                          child: Text('Spymaster',
                                            style: TextStyle(fontSize: 6.5.sp)
                                          ),
                                        )
                                      )
                                    ]
                                  )
                                ),
                                Container(
                                  height: 6.0.w, 
                                  width: 37.5.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      DropdownButton(
                                        value: versionTemp,
                                        icon: Icon(Icons.arrow_downward),
                                        iconSize: 7.0.sp,
                                        items: <String>['Words', 'Pictures', 'Words + Pictures']
                                          .map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value, style: TextStyle(fontSize: 6.5.sp)),
                                            );
                                          }).toList(),
                                        onChanged: (String newValue) {
                                          setState(() {
                                            versionTemp = newValue;
                                          });
                                        } 
                                      ),
                                      SizedBox(width: 0.5.w),
                                      ButtonTheme(  
                                        height: 5.0.w,
                                        minWidth: 14.0.w,
                                        padding: EdgeInsets.zero,
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
                                          child: Text('Next Game',
                                            style: TextStyle(fontSize: 6.5.sp)
                                          ),
                                        )
                                      ),
                                      SizedBox(width: 2.0.w)
                                    ]
                                  )
                                ) 
                              ]
                            )
                          )
                        ),
                        //SizedBox(height: 10.0.w),
                      ] 
                    )
                  )
                )
              //)
            );
          }
        );
      }
    );
  }

  List<Widget> _buildGridTiles(int numberOfTiles) {
    List<Container> containers = new List<Container>.generate(numberOfTiles, (int index) {
        return new Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: (spymaster == true || gameOver == true) ? colorList[index] : borderColorListWhiteforOperatives[index],
              width: (spymaster == true || gameOver == true) ? 1.0.w : 0.0.w,
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
        fontSize: 6.0.sp)
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
      return new Text("$winner wins!", style: TextStyle(color: _teamColor(), fontSize: 8.0.sp));
    } else {
      return new ButtonTheme(
        height: 5.0.w,
        minWidth: 16.0.w,
        padding: EdgeInsets.zero,
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
            child: new Text("End $currentTeam's turn", style: TextStyle(fontSize: 6.5.sp))
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
    return SimpleDialog(
      children: [
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
        Center(child: SelectableText("ROOM LINK", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10.0.sp))),
        SizedBox(height: 3.0.w),
        Container(
          height: 15.0.w,
          width: 98.0.w,
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(left: 3.0.w),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 500.0.w,
              child: ListView(
                children: [
                  SelectableText('Invite friends to this room with this link: ', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                  SelectableText('https://www.detective-dingo.web.app/#/${this.roomId}/', style: TextStyle(color: Colors.black, fontStyle: FontStyle.italic, decoration: TextDecoration.underline, fontSize: 8.0.sp)),
/*                   Link(url: 'https://www.detective-dingo.web.app/#/${this.roomId}/', 
                    child: Text('https://www.detective-dingo.web.app/#/${this.roomId}/',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 8.0.sp),  
                    )
                  ) */
                ]
              )
            )
          ) 
        ),
        SizedBox(height: 3.0.w)   
      ]
    );
  }

  Widget _dialogBuilderRules(BuildContext context) {
    return SimpleDialog(
      children: [
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
        Center(child: SelectableText("TYPICAL RULES", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10.0.sp))),
        SizedBox(height: 3.0.w),
        Container(
          height: 50.0.w,
          width: 90.0.w,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 500.0.w,
              child: ListView(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 2.0.w, right: 2.0.w),
                    child: Column(children: [
                      Align(alignment: Alignment.centerLeft, 
                        child: SelectableText("Setup", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 7.0.sp))),
                      Align(alignment: Alignment.centerLeft,
                        child: SelectableText('    ${String.fromCharCode(0x2014)} Players self-organize into 2 teams (1 red team and 1 blue team).\n    ${String.fromCharCode(0x2014)} Each team selects one Spymaster. The Spymaster clicks the "Spymaster" tab on the bottom left.\n    ${String.fromCharCode(0x2014)} The rest of the players on each team are Operatives. They click the "Operative" tab.\n    ${String.fromCharCode(0x2014)} The top of the game screen indicates the score for each team and which team\'s turn it is.\n    ${String.fromCharCode(0x2014)} To create a timer for each team\'s turn, adjust the game settings.',
                          style: TextStyle(color: Colors.black, fontSize: 6.0.sp))),
                      
                      SizedBox(height: 3.0.w),

                      Align(alignment: Alignment.centerLeft, 
                        child: SelectableText("Gameplay", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 7.0.sp))),
                      Align(alignment: Alignment.centerLeft,
                        child: SelectableText('    ${String.fromCharCode(0x2014)} Each team\'s turn consists of two phases:\n             (1) Spymaster gives a clue consisting of one Word and one Number.\n             (2) Operatives try guessing (one at a time) the words/pictures associated with the Word.\n    ${String.fromCharCode(0x2014)} Outside of the clues at the start of each turn, the Spymaster should not communicate with anyone.\n    ${String.fromCharCode(0x2014)} The Operatives may communicate with each other as much as they want.\n    ${String.fromCharCode(0x2014)} On each turn, the Operatives have up to (Number + 1) attempts to guess.\n    ${String.fromCharCode(0x2014)} Example turn:\n             (1) Spymaster gives the clue: "Animal, 3."\n             (2) Operatives have up to 4 attempts to guess words/pictures associated with animals.\n    ${String.fromCharCode(0x2014)} If the Operatives correctly click a word/picture, they continue guessing.\n    ${String.fromCharCode(0x2014)} If the Operatives click a wrong word/picture (Neutral or Opponent\'s), their turn immediately ends.\n    ${String.fromCharCode(0x2014)} If the Operatives ever click the Assassin word/picture, that team automatically loses!\n    ${String.fromCharCode(0x2014)} At any point during a team\'s turn, the Operatives have the option to end their turn.',
                          style: TextStyle(color: Colors.black, fontSize: 6.0.sp))),

                      SizedBox(height: 3.0.w),

                      Align(alignment: Alignment.centerLeft, 
                        child: SelectableText("End of Game", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 7.0.sp))),
                      Align(alignment: Alignment.centerLeft,
                        child: SelectableText('    ${String.fromCharCode(0x2014)} Unless the Assassin word/picture is guessed, the first team to guess all their words/pictures wins!\n    ${String.fromCharCode(0x2014)} The team that goes first has 9 words/pictures to guess, while the second team has 8.\n    ${String.fromCharCode(0x2014)} To start a new game, select the game version at the bottom of the screen and click "Next Game."',
                          style: TextStyle(color: Colors.black, fontSize: 6.0.sp))),

                      SizedBox(height: 3.0.w),
                    ])
                  )
                ]
              )
            )
          )
        )
      ]
    );
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
        Center(child: SelectableText("SETTINGS", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.0.sp))),
        SizedBox(height: 3.0.w),
        Container(
          height: 40.0.w,
          width: 50.0.w,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 500.0.w,
              child: ListView(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 3.0.w),
                    child: Row(
                      children: [
                        SelectableText("Blue Timer", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(width: 1.0.w),
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
                        SizedBox(width: 1.0.w),
                        _timeSettingInputContainerBlue(),
                      ])
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 3.0.w),
                    child: Row(children: [
                      SelectableText("Red Timer", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(width: 1.0.w),
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
                      SizedBox(width: 1.0.w),
                      _timeSettingInputContainerRed(),
                    ])
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 3.0.w),
                    child: Row(children: [
                      SelectableText("Enforce Timers", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
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
                    padding: EdgeInsets.only(left: 3.0.w),
                    child: Row(children: [
                      SelectableText("Spymaster Can Guess", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(width: 1.0.w),
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
                  )  
                ]
              )
            )
          )  
        ),
        SizedBox(height: 3.0.w),
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
        )),
        SizedBox(height: 3.0.w),
      ]);
    });
  }

  Widget _dialogBuilderNotes(BuildContext context) {
    return SimpleDialog(
      children: [
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
        Center(child: SelectableText("NOTES", style: GoogleFonts.shojumaru(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10.0.sp))),
        SizedBox(height: 3.0.w),
        Container(
          height: 30.0.w,
          width: 90.0.w,
          padding: EdgeInsets.only(left: 3.0.w),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 500.0.w,
              child: ListView(
                children: [
                  Wrap(
                    children: [
                    Text('${String.fromCharCode(0x2014)} Based on the actual ', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                    Link(url: 'https://czechgames.com/en/codenames/', 
                      child: Text('board game',
                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 8.0.sp), 
                      )
                    ),
                    Text(' by Vlaada Chv${String.fromCharCode(0x00E1)}til.', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                    ]
                  ),
                  SizedBox(height: 1.0.w),                
                  Wrap(
                    children: [
                      Text('${String.fromCharCode(0x2014)} Thanks to ', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                      Link(url: 'https://www.horsepaste.com/', 
                        child: Text('horsepaste',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 8.0.sp), 
                        )
                      ),
                      Text(' for the inspiration and ideas for formatting.', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                    ]
                  ),
                  SizedBox(height: 1.0.w),
                  Wrap(
                    children: [
                      Text('${String.fromCharCode(0x2014)} Words in the game were sourced from ', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                      Link(url: 'https://github.com/seanlyons/codenames/blob/master/wordlist.txt', 
                        child: Text('here',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 8.0.sp), 
                        )
                      ),
                      Text('.', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                    ]
                  ),
                  SizedBox(height: 1.0.w),
                  Wrap(
                    children: [
                      Text('${String.fromCharCode(0x2014)} Images in the game were sourced from ', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                      Link(url: 'https://unsplash.com/', 
                        child: Text('Unsplash',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 8.0.sp), 
                        )
                      ),
                      Text('.', style: TextStyle(color: Colors.black, fontSize: 8.0.sp)),
                    ]
                  ),
                  SizedBox(height: 3.0.w),
                ]
              )
            )
          ) 
        )
      ]
    );
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
        SelectableText((timerSwitchTempBlue == true && errorMinuteSettingInputBlue == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 5.0),
        SelectableText(" m", style: TextStyle(color: Colors.black, fontSize: 18)),
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
        SelectableText((timerSwitchTempBlue == true && errorSecondSettingInputBlue == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 5.0),
        SelectableText(" s", style: TextStyle(color: Colors.black, fontSize: 18)),
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
        SelectableText((timerSwitchTempRed == true && errorMinuteSettingInputRed == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 5.0),
        SelectableText(" m", style: TextStyle(color: Colors.black, fontSize: 18)),
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
        SelectableText((timerSwitchTempRed == true && errorSecondSettingInputRed == true) ? "!" : "", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 5.0),
        SelectableText(" s", style: TextStyle(color: Colors.black, fontSize: 18)),
      ]);
    } else {
      return Container();
    }
  }
}

class UnknownPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SelectableText('Not found - 404'),
      )
    );
  }
}