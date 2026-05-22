import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';
import '../models/line_item.dart';
import '../widgets/running_total_bar.dart';
import '../widgets/line_item_card.dart';
import '../providers/line_items_provider.dart';

class SystemDetailScreen extends ConsumerWidget {
  final String projectId;
  final String systemType;

  const SystemDetailScreen({
    super.key,
    required this.projectId,
    required this.systemType,
  });

  void _showItemOptions(BuildContext context, WidgetRef ref, LineItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text('Edit',
                style: GoogleFonts.inter(color: AppColors.textOnCard)),
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Edit coming soon', style: GoogleFonts.inter()),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title:
                Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _deleteWithUndo(context, ref, item);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _deleteWithUndo(BuildContext context, WidgetRef ref, LineItem item) {
    ref.read(lineItemsProvider.notifier).deleteItem(item.projectId, item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item removed', style: GoogleFonts.inter()),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(lineItemsProvider.notifier).addItem(item),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(lineItemsProvider).maybeWhen(
          data: (all) => all
              .where((i) =>
                  i.projectId == projectId && i.systemType == systemType)
              .toList(),
          orElse: () => <LineItem>[],
        );
    final isLoading = ref.watch(lineItemsProvider).isLoading;
    final subtotal = items.fold(0.0, (s, i) => s + i.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          systemType,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                formatINR(subtotal),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: RunningTotalBar(totalExGST: subtotal),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : items.isEmpty
              ? Center(
                  child: Text(
                    'No items yet.\nTap "Add Item" to get started.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondaryOnDark,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return LineItemCard(
                      itemId: item.id,
                      productName: item.productName,
                      brand: item.brand,
                      quantity: item.quantity,
                      unit: item.unit,
                      rate: item.rate,
                      noteText: item.noteText,
                      onTap: () => _showItemOptions(context, ref, item),
                      onDismissed: () => _deleteWithUndo(context, ref, item),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context
            .push('/project/$projectId/system/$systemType/add-item'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Item',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
