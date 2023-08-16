import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:minesweeper/dialog.dart';
import 'package:minesweeper/model.dart';
import 'package:minesweeper/state.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MineHomePage(),
    );
  }
}

class TimeCounter extends ConsumerWidget {
  const TimeCounter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerProvider);
    return timer.when(
      data: (data) => Text((data / 1000).toString()),
      error: (_, __) => Container(),
      loading: () => Container(),
    );
  }
}

class MineHomePage extends ConsumerWidget {
  const MineHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final playState = ref.watch(playStateProvider);
    Widget ctrlButton;
    if (playState == PlayState.STARTED || playState == PlayState.RESET) {
      ctrlButton = ElevatedButton.icon(
        onPressed: () => ref.read(playStateProvider.notifier).pause(),
        icon: Icon(Icons.pause),
        label: Text("Pause"),
      );
    } else if (playState == PlayState.PAUSED) {
      ctrlButton = ElevatedButton.icon(
          onPressed: () => ref.read(playStateProvider.notifier).start(), icon: Icon(Icons.start), label: Text("Reprendre"));
    } else {
      ctrlButton = ElevatedButton.icon(
          onPressed: () {
            ref.read(gameStateProvider.notifier).reset();
            ref.read(playStateProvider.notifier).reset();
          },
          icon: Icon(Icons.start),
          label: Text("Start"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Mine Sweeper")),
      ),
      body: Column(
        children: [
          TimeCounter(),
          Padding(padding: const EdgeInsets.all(8.0), child: ctrlButton),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(1.0),
                child: ConstrainedBox(constraints: BoxConstraints(maxWidth: settings.maxX * 32), child: MinesGrid()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MineSettings extends ConsumerWidget {
  const MineSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}

class MinesGrid extends ConsumerWidget {
  const MinesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DialogNotif?>(dialogProvider, (prev, next) async {
      if (next != null) {
        await displayDialog(context, next);
      }
    });
    final game = ref.watch(gameStateProvider);
    final gridState = ref.watch(gridStateProvider);
    final playState = ref.watch(playStateProvider);
    if (playState == PlayState.STARTED || playState == PlayState.END || playState == PlayState.RESET) {
      return GridView.count(
          crossAxisCount: game.settings.maxY,
          children: gridState.grid.values
              .map((e) => MineTile(
                    disabled: playState == PlayState.END ? true : false,
                    cellState: e,
                    cell: e.cell,
                    key: ObjectKey(e.cell.coordinate),
                  ))
              .toList());
    } else {
      return Container();
    }
  }
}

class MineTile extends ConsumerWidget {
  const MineTile({this.disabled = false, required this.cellState, required this.cell, super.key});
  final CellState cellState;
  final Cell cell;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onSecondaryTap: disabled
          ? null
          : () {
              ref.read(gridStateProvider.notifier).flag(cell.coordinate);
            },
      onLongPress: disabled
          ? null
          : () {
              ref.read(gridStateProvider.notifier).flag(cell.coordinate);
            },
      onTap: disabled
          ? null
          : () {
              if (cellState.flagged) {
                return;
              }
              final gridState = ref.read(gridStateProvider.notifier);
              gridState.reveal(cell.coordinate);
              if (cell.hasBomb) {
                ref.read(playStateProvider.notifier).end();
                ref.read(dialogProvider.notifier).displayDialog(
                      message: "Perdu ! Rejouer ??",
                      validateAction: "Rejouer",
                      annulationAction: "Annuler",
                      callback: (returnValue) {
                        if (returnValue != null && returnValue) {
                          ref.read(gameStateProvider.notifier).reset();
                          ref.read(playStateProvider.notifier).reset();
                        }
                      },
                    );
                return;
              }
              final bool win = ref.read(gameStateProvider).hasWin(gridState.grid, gridState.bombCount, gridState.revelated);
              if (win) {
                ref.read(playStateProvider.notifier).end();
                ref.read(dialogProvider.notifier).displayDialog(
                      message: "Gagné ! Rejouer ??",
                      validateAction: "Rejouer",
                      annulationAction: "Annuler",
                      callback: (returnValue) {
                        if (returnValue != null && returnValue) {
                          ref.read(gameStateProvider.notifier).reset();
                          ref.read(playStateProvider.notifier).reset();
                        }
                      },
                    );
              }
            },
      child: Container(
        decoration: BoxDecoration(
          color: cellState.revealed ? Colors.white : Colors.grey,
          border: Border(
            right: const BorderSide(),
            bottom: const BorderSide(),
            left: cell.coordinate.yPos == 1 ? const BorderSide() : BorderSide.none,
            top: cell.coordinate.xPos == 1 ? const BorderSide() : BorderSide.none,
          ),
        ),
        child: Center(child: getCellIcon(cellState)),
      ),
    );
  }

  Widget getCellIcon(CellState cellState) {
    if (cellState.revealed && cell.hasBomb) {
      return const FaIcon(FontAwesomeIcons.bomb);
    }
    if (cellState.revealed) {
      return Text(cell.bombsNearCount.toString());
    }
    if (cellState.flagged) {
      return const Icon(Icons.tour);
    }
    return const Text("");
  }
}
