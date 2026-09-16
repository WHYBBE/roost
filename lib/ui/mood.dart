import 'package:flutter/material.dart';

import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';

extension MoodX on Mood {
  IconData get icon => switch (this) {
        Mood.calm => Icons.spa_outlined,
        Mood.happy => Icons.sentiment_very_satisfied_outlined,
        Mood.neutral => Icons.sentiment_neutral_outlined,
        Mood.down => Icons.sentiment_dissatisfied_outlined,
        Mood.anxious => Icons.waving_hand_outlined,
      };

  Color color(BuildContext context) => switch (this) {
        Mood.calm => Colors.teal,
        Mood.happy => Colors.amber.shade700,
        Mood.neutral => Colors.blueGrey,
        Mood.down => Colors.indigo,
        Mood.anxious => Colors.deepOrange,
      };

  String label(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return switch (this) {
      Mood.calm => l.moodCalm,
      Mood.happy => l.moodHappy,
      Mood.neutral => l.moodNeutral,
      Mood.down => l.moodDown,
      Mood.anxious => l.moodAnxious,
    };
  }
}

const moodLevels = [0, 1, 2, 3, 4, 6, 9];

int heatLevel(int count) {
  for (var i = moodLevels.length - 1; i >= 0; i--) {
    if (count >= moodLevels[i]) return i;
  }
  return 0;
}
