class GameState {
  final int doubloons;
  final Map<String, int> upgrades;
  final Map<String, int> generators;

  GameState({
    this.doubloons = 0,
    this.upgrades = const {},
    this.generators = const {},
  });

  GameState copyWith({
    int? doubloons,
    Map<String, int>? upgrades,
    Map<String, int>? generators,
  }) {
    return GameState(
      doubloons: doubloons ?? this.doubloons,
      upgrades: upgrades ?? this.upgrades,
      generators: generators ?? this.generators,
    );
  }
}
