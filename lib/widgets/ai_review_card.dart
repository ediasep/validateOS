import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class AiReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const AiReviewCard({super.key, required this.review});

  Color get _borderColor {
    switch (review['verdict']) {
      case 'approved':
        return AppColors.success;
      case 'needs_work':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _bgTint {
    switch (review['verdict']) {
      case 'approved':
        return AppColors.success.withValues(alpha: 0.08);
      case 'needs_work':
        return AppColors.warning.withValues(alpha: 0.08);
      case 'rejected':
        return AppColors.error.withValues(alpha: 0.08);
      default:
        return Colors.transparent;
    }
  }

  String get _verdictLabel {
    switch (review['verdict']) {
      case 'approved':
        return 'Approved';
      case 'needs_work':
        return 'Needs Work';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  IconData get _verdictIcon {
    switch (review['verdict']) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'needs_work':
        return Icons.edit_note;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _bgTint,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: _borderColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_verdictIcon, color: _borderColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  _verdictLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _borderColor,
                  ),
                ),
                const Spacer(),
                if (review['score'] != null)
                  Text(
                    '${review['score']}/10',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _borderColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (review['explanation'] != null)
              Text(
                review['explanation'] as String,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            if (review['issues'] != null &&
                (review['issues'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              ...(review['issues'] as List).map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary)),
                        Expanded(
                          child: Text(
                            issue as String,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (review['suggestion'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review['suggestion'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (review['pain_signal_check'] != null) ...[
              const SizedBox(height: 8),
              Text(
                review['pain_signal_check'] as String,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (review['validation_idea'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Validation idea: ${review['validation_idea']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
