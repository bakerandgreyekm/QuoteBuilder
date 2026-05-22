import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';

class LineItemCard extends StatelessWidget {
  final String itemId;
  final String productName;
  final String brand;
  final int quantity;
  final String unit;
  final double rate;
  final String noteText;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const LineItemCard({
    super.key,
    required this.itemId,
    required this.productName,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.rate,
    this.noteText = '',
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final double amount = quantity * rate;
    final String note = noteText.length > 40
        ? '${noteText.substring(0, 40)}...'
        : noteText;

    return Dismissible(
      key: Key(itemId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => onDismissed != null,
      onDismissed: (_) => onDismissed?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnCard,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  brand,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondaryOnCard,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Qty: $quantity $unit',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondaryOnCard,
                      ),
                    ),
                    Text(
                      formatINR(amount),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (noteText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.mic,
                        size: 14,
                        color: AppColors.textSecondaryOnCard,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondaryOnCard,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
