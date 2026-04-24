import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../state/game_controller.dart';
import '../../models/upgrade.dart';
import '../../state/translations.dart';

class GameScreen extends StatefulWidget {
  final GameController controller;

  const GameScreen({super.key, required this.controller});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _selectedAmount = 1;

  Widget _getDynamicIcon(String id) {
    return DynamicIcon(id, 40, 'upgrade').image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('app_title')),
        actions: [
          DropdownButton<String>(
            value: currentLanguage,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('🇺🇸 EN')),
              DropdownMenuItem(value: 'pirate_en', child: Text('🏴‍☠️ EN')),
              DropdownMenuItem(value: 'es', child: Text('🇪🇸 ES')),
              DropdownMenuItem(value: 'pirate_es', child: Text('🏴‍☠️ ES')),
              DropdownMenuItem(value: 'nl', child: Text('🇳🇱 NL')),
              DropdownMenuItem(value: 'pirate_nl', child: Text('🏴‍☠️ NL')),
            ],
            onChanged: (String? newValue) async {
              if (newValue != null) {
                await loadTranslations(newValue);
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const StaticIcon('doubloon', 30).image,
                      const SizedBox(width: 8),
                      Text(
                        '${translate('doubloons')}: ${state.doubloons}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Text(
                    '${translate('click_power')}: ${widget.controller.clickPower}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Income: ${widget.controller.passiveIncomePerSecond} ${translate('per_second')}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Purchase Amount Selector
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 1, label: Text('x1')),
                      ButtonSegment(value: 10, label: Text('x10')),
                      ButtonSegment(value: -1, label: Text(translate('max'))),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const StaticIcon('chest', 40).image,
                          const SizedBox(width: 8),
                          Text(translate('click_chest')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(translate('upgrades')),
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
                        leading: _getDynamicIcon(upgrade.id),
                        title: Text('${translateDynamic(upgrade.id, 'upgrade')} ($ownedCount)'),
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
                  Text(translate('crew_members')),
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
                        leading: _getDynamicIcon(generator.id),
                        title: Text('${translateDynamic(generator.id, 'crew')} ($ownedCount)'),
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
                  const SizedBox(height: 32),
                  Text(translate('fleet')),
                  const SizedBox(height: 8),
                  ...initialFleet.map((generator) {
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
                        leading: _getDynamicIcon(generator.id),
                        title: Text('${translateDynamic(generator.id, 'fleet')} ($ownedCount)'),
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

// Icon classes moved from models/upgrade.dart

// ignore: experimental_member_use
@RecordUse()
final class StaticIcon {
  final String id;
  final double size;
  // ignore: experimental_member_use
  const StaticIcon(@mustBeConst this.id, @mustBeConst this.size);

  Widget get image => Image.asset(
    'assets/images/$id.png',
    package: 'idle_pirate',
    width: size,
    height: size,
    errorBuilder: (context, error, stackTrace) {
      return Icon(_getIconForId(id));
    },
  );
}

// ignore: experimental_member_use
@RecordUse()
final class DynamicIcon {
  final String id;
  final double size;
  final String category;
  // ignore: experimental_member_use
  const DynamicIcon(
    this.id,
    // ignore: experimental_member_use
    @mustBeConst this.size,
    // ignore: experimental_member_use
    @mustBeConst this.category,
  );

  Widget get image => Image.asset(
    'assets/images/$id.png',
    package: 'idle_pirate',
    width: size,
    height: size,
    errorBuilder: (context, error, stackTrace) {
      return Icon(_getIconForId(id));
    },
  );
}

IconData _getIconForId(String id) {
  switch (id) {
    case 'sharper_hooks':
      return Icons.fitness_center;
    case 'better_shovels':
      return Icons.agriculture;
    case 'heavy_boots':
      return Icons.directions_walk;
    case 'cabin_boy':
      return Icons.person;
    case 'gunner':
      return Icons.security;
    case 'quartermaster':
      return Icons.star;
    case 'sloop':
    case 'brigantine':
    case 'frigate':
      return Icons.directions_boat;
    case 'doubloon':
      return Icons.monetization_on;
    case 'chest':
      return Icons.archive;
    default:
      return Icons.help_outline;
  }
}
