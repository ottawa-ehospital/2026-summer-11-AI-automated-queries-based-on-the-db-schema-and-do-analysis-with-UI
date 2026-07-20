import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'goal_card.dart';

class GoalsTabContent extends StatelessWidget {
  final int actualSteps;
  final double actualSleep;
  final int actualCalories;
  final int goalSteps;
  final double goalSleep;
  final int goalCalories;
  final void Function({
    required String title,
    required String unit,
    required double currentValue,
    required double min,
    required double max,
    required bool isInt,
    required ValueChanged<double> onSave,
  })
  onEditGoal;
  final ValueChanged<double> onSaveSteps;
  final ValueChanged<double> onSaveSleep;
  final ValueChanged<double> onSaveCalories;

  const GoalsTabContent({
    super.key,
    required this.actualSteps,
    required this.actualSleep,
    required this.actualCalories,
    required this.goalSteps,
    required this.goalSleep,
    required this.goalCalories,
    required this.onEditGoal,
    required this.onSaveSteps,
    required this.onSaveSleep,
    required this.onSaveCalories,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        GoalCard(
          icon: Icons.directions_walk,
          title: l10n.dailyStepsTitle,
          actual: actualSteps.toDouble(),
          goal: goalSteps.toDouble(),
          progressLabel: _formatProgress(
            context,
            actualSteps.toDouble(),
            goalSteps.toDouble(),
            l10n.stepsUnit,
          ),
          editTooltip: l10n.editGoalTooltip,
          color: Colors.blue,
          onEdit: () => onEditGoal(
            title: l10n.stepsGoalTitle,
            unit: l10n.stepsUnit,
            currentValue: goalSteps.toDouble(),
            min: 1000,
            max: 30000,
            isInt: true,
            onSave: onSaveSteps,
          ),
        ),
        const SizedBox(height: 16),
        GoalCard(
          icon: Icons.bedtime_outlined,
          title: l10n.sleepTitle,
          actual: actualSleep,
          goal: goalSleep,
          progressLabel: _formatProgress(
            context,
            actualSleep,
            goalSleep,
            l10n.hrsUnit,
          ),
          editTooltip: l10n.editGoalTooltip,
          color: Colors.indigo,
          onEdit: () => onEditGoal(
            title: l10n.sleepTitle,
            unit: l10n.hoursUnit,
            currentValue: goalSleep,
            min: 4,
            max: 12,
            isInt: false,
            onSave: onSaveSleep,
          ),
        ),
        const SizedBox(height: 16),
        GoalCard(
          icon: Icons.local_fire_department_outlined,
          title: l10n.caloriesBurnedTitle,
          actual: actualCalories.toDouble(),
          goal: goalCalories.toDouble(),
          progressLabel: _formatProgress(
            context,
            actualCalories.toDouble(),
            goalCalories.toDouble(),
            l10n.kcalUnit,
          ),
          editTooltip: l10n.editGoalTooltip,
          color: Colors.orange,
          onEdit: () => onEditGoal(
            title: l10n.caloriesGoalTitle,
            unit: l10n.kcalUnit,
            currentValue: goalCalories.toDouble(),
            min: 100,
            max: 3000,
            isInt: true,
            onSave: onSaveCalories,
          ),
        ),
      ],
    );
  }

  String _formatProgress(
    BuildContext context,
    double actual,
    double goal,
    String unit,
  ) {
    String format(double value) => value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return context.l10n.goalProgressValue(format(actual), format(goal), unit);
  }
}
