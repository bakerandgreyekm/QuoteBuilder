import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';

class LineItemCard extends StatefulWidget {
  final String itemId;
  final String productName;
  final String brand;
  final int quantity;
  final String unit;
  final double rate;
  final String noteText;
  final VoidCallback? onTap;
  final Future<bool> Function()? onConfirmDismiss;

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
    this.onConfirmDismiss,
  });

  @override
  State<LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends State<LineItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final double amount = widget.quantity * widget.rate;

    return Dismissible(
      key: Key(widget.itemId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) =>
          widget.onConfirmDismiss?.call() ?? Future.value(false),
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
        onTap: widget.onTap,
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
                  widget.productName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnCard,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.brand,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondaryOnCard,
                  ),
                ),
                if (widget.noteText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final labelStyle = GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        );
                        final bodyStyle = GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textOnCard,
                        );
                        final toggleStyle = GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        );
                        final tp = TextPainter(
                          text: TextSpan(children: [
                            TextSpan(text: 'Note: ', style: labelStyle),
                            TextSpan(text: widget.noteText, style: bodyStyle),
                          ]),
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        )..layout(maxWidth: constraints.maxWidth);
                        final overflows = tp.didExceedMaxLines;

                        if (!overflows) {
                          return RichText(
                            text: TextSpan(children: [
                              TextSpan(text: 'Note: ', style: labelStyle),
                              TextSpan(text: widget.noteText, style: bodyStyle),
                            ]),
                          );
                        }

                        if (_expanded) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(text: 'Note: ', style: labelStyle),
                                  TextSpan(
                                      text: widget.noteText, style: bodyStyle),
                                ]),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _expanded = false),
                                  child: Text('Show less', style: toggleStyle),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(children: [
                                  TextSpan(text: 'Note: ', style: labelStyle),
                                  TextSpan(
                                      text: widget.noteText, style: bodyStyle),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _expanded = true),
                              child: Text('Show more', style: toggleStyle),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const Divider(height: 18, color: AppColors.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${formatINR(widget.rate)} each  ×  ${widget.quantity} ${widget.unit}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondaryOnCard,
                      ),
                    ),
                    Text(
                      formatINR(amount),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
