import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PainScoreBadge extends StatelessWidget {
  final int score;
  final bool showLabel;

  const PainScoreBadge({
    super.key,
    required this.score,
    this.showLabel = true,
  });

  Color get _backgroundColor {
    if (score >= 12) return AppColors.success;
    if (score >= 7) return AppColors.warning;
    return AppColors.error;
  }

  String get _label {
    if (score >= 12) return 'Painful — pursue';
    if (score >= 7) return 'Moderate';
    return 'Weak signal';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _backgroundColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toString(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _backgroundColor,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              _label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _backgroundColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
