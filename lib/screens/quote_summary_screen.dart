import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';
import '../models/line_item.dart';
import '../providers/projects_provider.dart';
import '../providers/systems_provider.dart';
import '../providers/line_items_provider.dart';

class QuoteSummaryScreen extends ConsumerWidget {
  final String projectId;

  const QuoteSummaryScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final systemsAsync = ref.watch(systemsProvider);
    final itemsAsync = ref.watch(lineItemsProvider);

    if (projectsAsync.isLoading ||
        systemsAsync.isLoading ||
        itemsAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final projects = projectsAsync.value ?? [];
    final projectMatches = projects.where((p) => p.id == projectId).toList();
    if (projectMatches.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Project not found',
              style: GoogleFonts.inter(color: AppColors.textOnDark)),
        ),
      );
    }
    final project = projectMatches.first;
    final systems = (systemsAsync.value ?? [])
        .where((s) => s.projectId == projectId)
        .toList();
    final allItems = (itemsAsync.value ?? [])
        .where((i) => i.projectId == projectId)
        .toList();

    final double totalExGST = allItems.fold(0.0, (s, i) => s + i.amount);
    final double gst = totalExGST * 0.18;
    final double grandTotal = totalExGST + gst;

    final List<Widget> boqRows = [];
    int slNo = 0;
    for (final system in systems) {
      final sysItems =
          allItems.where((i) => i.systemType == system.systemType).toList();
      if (sysItems.isEmpty) continue;
      boqRows.add(_SectionHeader(title: system.systemType));
      for (final item in sysItems) {
        slNo++;
        boqRows.add(_ItemRow(slNo: slNo, item: item));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Quote Summary',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnCard,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.clientName,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondaryOnCard),
                  ),
                  Text(
                    project.location,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondaryOnCard),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ref: ${project.refNumber}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryOnCard),
                      ),
                      Text(
                        _formatDate(project.createdAt),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryOnCard),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 28,
                            child: Text('#', style: _tableHeaderStyle())),
                        Expanded(
                            child:
                                Text('Item', style: _tableHeaderStyle())),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 84,
                          child: Text('Amount',
                              style: _tableHeaderStyle(),
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                  if (boqRows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No items added yet.',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondaryOnCard),
                      ),
                    )
                  else
                    ...boqRows,
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _TotalRow(
                      label: 'Total (ex. GST)',
                      value: formatINR(totalExGST)),
                  const Divider(color: AppColors.divider, height: 20),
                  _TotalRow(label: 'GST @18%', value: formatINR(gst)),
                  const Divider(color: AppColors.divider, height: 20),
                  _TotalRow(
                    label: 'Grand Total',
                    value: formatINR(grandTotal),
                    isGrandTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Share Quote',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Generate PDF (Coming Soon)',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyle() => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryOnCard,
      );

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFF3F4F6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryOnCard,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int slNo;
  final LineItem item;

  const _ItemRow({required this.slNo, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$slNo',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondaryOnCard),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textOnCard),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} ${item.unit}  ·  ${formatINR(item.rate)}',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondaryOnCard),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Text(
              formatINR(item.amount),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textOnCard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGrandTotal;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isGrandTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isGrandTotal ? 16 : 14,
            fontWeight: isGrandTotal ? FontWeight.w700 : FontWeight.w400,
            color: isGrandTotal
                ? AppColors.textOnCard
                : AppColors.textSecondaryOnCard,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isGrandTotal ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: isGrandTotal ? AppColors.primary : AppColors.textOnCard,
          ),
        ),
      ],
    );
  }
}
