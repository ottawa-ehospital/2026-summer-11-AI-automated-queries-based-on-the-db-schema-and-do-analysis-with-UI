import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class AssistantStyles {
  static const modulePickerPadding = EdgeInsets.fromLTRB(20, 20, 20, 18);
  static const bannerPadding = EdgeInsets.fromLTRB(20, 16, 20, 16);
  static const messagesPadding = EdgeInsets.all(AppSpacing.lg);
  static const inputPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );
  static const bubbleMargin = EdgeInsets.only(bottom: AppSpacing.md);
  static const bubblePadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const typingPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
  static const pickerItemOuterPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xs,
    vertical: AppSpacing.sm,
  );
  static const pickerItemPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.lg,
  );
  static const pickerAnimationDuration = Duration(milliseconds: 220);
  static final pickerItemRadius = AppRadii.radius(AppRadii.xl);

  static const bannerDecoration = BoxDecoration(
    gradient: AppGradients.primary,
    boxShadow: [
      BoxShadow(color: Color(0x336A1B9A), blurRadius: 8, offset: Offset(0, 4)),
    ],
  );

  static const bannerIconDecoration = BoxDecoration(
    color: Color(0x26FFFFFF),
    shape: BoxShape.circle,
  );

  static const inputDecoration = BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
    ],
  );

  static BoxDecoration messageBubbleDecoration({required bool isUser}) =>
      BoxDecoration(
        color: isUser ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadii.xl),
          topRight: const Radius.circular(AppRadii.xl),
          bottomLeft: Radius.circular(isUser ? AppRadii.xl : AppSpacing.xs),
          bottomRight: Radius.circular(isUser ? AppSpacing.xs : AppRadii.xl),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration pickerItemDecoration({required bool selected}) =>
      BoxDecoration(
        color: selected ? Colors.white : const Color(0xFFFDFDFE),
        borderRadius: pickerItemRadius,
        border: Border.all(
          color: selected ? AppColors.primaryAccent : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x246A1B9A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
      );

  static BoxDecoration pickerIconDecoration({required bool selected}) =>
      BoxDecoration(
        color: selected ? AppColors.primary : AppColors.primarySoft,
        borderRadius: AppRadii.radius(AppRadii.lg),
      );

  static BoxDecoration pickerLaunchDecoration({required bool selected}) =>
      BoxDecoration(
        color: selected ? AppColors.primary : AppColors.primarySoft,
        shape: BoxShape.circle,
        border: selected ? null : Border.all(color: AppColors.border),
      );

  static BoxDecoration typingDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: AppRadii.radius(AppRadii.xl),
    boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4)],
  );

  static BoxDecoration get emptyDisclaimerDecoration => BoxDecoration(
    color: Colors.orange.shade50,
    borderRadius: AppRadii.radius(AppRadii.sm),
    border: Border.all(color: Colors.orange.shade200),
  );

  static const bannerTitle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  static const bannerSubtitle = TextStyle(color: Colors.white70, fontSize: 12);
  static const emptyTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static const prompt = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
    fontStyle: FontStyle.italic,
  );
  static const messageText = TextStyle(fontSize: 14, height: 1.5);
  static const pickerTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static const pickerSelectedTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
  static const pickerDescription = TextStyle(
    fontSize: 12,
    height: 1.3,
    color: AppColors.textMuted,
  );
  static const pickerSelectedDescription = TextStyle(
    fontSize: 13,
    height: 1.35,
    color: AppColors.textBody,
  );
}
