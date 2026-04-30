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
                  ItemGroup(
                    title: translate('upgrades'),
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
        Text(title),
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
        ? (isMax ? '$cost D ($amountToBuy)' : '$cost D')
        : '${item.getBulkCost(ownedCount, 1)} D';

    Widget subtitle;
    if (item.isGenerator) {
      final duration = item.duration!.inSeconds.toDouble();
      final cycleReward = item.reward.value * duration;
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('+${cycleReward.toInt()} doubloons every ${duration.toInt()}s'),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: state.progress[item] ?? 0.0,
          ),
        ],
      );
    } else {
      subtitle = Text('+${item.reward.value} click power');
    }

    return Card(
      child: ListTile(
        leading: DynamicIcon(item.id, 40, 'item').image,
        title: Text('${translateDynamic(item.id, 'item')} ($ownedCount)'),
        subtitle: subtitle,
        trailing: ElevatedButton(
          onPressed: canAfford ? () => onBuy(amountToBuy) : null,
          child: Text(costText),
        ),
      ),
    );
  }
}
