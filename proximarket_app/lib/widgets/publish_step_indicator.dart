import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PublishStepIndicator extends StatelessWidget {
  final int currentStep; // 0-indexed
  final List<String> labels;

  const PublishStepIndicator({
    super.key,
    required this.currentStep,
    this.labels = const ['Description', 'Détails', 'Photos', 'Lieu', 'Aperçu'],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i ~/ 2) < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: leftDone ? AppTheme.primary : AppTheme.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < currentStep;
          final active = stepIndex == currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? AppTheme.primary : Colors.transparent,
                  border: Border.all(
                    color: done || active
                        ? AppTheme.primary
                        : AppTheme.textTertiary,
                    width: 1.5,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
