import 'package:flutter/material.dart';

import '../../assets/images.dart';
import '../../models/item.dart';
import '../../models/game_state.dart';
import '../../state/game_controller.dart';
import 'package:pirate_speak/pirate_speak.dart';

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
    _loadLangs();
  }

  Future<void> _loadLangs() async {
    final langs = await loadAvailableLanguages();
    setState(() {
      _availableLanguages = langs;
    });
  }

  String _getLanguageLabel(String lang) {
    return allLanguages[lang] ?? lang.toUpperCase();
  }

  @visibleForTesting
  void setAvailableLanguagesForTesting(List<String> langs) {
    setState(() {
      _availableLanguages = langs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: Stack(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.only(top: 70.0, left: 16.0, right: 16.0),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                final state = widget.controller.state;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.passiveIncomePerSecond > 0) ...[
                        Text(
                          translate('income_per_second').replaceAll(
                            '{amount}',
                            Doubloon(
                              state.passiveIncomePerSecond,
                            ).compact,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const StaticIcon('chest', 70).image,
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFFD700,
                                ), // Gold color
                                foregroundColor: Colors.black, // Black text
                              ),
                              onPressed: widget.controller.clickChest,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      translate('click_chest'),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      translate('gain_doubloons').replaceAll(
                                        '{count}',
                                        widget.controller.state.clickPower
                                            .toString(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const StaticIcon('chest', 70).image,
                          ],
                        ),
                      ),
                      if ((state.items[Item.heavyBoots] ?? 0) > 0) ...[
                        const SizedBox(height: 16),
                        // Purchase Amount Selector
                        Align(
                          alignment: Alignment.centerRight,
                          child: SegmentedButton<int>(
                            style: SegmentedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A2332),
                              foregroundColor: Colors.white70,
                              selectedBackgroundColor: const Color(0xFF2A3548),
                              selectedForegroundColor: Colors.white,
                            ),
                            segments: [
                              ButtonSegment(value: 1, label: Text('x1')),
                              ButtonSegment(
                                value: -1,
                                label: Text(translate('max')),
                              ),
                            ],
                            selected: {_selectedAmount},
                            onSelectionChanged: (Set<int> newSelection) {
                              setState(() {
                                _selectedAmount = newSelection.first;
                              });
                            },
                          ),
                        ),
                      ],
                      ItemGroup(
                        title: translate('equipment'),
                        items: Item.equipment,
                        state: state,
                        selectedAmount: _selectedAmount,
                        onBuy: (item, amount) =>
                            widget.controller.buyUpgrades(item, amount),
                      ),
                      if ((state.items[Item.heavyBoots] ?? 0) > 0)
                        ItemGroup(
                          title: translate('crew_members'),
                          items: Item.personnel,
                          state: state,
                          selectedAmount: _selectedAmount,
                          onBuy: (item, amount) =>
                              widget.controller.buyUpgrades(item, amount),
                        ),
                      if (Item.personnel.every(
                        (item) => (state.items[item] ?? 0) > 0,
                      ))
                        ItemGroup(
                          title: translate('fleet'),
                          items: Item.fleet,
                          state: state,
                          selectedAmount: _selectedAmount,
                          onBuy: (item, amount) =>
                              widget.controller.buyUpgrades(item, amount),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Fixed Header (Doubloons)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF0C1017),
              padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, child) {
                  final state = widget.controller.state;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const StaticIcon('doubloon', 50).image,
                      const SizedBox(width: 8),
                      Text(
                        '${translate('doubloons')}: ${state.doubloons.compact}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const StaticIcon('doubloon', 50).image,
                    ],
                  );
                },
              ),
            ),
          ),
          // Floating Language and Volume Controls
          Positioned(
            top: 16,
            right: 16,
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                final volume = widget.controller.volume;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      volume == 0.0
                          ? Icons.volume_off
                          : volume < 0.5
                          ? Icons.volume_down
                          : Icons.volume_up,
                      color: Colors.white70,
                      size: 20,
                    ),
                    SizedBox(
                      width: 100,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFFFFD700),
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
                            widget.controller.setVolume(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: currentLanguage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      dropdownColor: const Color(0xFF1A2332),
                      underline: const SizedBox(),
                      items: _availableLanguages.map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Text(
                            _getLanguageLabel(lang),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) async {
                        if (newValue != null) {
                          await loadTranslations(newValue);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          // Reset Button
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'Reset Game',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A2332),
                    title: const Text(
                      'Reset Game?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to wipe all your doubloons and upgrades?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.controller.resetGame();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ItemGroup extends StatelessWidget {
  final String title;
  final List<Item> items;
  final GameState state;
  final int selectedAmount;
  final Function(Item, int) onBuy;

  const ItemGroup({
    super.key,
    required this.title,
    required this.items,
    required this.state,
    required this.selectedAmount,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    // Find the first item in this group that the user doesn't own yet
    Item? firstUnowned;
    for (final item in items) {
      if ((state.items[item] ?? 0) == 0) {
        firstUnowned = item;
        break;
      }
    }

    final visibleTiles = <Widget>[];
    for (final item in items) {
      final ownedCount = state.items[item] ?? 0;
      final isNextToBuy = item == firstUnowned;

      if (ownedCount > 0 || isNextToBuy) {
        visibleTiles.add(
          ItemTile(
            key: ValueKey(item.id),
            item: item,
            state: state,
            selectedAmount: selectedAmount,
            onBuy: (amount) => onBuy(item, amount),
          ),
        );
      }
    }

    if (visibleTiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...visibleTiles,
      ],
    );
  }
}

class ItemTile extends StatelessWidget {
  final Item item;
  final GameState state;
  final int selectedAmount;
  final Function(int) onBuy;

  const ItemTile({
    super.key,
    required this.item,
    required this.state,
    required this.selectedAmount,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final ownedCount = state.items[item] ?? 0;

    int amountToBuy = selectedAmount;
    final isMax = selectedAmount == -1;
    if (isMax) {
      amountToBuy = state.getMaxAffordable(item);
    }

    final cost = item.getBulkCost(ownedCount, amountToBuy);
    final canAfford = state.doubloons.value >= cost && amountToBuy > 0;

    final numCost = amountToBuy > 0 ? cost : item.getBulkCost(ownedCount, 1);
    final costValText = Doubloon(numCost).compact;
    final suffixText = (amountToBuy > 0 && isMax) ? ' ($amountToBuy)' : '';

    Widget subtitle;
    final duration = item.duration?.inSeconds.toDouble();
    final cycleReward = duration != null ? item.reward.value * duration : 0.0;

    if (item.isGenerator) {
      subtitle = Text(
        translate('generator_reward')
            .replaceAll('{amount}', Doubloon(cycleReward.toInt()).compact)
            .replaceAll('{seconds}', duration!.toInt().toString()),
        style: const TextStyle(color: Colors.white70),
      );
    } else {
      subtitle = Text(
        translate(
          'click_power_reward',
        ).replaceAll('{amount}', item.reward.value.toString()),
        style: const TextStyle(color: Colors.white70),
      );
    }

    return Card(
      color: const Color(0xFF1A2332),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          DynamicIcon(item.id, 60, 'item').image,
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${translateDynamic(item.id, 'item')} ($ownedCount)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey.shade700,
                            disabledForegroundColor: Colors.white38,
                          ),
                          onPressed: canAfford
                              ? () => onBuy(amountToBuy)
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(costValText),
                              const SizedBox(width: 4),
                              Text(translate('doubloons')),
                              if (suffixText.isNotEmpty) Text(suffixText),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isGenerator)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 8.0,
                    child: LinearProgressIndicator(
                      value: state.progress[item] ?? 0.0,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
