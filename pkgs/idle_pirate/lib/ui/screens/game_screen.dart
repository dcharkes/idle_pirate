import 'package:flutter/material.dart';

import '../../assets/images.dart';
import '../../models/item.dart';
import '../../models/game_state.dart';
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1017),
        elevation: 0,
        title: Text(
          translate('app_title'),
          style: const TextStyle(color: Colors.white),
        ),
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
                        '${translate('doubloons')}: ${state.doubloons.compact}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700), // Gold color
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${translate('click_power')}: ${widget.controller.state.clickPower}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Income: ${Doubloon(widget.controller.state.passiveIncomePerSecond).compact} ${translate('per_second')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Purchase Amount Selector
                  SegmentedButton<int>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2332),
                      foregroundColor: Colors.white70,
                      selectedBackgroundColor: const Color(0xFF2A3548),
                      selectedForegroundColor: Colors.white,
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700), // Gold color
                      foregroundColor: Colors.black, // Black text
                    ),
                    onPressed: widget.controller.clickChest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const StaticIcon('chest', 40).image,
                          const SizedBox(width: 8),
                          Text(
                            translate('click_chest'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ItemGroup(
                    title: translate('equipment'),
                    items: Item.equipment,
                    state: state,
                    selectedAmount: _selectedAmount,
                    onBuy: (item, amount) =>
                        widget.controller.buyUpgrades(item, amount),
                  ),
                  ItemGroup(
                    title: translate('crew_members'),
                    items: Item.personnel,
                    state: state,
                    selectedAmount: _selectedAmount,
                    onBuy: (item, amount) =>
                        widget.controller.buyUpgrades(item, amount),
                  ),
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
            ),
          );
        },
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
        for (final item in items)
          ItemTile(
            item: item,
            state: state,
            selectedAmount: selectedAmount,
            onBuy: (amount) => onBuy(item, amount),
          ),
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

    final costText = amountToBuy > 0
        ? (isMax
              ? '${Doubloon(cost).compact} D ($amountToBuy)'
              : '${Doubloon(cost).compact} D')
        : '${Doubloon(item.getBulkCost(ownedCount, 1)).compact} D';

    Widget subtitle;
    if (item.isGenerator) {
      final duration = item.duration!.inSeconds.toDouble();
      final cycleReward = item.reward.value * duration;
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '+${Doubloon(cycleReward.toInt()).compact} doubloons every ${duration.toInt()}s',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: state.progress[item] ?? 0.0,
          ),
        ],
      );
    } else {
      subtitle = Text(
        '+${item.reward.value} click power',
        style: const TextStyle(color: Colors.white70),
      );
    }

    return Card(
      color: const Color(0xFF1A2332), // Dark card color
      child: ListTile(
        leading: DynamicIcon(item.id, 40, 'item').image,
        title: Text(
          '${translateDynamic(item.id, 'item')} ($ownedCount)',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: subtitle,
        trailing: ElevatedButton(
          onPressed: canAfford ? () => onBuy(amountToBuy) : null,
          child: Text(costText),
        ),
      ),
    );
  }
}
