import 'package:cloud_firestore/cloud_firestore.dart';

class Database {

  final DocumentReference reference;

  String versionTemp;
  List<String> wordsListFull;
  List<String> wordsList;
  List imageData;
  List colorListInteractive;
  List colorList;
  List blendModeListInteractive;
  List blendModeList;
  List borderColorListWhiteforOperatives;
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
  
  String minuteSettingInputBlue = '2';
  String secondSettingInputBlue = '0';
  String minuteSettingInputRed = '2';
  String secondSettingInputRed = '0';

  bool errorMinuteSettingInputBlue = false;
  bool errorSecondSettingInputBlue = false;
  bool errorMinuteSettingInputRed = false;
  bool errorSecondSettingInputRed = false;

  Database.fromMap(Map<String, dynamic> map, {this.reference})
      : versionTemp = map['versionTemp'],
        wordsListFull = map[' wordsListFull'],
        wordsList = map[' wordsList'],
        imageData = map['imageData'],
        colorListInteractive = map['colorListInteractive'],
        colorList = map['colorList'],
        blendModeListInteractive = map['blendModeListInteractive'],
        blendModeList = map['blendModeList'],
        borderColorListWhiteforOperatives = map['borderColorListWhiteforOperatives'],
        spymaster = map['spymaster'],
        spymasterEnableSwitch = map['spymasterEnableSwitch'],
        spymasterEnableSwitchTemp = map['spymasterEnableSwitchTemp'],
        enforceTimersSwitch = map['enforceTimersSwitch'],
        enforceTimersSwitchTemp = map['enforceTimersSwitchTemp'],
        restart = map['restart'],
        runFutures = map['runFutures'],
        blueScoreCounter = map['blueScoreCounter'],
        redScoreCounter = map['redScoreCounter'],
        blueScore = map['blueScore'],
        redScore = map['redScore'],
        blueFirst = map['blueFirst'],
        winner = map['winner'],
        displayWinner = map['displayWinner'],
        currentTeam = map['currentTeam'],
        gameOver = map['gameOver'],
        wordsPicturesRandomOrder = map['wordsPicturesRandomOrder'],
        _minuteLimitBlue = map['_minuteLimitBlue'],
        _secondLimitBlue = map['_secondLimitBlue'],
        _minuteLimitRed = map['_minuteLimitRed'],
        _secondLimitRed = map['_secondLimitRed'],
        _currentTime = map['_currentTime'],
        _currentMinutesRemaining = map['_currentMinutesRemaining'],
        _currentSecondsRemaining = map['_currentSecondsRemaining'],
        timerSwitchBlue = map['timerSwitchBlue'],
        timerSwitchTempBlue = map['timerSwitchTempBlue'],
        timerSwitchRed = map['timerSwitchRed'],
        timerSwitchTempRed = map['timerSwitchTempRed'],
        minuteSettingInputBlue = map['minuteSettingInputBlue'],
        secondSettingInputBlue = map['secondSettingInputBlue'],
        minuteSettingInputRed = map['minuteSettingInputRed'],
        secondSettingInputRed = map['secondSettingInputRed'],
        errorMinuteSettingInputBlue = map['errorMinuteSettingInputBlue'],
        errorSecondSettingInputBlue = map['errorSecondSettingInputBlue'],
        errorMinuteSettingInputRed = map['errorMinuteSettingInputRed'],
        errorSecondSettingInputRed = map['errorSecondSettingInputRed'];


  Database.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

}