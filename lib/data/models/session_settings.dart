class SessionSettings {
  final bool bonusEnabled;
  final int bonusAmount;

  const SessionSettings({
    required this.bonusEnabled,
    required this.bonusAmount,
  });

  const SessionSettings.disabled()
      : bonusEnabled = false,
        bonusAmount = 0;

  int get effectiveBonus => bonusEnabled ? bonusAmount : 0;

  SessionSettings copyWith({bool? bonusEnabled, int? bonusAmount}) =>
      SessionSettings(
        bonusEnabled: bonusEnabled ?? this.bonusEnabled,
        bonusAmount: bonusAmount ?? this.bonusAmount,
      );

  Map<String, dynamic> toJson() => {
        'bonusEnabled': bonusEnabled,
        'bonusAmount': bonusAmount,
      };

  factory SessionSettings.fromJson(Map<String, dynamic> json) =>
      SessionSettings(
        bonusEnabled: json['bonusEnabled'] as bool,
        bonusAmount: json['bonusAmount'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is SessionSettings &&
      other.bonusEnabled == bonusEnabled &&
      other.bonusAmount == bonusAmount;

  @override
  int get hashCode => Object.hash(bonusEnabled, bonusAmount);
}
