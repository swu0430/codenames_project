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
  
  // Create the initialization Future outside of 'build':
  //final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');

  @override
  Widget build(BuildContext context) {
    return new MaterialApp.router(
      title:"Codenames - Words & Pictures",
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      routerDelegate: GameRouterDelegate(showGame, roomId),
      routeInformationParser: GameRouteInformationParser(),
    );
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

  bool runFutures = false;
  bool restart = false;

  GameRouterDelegate(showGame, roomId) {
    this.showGame = showGame;
    this.roomId = roomId;
  }

  // Initilialize game variables
  String versionTemp;
  List<String> wordsList = new List<String>();
  List imageData;
  List wordsPicturesRandomOrder = new List<String>(25);
  List colorListInteractiveString = new List<String>(25);
  List colorListString = new List<String>();
  List blendModeListInteractiveBool = new List<bool>(25);
  bool timerSwitchBlue = false;
  bool timerSwitchTempBlue = false;
  bool timerSwitchRed = false;
  bool timerSwitchTempRed = false;
  bool spymasterEnableSwitch = false;
  bool spymasterEnableSwitchTemp = false;
  bool enforceTimersSwitch = false;
  bool enforceTimersSwitchTemp = false;
  String minuteSettingInputBlue = '2';
  String secondSettingInputBlue = '0';
  String minuteSettingInputRed = '2';
  String secondSettingInputRed = '0';
  int _minuteLimitBlue;
  int _secondLimitBlue;
  int _minuteLimitRed;
  int _secondLimitRed;
  String currentTeam = "";
  int _currentTime;
  int blueScoreCounter = 0;
  int redScoreCounter = 0;
  bool blueFirst; 
  String winner = "";
  bool displayWinner = false;
  bool gameOver = false;
  bool spymasterRestart = false;

  @override
  GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();

  CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');

  Future<void> addRoom(String roomId, String version) async {
    
    this.version = version;
    this.restart = true;
    if ((version == "Pictures") || version == "Words + Pictures") {
      this.runFutures = true;
    }

    for (int i = 0; i < blendModeListInteractiveBool.length; i++) {
      blendModeListInteractiveBool[i] = false;
    }
    
    return rooms
      .doc(roomId)
      .set({
        'version': version,
        'versionTemp': version,
        'wordsList': wordsList, 
        'imageData': imageData,
        'wordsPicturesRandomOrder': wordsPicturesRandomOrder,
        'colorListInteractiveString': colorListInteractiveString,
        'colorListString': colorListString,
        'blendModeListInteractiveBool': blendModeListInteractiveBool,
        'timerSwitchBlue': timerSwitchBlue,
        'timerSwitchTempBlue': timerSwitchTempBlue,
        'timerSwitchRed': timerSwitchRed,
        'timerSwitchTempRed': timerSwitchTempRed,
        'spymasterEnableSwitch': spymasterEnableSwitch,
        'spymasterEnableSwitchTemp': spymasterEnableSwitchTemp,
        'enforceTimersSwitch': enforceTimersSwitch,
        'enforceTimersSwitchTemp': enforceTimersSwitchTemp,
        'minuteSettingInputBlue': minuteSettingInputBlue,
        'secondSettingInputBlue': secondSettingInputBlue,
        'minuteSettingInputRed': minuteSettingInputRed,
        'secondSettingInputRed': secondSettingInputRed,
        '_minuteLimitBlue': _minuteLimitBlue,
        '_secondLimitBlue': _secondLimitBlue,
        '_minuteLimitRed': _minuteLimitRed,
        '_secondLimitRed': _secondLimitRed,
        'currentTeam': currentTeam,
        '_currentTime': _currentTime,
        'blueScoreCounter': blueScoreCounter,
        'redScoreCounter': redScoreCounter,
        'blueFirst': blueFirst,
        'winner': winner,
        'displayWinner': displayWinner,
        'gameOver': gameOver,
        'spymasterRestart': spymasterRestart,
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
      addRoom(this.roomId, version);
    }

    showGame = true;
    notifyListeners();
  }

  void _handleJoinButtonTapped(String room) async {
    this.roomId = room;
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
            onTapPlay: _handlePlayButtonTapped,
            onTapJoin: _handleJoinButtonTapped,
          ),
        ),
        if (show404) 
          MaterialPage(key: ValueKey('UnknownKey'), child: UnknownPage())
        else if (showGame == true) 
          MaterialPage(
            child: new GameScreen(roomId: this.roomId, runFutures: this.runFutures, restart: this.restart, version: this.version),
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
    } else {
      showGame = false;
    }
    show404 = false;
  }
}

