import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';

class RunningTotalBar extends StatelessWidget {
  final double totalExGST;

  const RunningTotalBar({super.key, required this.totalExGST});

  @override
  Widget build(BuildContext context) {
    final double gst = totalExGST * 0.18;
    final double grandTotal = totalExGST + gst;

    return Container(
      height: 56,
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total (ex. GST)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textOnDark,
                ),
              ),
              Text(
                'GST @18% | Grand Total',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondaryOnDark,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatINR(totalExGST),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                formatINR(grandTotal),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondaryOnDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
