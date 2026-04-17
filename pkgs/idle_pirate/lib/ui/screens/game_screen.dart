import 'package:flutter/material.dart';
import '../../state/game_controller.dart';
import '../../models/upgrade.dart';

class GameScreen extends StatelessWidget {
  final GameController controller;

  const GameScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idle Pirate')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final state = controller.state;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Doubloons: ${state.doubloons}',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Click Power: ${controller.clickPower}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: controller.clickChest,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Click Chest'),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Upgrades:'),
                const SizedBox(height: 8),
                ...initialUpgrades.map((upgrade) {
                  final isOwned = state.upgrades.containsKey(upgrade.id);
                  return Card(
                    child: ListTile(
                      title: Text(upgrade.name),
                      subtitle: Text('+${upgrade.benefit} click power'),
                      trailing: isOwned
                          ? const Icon(Icons.check, color: Colors.green)
                          : ElevatedButton(
                              onPressed: state.doubloons >= upgrade.baseCost
                                  ? () => controller.buyUpgrade(upgrade)
                                  : null,
                              child: Text('${upgrade.baseCost} D'),
                            ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
