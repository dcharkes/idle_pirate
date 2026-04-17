import 'package:flutter/material.dart';
import '../../state/game_controller.dart';
import '../../models/upgrade.dart';

class GameScreen extends StatefulWidget {
  final GameController controller;

  const GameScreen({super.key, required this.controller});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _selectedAmount = 1; // 1, 10, or -1 for Max

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idle Pirate')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final state = widget.controller.state;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Doubloons: ${state.doubloons}',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Click Power: ${widget.controller.clickPower}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Income: ${widget.controller.passiveIncomePerSecond}/sec',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Purchase Amount Selector
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('x1')),
                      ButtonSegment(value: 10, label: Text('x10')),
                      ButtonSegment(value: -1, label: Text('Max')),
                    ],
                    selected: {_selectedAmount},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _selectedAmount = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: widget.controller.clickChest,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Click Chest'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Upgrades:'),
                  const SizedBox(height: 8),
                  ...initialUpgrades.map((upgrade) {
                    final ownedCount = state.upgrades[upgrade.id] ?? 0;

                    int amountToBuy = _selectedAmount;
                    final isMax = _selectedAmount == -1;
                    if (isMax) {
                      amountToBuy = widget.controller.getMaxAffordable(upgrade);
                    }

                    final cost = widget.controller.getBulkCost(
                      upgrade,
                      amountToBuy,
                    );
                    final canAfford =
                        state.doubloons >= cost && amountToBuy > 0;

                    final costText = amountToBuy > 0
                        ? (isMax ? '$cost D ($amountToBuy)' : '$cost D')
                        : '${widget.controller.getBulkCost(upgrade, 1)} D';

                    return Card(
                      child: ListTile(
                        title: Text('${upgrade.name} ($ownedCount)'),
                        subtitle: Text('+${upgrade.benefit} click power'),
                        trailing: ElevatedButton(
                          onPressed: canAfford
                              ? () => widget.controller.buyUpgrades(
                                  upgrade,
                                  amountToBuy,
                                )
                              : null,
                          child: Text(costText),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  const Text('Crew Members:'),
                  const SizedBox(height: 8),
                  ...initialGenerators.map((generator) {
                    final ownedCount = state.generators[generator.id] ?? 0;

                    int amountToBuy = _selectedAmount;
                    final isMax = _selectedAmount == -1;
                    if (isMax) {
                      amountToBuy = widget.controller.getMaxAffordable(
                        generator,
                      );
                    }

                    final cost = widget.controller.getBulkCost(
                      generator,
                      amountToBuy,
                    );
                    final canAfford =
                        state.doubloons >= cost && amountToBuy > 0;

                    final costText = amountToBuy > 0
                        ? (isMax ? '$cost D ($amountToBuy)' : '$cost D')
                        : '${widget.controller.getBulkCost(generator, 1)} D';

                    final duration =
                        widget.controller.generatorDurations[generator.id] ??
                        5.0;
                    final cycleReward = generator.benefit * duration;

                    return Card(
                      child: ListTile(
                        title: Text('${generator.name} ($ownedCount)'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+${cycleReward.toInt()} doubloons every ${duration.toInt()}s',
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  widget.controller.generatorsProgress[generator
                                      .id] ??
                                  0.0,
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: canAfford
                              ? () => widget.controller.buyUpgrades(
                                  generator,
                                  amountToBuy,
                                )
                              : null,
                          child: Text(costText),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
