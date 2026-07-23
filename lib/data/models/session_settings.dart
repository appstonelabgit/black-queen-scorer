/// How a session is scored.
///
/// [bid] — the original, proven bid-contract engine (caller + team + target +
/// won/lost, zero-sum). This is the default so every existing session and all
/// legacy persisted data map to it untouched.
///
/// [free] — free-score mode: an arbitrary number entered per player per round,
/// accumulated. Covers point-accrual games (Black Queen, Rummy, Hearts, …).
enum ScoreMode { bid, free }

ScoreMode _scoreModeFromName(String? name) {
  for (final m in ScoreMode.values) {
    if (m.name == name) return m;
  }
  return ScoreMode.bid;
}

class SessionSettings {
  final bool bonusEnabled;
  final int bonusAmount;
  final ScoreMode mode;

  const SessionSettings({
    required this.bonusEnabled,
    required this.bonusAmount,
    this.mode = ScoreMode.bid,
  });

  const SessionSettings.disabled()
      : bonusEnabled = false,
        bonusAmount = 0,
        mode = ScoreMode.bid;

  int get effectiveBonus => bonusEnabled ? bonusAmount : 0;

  bool get isFreeScore => mode == ScoreMode.free;

  SessionSettings copyWith({
    bool? bonusEnabled,
    int? bonusAmount,
    ScoreMode? mode,
  }) =>
      SessionSettings(
        bonusEnabled: bonusEnabled ?? this.bonusEnabled,
        bonusAmount: bonusAmount ?? this.bonusAmount,
        mode: mode ?? this.mode,
      );

  Map<String, dynamic> toJson() => {
        'bonusEnabled': bonusEnabled,
        'bonusAmount': bonusAmount,
        'mode': mode.name,
      };

  factory SessionSettings.fromJson(Map<String, dynamic> json) =>
      SessionSettings(
        bonusEnabled: json['bonusEnabled'] as bool,
        bonusAmount: json['bonusAmount'] as int,
        mode: _scoreModeFromName(json['mode'] as String?),
      );

  @override
  bool operator ==(Object other) =>
      other is SessionSettings &&
      other.bonusEnabled == bonusEnabled &&
      other.bonusAmount == bonusAmount &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(bonusEnabled, bonusAmount, mode);
}
