import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minesweeper/model.dart';

class DialogNotifier extends StateNotifier<DialogNotif?> {
  DialogNotifier(super.state);
  void displayDialog(
      {required String message, required String validateAction, required String annulationAction, void Function(bool?)? callback}) {
    state = DialogNotif(message, validateAction, annulationAction, callback);
  }
}

class GameStateNotifier extends ChangeNotifier {
  late Map<Coordinate, Cell> grid;
  final Settings settings;
  GameStateNotifier(this.settings);

  void reset() {
    createGrid();
    notifyListeners();
  }

  bool hasWin(Map<Coordinate, CellState> grid, int bombCount, int revelated) {
    if (grid.length - bombCount == revelated) {
      return true;
    }
    return false;
  }

  createGrid() {
    final List<int> bombedCells = [];
    final rnList = List<int>.generate(settings.maxX * settings.maxY, (index) => index + 1)..shuffle();
    while (bombedCells.length < settings.bombCount) {
      bombedCells.add(rnList.removeLast());
    }

    final Map<Coordinate, bool> tempGrid = {};
    int cellCount = 1;
    for (var x = 0; x < settings.maxX; x++) {
      for (var y = 0; y < settings.maxY; y++) {
        tempGrid[Coordinate(x + 1, y + 1)] = bombedCells.contains(cellCount) ? true : false;

        cellCount++;
      }
    }
    grid = {};
    for (MapEntry<Coordinate, bool> entry in tempGrid.entries) {
      final coordinate = entry.key;
      int nearBombs = 0;
      for (Coordinate nearCell in coordinate.nearsCells) {
        if (tempGrid[nearCell] != null && tempGrid[nearCell]!) {
          nearBombs++;
        }
      }
      grid[coordinate] = Cell(coordinate: coordinate, hasBomb: entry.value, bombsNearCount: nearBombs);
    }
  }
}

class PlayStateNotifier extends StateNotifier<PlayState> {
  PlayStateNotifier() : super(PlayState.INIT);

  void start({bool init = false}) {
    state = PlayState.STARTED;
  }

  void pause() {
    state = PlayState.PAUSED;
  }

  void reset() {
    state = PlayState.RESET;
  }

  void init() {
    state = PlayState.INIT;
  }

  void end() {
    state = PlayState.END;
  }
}

class GridState extends ChangeNotifier {
  final Map<Coordinate, CellState> grid;
  final int bombCount;
  int revelated = 0;
  GridState({required this.bombCount, required this.grid});

  reveal(Coordinate coord) {
    if (grid[coord]!.revealed == false) {
      if (grid[coord]!.cell.bombsNearCount == 0) {
        revealNear(coord);
      } else {
        grid[coord] = grid[coord]!.copyWith(revealed: true);
        revelated++;
      }
      if (grid.length - bombCount == revelated) {
        print("WIN");
      }
      notifyListeners();
    }
  }

  flag(Coordinate coord) {
    grid[coord] = grid[coord]!.copyWith(flagged: !grid[coord]!.flagged);
    notifyListeners();
  }

  revealNear(Coordinate coord) {
    grid[coord] = grid[coord]!.copyWith(revealed: true);
    revelated++;
    if (grid[coord]!.cell.bombsNearCount == 0) {
      for (Coordinate nextCoord in coord.nearsCells) {
        if (grid.containsKey(nextCoord) && grid[nextCoord]!.revealed == false && grid[nextCoord]!.cell.hasBomb == false) {
          revealNear(nextCoord);
        }
      }
    }
  }
}

@immutable
class CellState {
  const CellState({required this.flagged, required this.revealed, required this.cell});

  final bool flagged;
  final bool revealed;
  final Cell cell;

  CellState copyWith({bool? flagged, bool? revealed}) {
    return CellState(flagged: flagged ?? this.flagged, revealed: revealed ?? this.revealed, cell: cell);
  }
}

final gameStateProvider = ChangeNotifierProvider((ref) {
  final settings = ref.watch(settingsProvider);
  return GameStateNotifier(settings);
});

final playStateProvider = StateNotifierProvider<PlayStateNotifier, PlayState>((ref) => PlayStateNotifier());

final gridStateProvider = ChangeNotifierProvider((ref) {
  final game = ref.watch(gameStateProvider);
  game.createGrid();
  return GridState(
    bombCount: game.settings.bombCount,
    grid: game.grid.map((key, value) => MapEntry(key, CellState(cell: value, revealed: false, flagged: false))),
  );
});

final settingsProvider = Provider((ref) {
  return Settings(10, 10, 10);
});

final dialogProvider = StateNotifierProvider<DialogNotifier, DialogNotif?>((ref) {
  return DialogNotifier(null);
});

final _stopWatchProvider = Provider((ref) => Stopwatch());

final _timerProvider = Provider((ref) {
  final stopWatch = ref.watch(_stopWatchProvider);
  final playState = ref.watch(playStateProvider);
  if (playState == PlayState.INIT) {
    stopWatch.reset();
  }
  if (playState == PlayState.RESET) {
    stopWatch.reset();
    stopWatch.start();
  }
  if (playState == PlayState.STARTED) {
    stopWatch.start();
  }
  if (playState == PlayState.END) {
    stopWatch.stop();
  }
  if (playState == PlayState.PAUSED) {
    stopWatch.stop();
  }
  return stopWatch;
});

final timerProvider = StreamProvider((ref) {
  final stopWatch = ref.watch(_timerProvider);
  return Stream.periodic(
    Duration(milliseconds: 10),
    (computationCount) => stopWatch.elapsedMilliseconds,
  );
});