class HomeScreen extends StatefulWidget {
  
  ValueChanged<String> onTapPlay;
  ValueChanged<String> onTapJoin;

  HomeScreen({Key key, @required this.onTapPlay, @required this.onTapJoin}) : super(key: key);
  
  @override
  _HomeState createState() => _HomeState(this.onTapPlay, this.onTapJoin);
} 

class _HomeState extends State<HomeScreen> {
  String version = "Words";
  var roomId = TextEditingController();
  ValueChanged<String> onTapPlay;
  ValueChanged<String> onTapJoin;

  _HomeState(onTapPlay, onTapJoin) {
    this.onTapPlay = onTapPlay;
    this.onTapJoin = onTapJoin;
  }

  // Create the initialization Future outside of 'build':
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');

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
                  return new Scaffold(
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
                                          style: TextStyle(color: Colors.black, fontSize: 6.0.sp),
                                          textAlign: TextAlign.center,
                                          controller: roomId, 
                                          decoration: InputDecoration(
                                            hintText: "Enter Room ID",
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
                                          onPressed: () => onTapJoin(roomId.text),
                                            //Navigator.push(context, MaterialPageRoute(builder: (context) => GameScreen(version: this.version)));
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
  bool runFutures;
  bool restart; 
  String version;
  
  GameScreen({Key key, @required this.roomId, @required this.runFutures, @required this.restart, @required this.version}) : super(key: key);

  @override
  _GameState createState() => _GameState(this.roomId, this.runFutures, this.restart, this.version);
 }

class _GameState extends State<GameScreen> {

  String roomId;

  static final String DEVELOPER_KEY = ApiDevKey.DEV_KEY;

  // FIREBASE VARIABLES
  String version;
  String versionTemp;
  List wordsList;
  List imageData;
  List wordsPicturesRandomOrder = new List<String>(25);
  List colorListInteractiveString = new List<String>();
  List colorListString = new List<String>();
  List blendModeListInteractiveBool = new List<bool>();
  bool timerSwitchBlue;
  bool timerSwitchTempBlue;
  bool timerSwitchRed;
  bool timerSwitchTempRed;
  bool spymasterEnableSwitch;
  bool spymasterEnableSwitchTemp;
  bool enforceTimersSwitch;
  bool enforceTimersSwitchTemp;
  var minuteSettingInputBlue;
  var secondSettingInputBlue;
  var minuteSettingInputRed;
  var secondSettingInputRed;
  int _minuteLimitBlue;
  int _secondLimitBlue;
  int _minuteLimitRed;
  int _secondLimitRed;
  String currentTeam;
  int _currentTime;
  int blueScoreCounter;
  int redScoreCounter;
  bool blueFirst; 
  String winner = "";
  bool displayWinner = false;
  bool gameOver = false;
  bool spymasterRestart = false;

  // NON-FIREBASE VARIABLES
  bool runFutures = false;
  bool restart = false;
  List<String> wordsListFull;
  List colorListInteractive = new List<Color>(25);
  List colorList = new List<Color>(25);
  List blendModeListInteractive = new List<BlendMode>(25);
  List blendModeList = new List<BlendMode>();
  List borderColorListWhiteforOperatives = new List<Color>();
  int _currentMinutesRemaining;
  int _currentSecondsRemaining;
  bool spymaster = false;
  int blueScore;
  int redScore;
  bool errorMinuteSettingInputBlue = false;
  bool errorSecondSettingInputBlue = false;
  bool errorMinuteSettingInputRed = false;
  bool errorSecondSettingInputRed = false;

  bool roomExists = true;
  bool runRoomExistsCheck = true;
  Timer _timer;
  Random random = new Random();

  // Constructor for _GameState
   _GameState(roomId, runFutures, restart, version) {
    this.roomId = roomId;
    this.runFutures = runFutures;
    this.restart = restart;
    this.version = version;
  } 

  @override
  void initState() {
    super.initState();
    loadWords();
    fetchImages(); // Testing whether this line needs to be here to avoid having the game fail to load the first time
    getInitSettings();
    for (int i = 0; i < 25; i++) {
      blendModeList.add(BlendMode.hardLight); 
      borderColorListWhiteforOperatives.add(Colors.white);
    }
  }

  Future<void> getInitSettings() async {
    final document = await FirebaseFirestore.instance
      .collection("rooms")
      .doc(this.roomId)
      .get();
    
    timerSwitchBlue = document['timerSwitchBlue'];
    timerSwitchTempBlue = document['timerSwitchTempBlue'];
    timerSwitchRed = document['timerSwitchRed'];
    timerSwitchTempRed = document['timerSwitchTempRed'];

    spymasterEnableSwitch = document['spymasterEnableSwitch'];
    spymasterEnableSwitchTemp = document['spymasterEnableSwitchTemp'];
    enforceTimersSwitch = document['enforceTimersSwitch'];
    enforceTimersSwitchTemp = document['enforceTimersSwitchTemp'];

    currentTeam = document['currentTeam'];
    _currentTime = document['_currentTime'];
    spymasterRestart = document['spymasterRestart'];

  }

  Future<void> loadWords() async {
    wordsListFull = new List<String>();
    String wordString = await rootBundle.loadString('assets/wordlist.txt');
    LineSplitter.split(wordString).forEach((line) => wordsListFull.add(line));
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
      roomExists = false;
      print("Room doesn't exist!");
    }
  }

  Future<String> fetchImages() async {
    var fetchdata = await http.get('https://api.unsplash.com/photos/random?client_id=${DEVELOPER_KEY}&count=25');
    imageData = json.decode(fetchdata.body);
    return 'Success';
  }

  Future<void> _restart() async {
    
    wordsList = new List<String>();
    colorListString = new List<String>();
    wordsPicturesRandomOrder = new List<String>(25);
    colorListInteractiveString = new List<String>(25);
    blendModeListInteractiveBool = new List<bool>(25);

    for (int i = 0; i < blendModeListInteractiveBool.length; i++) {
      blendModeListInteractiveBool[i] = false;
    }

    await loadWords();
    _setFirstTeam();
    _wordList();
    _colorList();
    _randomizeWordsPictures();

    runFutures = false;
    restart = false; 

    if (currentTeam == "blue") {
      if (timerSwitchBlue) {
        _currentTime = _minuteLimitBlue * 60 + _secondLimitBlue;
      }
    } else if (currentTeam == "red") {
      if (timerSwitchRed) {
        _currentTime = _minuteLimitRed * 60 + _secondLimitRed;
      }
    }

    await FirebaseFirestore.instance.collection('rooms').doc(this.roomId).update({
      'version': version,
      'wordsList': wordsList, 
      'imageData': imageData,
      'wordsPicturesRandomOrder': wordsPicturesRandomOrder,
      'colorListInteractiveString': colorListInteractiveString,
      'colorListString': colorListString,
      'blendModeListInteractiveBool': blendModeListInteractiveBool,
      'currentTeam': currentTeam,
      '_currentTime': _currentTime,
      'blueScoreCounter': 0,
      'redScoreCounter': 0,
      'blueFirst': blueFirst,
      'winner': "",
      'displayWinner': false,
      'gameOver': false,
      'spymasterRestart': true
    });          
  }

  @override
  Widget build(BuildContext context) {
    if (runRoomExistsCheck) {
      return FutureBuilder(
        future: getDoc(),
        builder: (context, data) {
          if (!roomExists) {
            return UnknownPage();
          } else { 
            runRoomExistsCheck = false;
            return runFuturesRestartBuild();
          }
        }
      );
    } else {
      return runFuturesRestartBuild();
    }
  }

  Widget runFuturesRestartBuild() {
    if (runFutures) {
      return FutureBuilder(
        future: fetchImages(),
        builder: (context, data) {
          if (data.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else { 
            if (restart) {
              print("Restarting with pictures!");
              return FutureBuilder(
                future: _restart(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    print("Stream reached with pictures!");
                    return streamGameBuild(); 
                  }
                }
              );
            } else {
              print("Not restarting!");
              FirebaseFirestore.instance.collection('rooms').doc(this.roomId).update({'imageData': imageData});        
              return streamGameBuild(); 
            }
          }
        }
      );
    } else {
      if (restart) {
        print("Restarting, and no pictures!");
        return FutureBuilder(
          future: _restart(),
          builder: (context, data) {
            if (data.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              return streamGameBuild(); 
            }
          }
        );
      } else {    
        print("Not restarting, and no pictures!");
        return streamGameBuild(); 
      }
    }
  }

  Widget streamGameBuild() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(this.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        return gameBuild(context, snapshot.data);
      }
    ); 
  }

  Widget gameBuild(BuildContext context, DocumentSnapshot data) {

    // Updated all game variables from Firebase database
    version = data['version'];
    versionTemp = data['versionTemp'];
    imageData = data['imageData'];
    wordsList = data['wordsList'];
    wordsPicturesRandomOrder = data['wordsPicturesRandomOrder'];

    colorListInteractiveString = data['colorListInteractiveString'];
    colorListString = data['colorListString'];

    for (int i = 0; i < colorListString.length; i++) {
      if (colorListString[i] == "blue") {
        colorList[i] = Colors.blue;
      } else if (colorListString[i] == "red") {
        colorList[i] = Colors.red;
      } else if (colorListString[i] == "brown") {
        colorList[i] = Colors.brown[300];
      } else if (colorListString[i] == "grey") {
        colorList[i] = Colors.grey[900];
      }

      if (colorListInteractiveString[i] == null) {
        colorListInteractive[i] = null;
      } else if (colorListInteractiveString[i] == "blue") {
        colorListInteractive[i] = Colors.blue;
      } else if (colorListInteractiveString[i] == "red") {
        colorListInteractive[i] = Colors.red;
      } else if (colorListInteractiveString[i] == "brown") {
        colorListInteractive[i] = Colors.brown[300];
      } else if (colorListInteractiveString[i] == "grey") {
        colorListInteractive[i] = Colors.grey[900];
      }
            
    }

    blendModeListInteractiveBool = data['blendModeListInteractiveBool'];
    for (int j = 0; j < blendModeListInteractiveBool.length; j++) {
      if (blendModeListInteractiveBool[j]) {
        blendModeListInteractive[j] = blendModeList[j];
      }
    }

    minuteSettingInputBlue = TextEditingController()..text = data['minuteSettingInputBlue'];
    secondSettingInputBlue = TextEditingController()..text = data['secondSettingInputBlue'];
    minuteSettingInputRed = TextEditingController()..text = data['minuteSettingInputRed'];
    secondSettingInputRed = TextEditingController()..text = data['secondSettingInputRed'];

    _minuteLimitBlue = data['_minuteLimitBlue'];
    _secondLimitBlue = data['_secondLimitBlue'];
    _minuteLimitRed = data['_minuteLimitRed'];
    _secondLimitRed = data['_secondLimitRed'];

    currentTeam = data['currentTeam'];

    _currentTime = data['_currentTime'];
    if (_currentTime != null) {
      _currentMinutesRemaining = _currentTime ~/ 60;
      _currentSecondsRemaining = _currentTime % 60;
    }

    spymasterEnableSwitch = data['spymasterEnableSwitch'];
    spymasterEnableSwitchTemp = data['spymasterEnableSwitchTemp'];
    enforceTimersSwitch = data['enforceTimersSwitch'];
    enforceTimersSwitchTemp = data['enforceTimersSwitchTemp'];

    if (currentTeam == "blue") {
      if(timerSwitchBlue == true) {
        startTimer(_currentTime, data);
      }
    } 
    
    if (currentTeam == "red") {
      if(timerSwitchRed == true) {
        startTimer(_currentTime, data);
      }
    }
  
    blueFirst = data['blueFirst'];
    blueScoreCounter = data['blueScoreCounter'];
    redScoreCounter = data['redScoreCounter'];

    if (blueFirst == true) {
      blueScore = 9 - blueScoreCounter;
      redScore = 8 - redScoreCounter;
    } else {
      blueScore = 8 - blueScoreCounter;
      redScore = 9 - redScoreCounter;
    }

    winner = data['winner'];
    displayWinner = data['displayWinner'];
    gameOver = data['gameOver'];

    spymasterRestart = data['spymasterRestart'];
    if (spymasterRestart) {
      spymaster = false;
    }

    // Display the game board
    return new LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            //initialize SizerUtil()
            SizerUtil().init(constraints, orientation);
            return new Scaffold(
              drawer: MenuDrawer(data),
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
                                    _turnWidget(data),
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
                            children: _buildGridTiles(25, data),
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
                                          data.reference.update({'spymasterRestart': false});
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
                                        data.reference.update({'versionTemp': newValue});
                                        
/*                                           setState(() {
                                          versionTemp = newValue;
                                        }); */
                                      } 
                                    ),
                                    SizedBox(width: 0.5.w),
                                    ButtonTheme(  
                                      height: 5.0.w,
                                      minWidth: 14.0.w,
                                      padding: EdgeInsets.zero,
                                      child: new RaisedButton(
                                        onPressed: () {
                                          
                                          //version = versionTemp;
                                          //data.reference.update({'version': version});
                                          //if ((version == 'Pictures') || (version == "Words + Pictures")) {
                                            //fetchImages();
                                          //} 

                                          //_setFirstTeam(data);
                                          //_wordList(data);
                                          //_colorList(data);
                                          //_randomizeWordsPictures(data);
                                          
                                          /* data.reference.update({
                                            'version': version,
                                            //'versionTemp': versionTemp,
                                            //'wordsListFull': wordsListFull, 
                                            'wordsList': wordsList, 
                                            'imageData': imageData,
                                            'wordsPicturesRandomOrder': wordsPicturesRandomOrder,
                                            'colorListInteractiveString': colorListInteractiveString,
                                            'colorListString': colorListString,
                                            'blendModeListInteractiveBool': blendModeListInteractiveBool,
                                            //'timerSwitchBlue': timerSwitchBlue,
                                            //'timerSwitchTempBlue': timerSwitchTempBlue,
                                            //'timerSwitchRed': timerSwitchRed,
                                            //'timerSwitchTempRed': timerSwitchTempRed,
                                            //'spymasterEnableSwitch': spymasterEnableSwitch,
                                            //'spymasterEnableSwitchTemp': spymasterEnableSwitchTemp,
                                            //'enforceTimersSwitch': enforceTimersSwitch,
                                            //'enforceTimersSwitchTemp': enforceTimersSwitchTemp,
                                            //'minuteSettingInputBlue': minuteSettingInputBlue,
                                            //'secondSettingInputBlue': secondSettingInputBlue,
                                            //'minuteSettingInputRed': minuteSettingInputRed,
                                            //'secondSettingInputRed': secondSettingInputRed,
                                            //'_minuteLimitBlue': _minuteLimitBlue,
                                            //'_secondLimitBlue': _secondLimitBlue,
                                            //'_minuteLimitRed': _minuteLimitRed,
                                            //'_secondLimitRed': _secondLimitRed,
                                            'currentTeam': currentTeam,
                                            '_currentTime': blueFirst ? _minuteLimitBlue * 60 + _secondLimitBlue : _minuteLimitRed * 60 + _secondLimitRed,
                                            'blueScoreCounter': 0,
                                            'redScoreCounter': 0,
                                            'blueFirst': blueFirst,
                                            'winner': "red",
                                            'displayWinner': false,
                                            'gameOver': false,
                                            //'spymaster' : spymaster

                                          }); */
                                          

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
            );
          }
        );
      }
    );
  }

  List<Widget> _buildGridTiles(int numberOfTiles, DocumentSnapshot data) {
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
                
                //setState(() {
                  
                  if (colorList[index] == Colors.blue) {
                    if (colorListInteractive[index] != colorList[index]) {
                      blueScoreCounter++;
                      if (currentTeam == "red") {
                        currentTeam = "blue";
                        if(timerSwitchBlue == true) {
                          startTimer(_minuteLimitBlue * 60 + _secondLimitBlue, data);
                        }
                      }
                    }
                  } else if (colorList[index] == Colors.red) {
                    if (colorListInteractive[index] != colorList[index]) {
                      redScoreCounter++;
                      if (currentTeam == "blue") {
                        currentTeam = "red";
                        if(timerSwitchRed == true) {
                          startTimer(_minuteLimitRed * 60 + _secondLimitRed, data);
                        }
                      }
                    }
                  } else if (colorList[index] == Colors.brown[300]) {
                      if (colorListInteractive[index] != colorList[index]) {
                        if (currentTeam == "blue") {
                          currentTeam = "red";
                          if (timerSwitchRed == true) {
                            startTimer(_minuteLimitRed * 60 + _secondLimitRed, data);
                          }
                        } else if (currentTeam == "red") {
                          currentTeam = "blue";
                          if (timerSwitchBlue == true) {
                            startTimer(_minuteLimitBlue * 60 + _secondLimitBlue, data);
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

                  if (_isGameOver() == true) {
                    if (colorList[index] == Colors.blue) {
                      winner = "blue";
                    } else if (colorList[index] == Colors.red) {
                      winner = "red";
                    }
                    gameOver = true;
                    displayWinner = true;
                  }

                  if (colorList[index] == Colors.blue) {
                    colorListInteractiveString[index] = "blue";
                  } else if (colorList[index] == Colors.red) {
                    colorListInteractiveString[index] = "red";
                  } else if (colorList[index] == Colors.brown[300]) {
                    colorListInteractiveString[index] = "brown";
                  } else if (colorList[index] == Colors.grey[900]) {
                    colorListInteractiveString[index] = "grey";
                  }
                  
                  blendModeListInteractiveBool[index] = true;
                  data.reference.update({
                    'colorListInteractiveString': colorListInteractiveString,
                    'blendModeListInteractiveBool': blendModeListInteractiveBool,
                    'blueScoreCounter': blueScoreCounter,
                    'redScoreCounter': redScoreCounter,
                    'currentTeam': currentTeam,
                    'gameOver': gameOver,
                    'winner': winner,
                    'displayWinner': displayWinner
                  });
          
                //});
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
    wordsList = new List<String>();
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
    //data.reference.update({'wordsList': wordsList});
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

    //data.reference.update({
      //'blueFirst': blueFirst, 
      //'currentTeam': currentTeam
    //});
  }

  void _colorList() {

    colorListString = new List<String>();
    int numBlue, numRed, numNeutral, numAssassin;

    if (blueFirst == true) {
      numBlue = 9; numRed = 8; numNeutral = 7; numAssassin = 1;
    } else {
      numBlue = 8; numRed = 9; numNeutral = 7; numAssassin = 1;
    }

    for (int b = 0; b < numBlue; b++) {
      colorListString.add("blue");
    }
    for (int r = 0; r < numRed; r++) {
      colorListString.add("red");
    }
    for (int n = 0; n < numNeutral; n++) {
      colorListString.add("brown");
    }
    for (int a = 0; a < numAssassin; a++) {
      colorListString.add("grey");
    }

    colorListString.shuffle();

/*     for (int i = 0; i < colorListString.length; i++) {
      if (colorListString[i] == "blue") {
        colorList[i] = Colors.blue;
      } else if (colorListString[i] == "red") {
        colorList[i] = Colors.red;
      } else if (colorListString[i] == "brown") {
        colorList[i] = Colors.brown[300];
      } else if (colorListString[i] == "grey") {
        colorList[i] = Colors.grey[900];
      }
    } */

    //data.reference.update({'colorListString': colorListString});
  }

  void _randomizeWordsPictures() {
    int randomPick;
    int counter = 0;
    while (counter < 25) {
      randomPick = random.nextInt(2);
      if (randomPick == 0) {
        wordsPicturesRandomOrder[counter] = "word";
      } else if (randomPick == 1) {
        wordsPicturesRandomOrder[counter] = "picture";
      } 
      counter++;

      //data.reference.update({'wordsPicturesRandomOrder': wordsPicturesRandomOrder});
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

  Widget _turnWidget(DocumentSnapshot data) {
    if (gameOver == true) {
      return new Text("$winner wins!", style: TextStyle(color: _teamColor(), fontSize: 8.0.sp));
    } else {
      return new ButtonTheme(
        height: 5.0.w,
        minWidth: 16.0.w,
        padding: EdgeInsets.zero,
        child: new RaisedButton(
          onPressed: () {
            if (currentTeam == "blue") {
                currentTeam = "red";
                if(timerSwitchRed == true) {
                  startTimer(_minuteLimitRed * 60 + _secondLimitRed, data);
                }     
              } else if (currentTeam == "red") {
                currentTeam = "blue";
                if(timerSwitchBlue == true) {
                  startTimer(_minuteLimitBlue * 60 + _secondLimitBlue, data);
                }  
            }
            data.reference.update({'currentTeam': currentTeam});
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

  Widget MenuDrawer(DocumentSnapshot data) {
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
                builder: (context) => _dialogBuilderSettings(context, data)
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
                  SelectableText('https://detective-dingo.web.app/#/${this.roomId}/', style: TextStyle(color: Colors.black, fontStyle: FontStyle.italic, decoration: TextDecoration.underline, fontSize: 8.0.sp)),
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

  Widget _dialogBuilderSettings(BuildContext context, DocumentSnapshot data) {
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

              timerSwitchBlue = timerSwitchTempBlue;
              timerSwitchRed = timerSwitchTempRed;
              enforceTimersSwitch = enforceTimersSwitchTemp;
              spymasterEnableSwitch = spymasterEnableSwitchTemp;

              if (currentTeam == "blue" && timerSwitchBlue == true) {
                startTimer(_minuteLimitBlue * 60 + _secondLimitBlue, data);
              } else if (currentTeam == "red" && timerSwitchRed == true) {
                startTimer(_minuteLimitRed * 60 + _secondLimitRed, data);
              }
              
              data.reference.update({
                'timerSwitchTempBlue': timerSwitchTempBlue,
                'timerSwitchTempRed': timerSwitchBlue,
                'timerSwitchBlue': timerSwitchTempBlue,
                'timerSwitchRed': timerSwitchRed,
                '_minuteLimitBlue': _minuteLimitBlue,
                '_minuteLimitRed': _minuteLimitRed,
                '_secondLimitBlue': _secondLimitBlue,
                '_secondLimitRed': _secondLimitRed,
                'minuteSettingInputBlue': minuteSettingInputBlue.text,
                'secondSettingInputBlue': secondSettingInputBlue.text,
                'minuteSettingInputRed': minuteSettingInputRed.text,
                'secondSettingInputRed': secondSettingInputRed.text,
                'enforceTimersSwitchTemp': enforceTimersSwitchTemp,
                'spymasterEnableSwitchTemp': spymasterEnableSwitchTemp,
                'enforceTimersSwitch': enforceTimersSwitch,
                'spymasterEnableSwitch': spymasterEnableSwitch
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
                      Link(url: 'https://horsepaste.com/', 
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
                
  void startTimer(int timeLimit, DocumentSnapshot data) {
    
    const oneSec = const Duration(seconds: 1);
    
    if (_timer != null) {
      _timer.cancel();
    }

    _currentTime = timeLimit;
    _currentMinutesRemaining = _currentTime ~/ 60;
    _currentSecondsRemaining = _currentTime % 60;

    data.reference.update({'_currentTime': _currentTime});

    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_currentTime == 0) {
          timer.cancel();
          if (enforceTimersSwitch == true) {
            if (currentTeam == "blue") {
              currentTeam = "red";
              if (timerSwitchRed == true) {
                startTimer(_minuteLimitRed * 60 + _secondLimitRed, data);
              }
            } else if (currentTeam == "red") {
              currentTeam = "blue";
              if (timerSwitchBlue == true) {
                startTimer(_minuteLimitBlue * 60 + _secondLimitBlue, data);
              }
            }
            data.reference.update({'currentTeam': currentTeam});
          }
        } else {
          
          _currentTime--;
          _currentMinutesRemaining = _currentTime ~/ 60;
          _currentSecondsRemaining = _currentTime % 60;
          data.reference.update({'_currentTime':  _currentTime});

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
      print("Blue Timer: " + timerSwitchBlue.toString());
      return timerSwitchBlue;
    } else if (currentTeam == "red") {
      print("Red Timer: " + timerSwitchRed.toString());
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