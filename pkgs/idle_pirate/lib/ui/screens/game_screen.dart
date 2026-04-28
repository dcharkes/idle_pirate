import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../assets/images.dart';
import '../../models/item.dart';
import '../../state/game_controller.dart';
import '../../assets/translations.dart';

class GameScreen extends StatefulWidget {
  final GameController controller;

  const GameScreen({super.key, required this.controller});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _selectedAmount = 1;
  List<String> _availableLanguages = ['en'];

  @override
  void initState() {
    super.initState();
    _loadAvailableLanguages();
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final manifestStr = await rootBundle.loadString('AssetManifest.json');
      final manifestMap = json.decode(manifestStr) as Map<String, dynamic>;
      final assets = manifestMap.keys.toList();
      final langs = <String>[];
      for (final asset in assets) {
        if (asset.startsWith('packages/idle_pirate/assets/translations/') &&
            asset.endsWith('.json')) {
          final filename = asset.split('/').last;
          final lang = filename.split('.').first;
          langs.add(lang);
        }
      }
      if (!langs.contains('en')) langs.add('en');
      setState(() {
        _availableLanguages = langs;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load asset manifest: $e');
      // Fallback to just 'en' (initialized in state)
      setState(() {
        _availableLanguages = ['en'];
      });
    }
  }

  String _getLanguageLabel(String lang) {
    switch (lang) {
      case 'en':
        return '🇺🇸 EN';
      case 'pirate_en':
        return '🏴‍☠️ EN';
      case 'es':
        return '🇪🇸 ES';
      case 'pirate_es':
        return '🏴‍☠️ ES';
      case 'nl':
        return '🇳🇱 NL';
      case 'pirate_nl':
        return '🏴‍☠️ NL';
      case 'zh':
        return '🇨🇳 ZH';
      default:
        return lang.toUpperCase();
    }
  }

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
            items: _availableLanguages.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Text(_getLanguageLabel(lang)),
              );
            }).toList(),
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
                    '${translate('click_power')}: ${widget.controller.state.clickPower}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Income: ${widget.controller.state.passiveIncomePerSecond} ${translate('per_second')}',
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
                  ...Item.equipment.map((upgrade) {
                    final ownedCount = state.items[upgrade.id] ?? 0;

                    int amountToBuy = _selectedAmount;
                    final isMax = _selectedAmount == -1;
                    if (isMax) {
                      amountToBuy = state.getMaxAffordable(upgrade);
                    }

                    final cost = upgrade.getBulkCost(ownedCount, amountToBuy);
                    final canAfford =
                        state.doubloons >= cost && amountToBuy > 0;

                    final costText = amountToBuy > 0
                        ? (isMax ? '$cost D ($amountToBuy)' : '$cost D')
                        : '${upgrade.getBulkCost(ownedCount, 1)} D';

                    return Card(
                      child: ListTile(
                        leading: _getDynamicIcon(upgrade.id),
                        title: Text(
                          '${translateDynamic(upgrade.id, 'upgrade')} ($ownedCount)',
                        ),
                        subtitle: Text('+${upgrade.reward.value} click power'),
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
                  ...Item.personnel.map((generator) {
                    final ownedCount = state.items[generator.id] ?? 0;

                    int amountToBuy = _selectedAmount;
                    final isMax = _selectedAmount == -1;
                    if (isMax) {
                      amountToBuy = state.getMaxAffordable(generator);
                    }

                    final cost = generator.getBulkCost(ownedCount, amountToBuy);
                    final canAfford =
                        state.doubloons >= cost && amountToBuy > 0;

                    final costText = amountToBuy > 0
                        ? (isMax ? '$cost D ($amountToBuy)' : '$cost D')
                        : '${generator.getBulkCost(ownedCount, 1)} D';

                    final duration = generator.duration!.inSeconds.toDouble();
                    final cycleReward = generator.reward.value * duration;

                    return Card(
                      child: ListTile(
                        leading: _getDynamicIcon(generator.id),
                        title: Text(
                          '${translateDynamic(generator.id, 'crew')} ($ownedCount)',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+${cycleReward.toInt()} doubloons every ${duration.toInt()}s',
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  widget.controller.state.progress[generator
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
                  ...Item.fleet.map((generator) {
                    final ownedCount = state.items[generator.id] ?? 0;

                    int amountToBuy = _selectedAmount;
                    final isMax = _selectedAmount == -1;
                    if (isMax) {
                      amountToBuy = state.getMaxAffordable(generator);
                    }

                    final cost = generator.getBulkCost(ownedCount, amountToBuy);
                    final canAfford =
                        state.doubloons >= cost && amountToBuy > 0;

                    final costText = amountToBuy > 0
                        ? (isMax ? '$cost D ($amountToBuy)' : '$cost D')
                        : '${generator.getBulkCost(ownedCount, 1)} D';

                    final duration = generator.duration!.inSeconds.toDouble();
                    final cycleReward = generator.reward.value * duration;

                    return Card(
                      child: ListTile(
                        leading: _getDynamicIcon(generator.id),
                        title: Text(
                          '${translateDynamic(generator.id, 'fleet')} ($ownedCount)',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+${cycleReward.toInt()} doubloons every ${duration.toInt()}s',
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  widget.controller.state.progress[generator
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
