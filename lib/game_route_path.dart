/* class GameRoutePath {
  static bool isHomePage = false;
  static bool isGamePage = false;
  static bool isUnknown = false;

  GameRoutePath(String roomId) {
    
    if (roomId == null) {
      isHomePage = true;
      isGamePage = false;
      isUnknown = false;
    }

    FirebaseFirestore.instance
    .collection("rooms")
    .doc(roomId)
    .get()
    .then((doc) {
      if(!doc.exists) {
        print("Room doesn't exist!");
        isHomePage = false;
        isGamePage = false;
        isUnknown = true;
      } else {
        print("Found the room!");
        isHomePage = true;
        isGamePage = false;
        isUnknown = false;
      }
    });
  }
} */
  
  
/* class GameRoutePath { 
  String roomId;
  bool isUnknown = false;

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
} */


class GameRoutePath {
  final String roomId;
  final bool isUnknown;

  GameRoutePath.home() 
    : roomId = null,
      isUnknown = false;

  GameRoutePath.game(this.roomId) : isUnknown = false;

  GameRoutePath.unknown() 
    : roomId = null, 
      isUnknown = true;

  bool get isHomePage => roomId == null;
  bool get isGamePage => roomId != null;
}
