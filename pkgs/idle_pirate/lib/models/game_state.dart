class GameState {
  final int doubloons;
  final Map<String, int> upgrades;

  GameState({this.doubloons = 0, this.upgrades = const {}});

  GameState copyWith({int? doubloons, Map<String, int>? upgrades}) {
    return GameState(
      doubloons: doubloons ?? this.doubloons,
      upgrades: upgrades ?? this.upgrades,
    );
  }
}
