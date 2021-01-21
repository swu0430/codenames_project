class GameRoutePath {
  final int roomId;
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