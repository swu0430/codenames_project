class GameRoutePath {
  String roomId;
  bool isUnknown;

  //Try putting database checker from "setNewRoutePath" function in here...

  GameRoutePath.home() {
    this.roomId = null;
    this.isUnknown = false;
  }

  GameRoutePath.game(String id) {
    this.roomId = id;
    this.isUnknown = false;
  }

  GameRoutePath.unknown() {
    this.roomId = null;
    this.isUnknown = true;
  }

  bool get isHomePage => roomId == null;
  bool get isGamePage => roomId != null;


/*   final String roomId;
  final bool isUnknown;

  GameRoutePath.home() 
    : roomId = null,
      isUnknown = false;

  GameRoutePath.game(this.roomId) : isUnknown = false;

  GameRoutePath.unknown() 
    : roomId = null, 
      isUnknown = true;

  bool get isHomePage => roomId == null;
  bool get isGamePage => roomId != null; */

}