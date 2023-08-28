class Coordinate {
  final int xPos;
  final int yPos;

  Coordinate(this.xPos, this.yPos);

  @override
  bool operator ==(other) {
    if (other is Coordinate) {
      return xPos == other.xPos && yPos == other.yPos;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(xPos, yPos);

  List<Coordinate> get nearsCells => [
        Coordinate(xPos - 1, yPos),
        Coordinate(xPos + 1, yPos),
        Coordinate(xPos, yPos - 1),
        Coordinate(xPos, yPos + 1),
        Coordinate(xPos + 1, yPos - 1),
        Coordinate(xPos + 1, yPos + 1),
        Coordinate(xPos - 1, yPos - 1),
        Coordinate(xPos - 1, yPos + 1),
      ];
}

class Cell {
  final Coordinate coordinate;
  final bool hasBomb;
  final int bombsNearCount;

  Cell({required this.coordinate, required this.hasBomb, this.bombsNearCount = 0});
}

class CellGrid {}

class Settings {
  final int maxY;
  final int maxX;
  final int bombCount;

  Settings(this.bombCount, this.maxY, this.maxX);
}

enum PlayState {
  INIT,
  STARTED,
  RESET,
  PAUSED,

  END
}

class DialogNotif {
  final String message;
  final String validateAction;
  final String annulationAction;
  final void Function(bool)? callback;

  DialogNotif(this.message, this.validateAction, this.annulationAction, [this.callback]);
}
