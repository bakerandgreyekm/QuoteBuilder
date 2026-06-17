import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';
import '../models/line_item.dart';
import '../widgets/running_total_bar.dart';
import '../widgets/line_item_card.dart';
import '../widgets/section_header.dart';
import '../widgets/voice_note_button.dart';
import '../providers/line_items_provider.dart';
import '../providers/projects_provider.dart';
import '../responsive.dart';
import '../widgets/edit_line_item_sheet.dart';

class SystemDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String systemType;

  const SystemDetailScreen({
    super.key,
    required this.projectId,
    required this.systemType,
  });

  @override
  ConsumerState<SystemDetailScreen> createState() => _SystemDetailScreenState();
}

class _SystemDetailScreenState extends ConsumerState<SystemDetailScreen> {
  bool _deleting = false;

  Future<bool> _deleteItem(LineItem item) async {
    setState(() => _deleting = true);
    try {
      await ref
          .read(lineItemsProvider.notifier)
          .deleteItem(item.projectId, item.id);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e', style: GoogleFonts.inter()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showEditSheet(BuildContext context, LineItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: kSheetConstraints,
      builder: (_) => EditLineItemSheet(
        item: item,
        onSave: (qty, note, area) => ref
            .read(lineItemsProvider.notifier)
            .updateItem(
              refNumber: item.projectId,
              itemId: item.id,
              quantity: qty,
              noteText: note,
              area: area,
            ),
      ),
    );
  }

  void _showItemOptions(BuildContext context, LineItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      constraints: kSheetConstraints,
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
              _showEditSheet(context, item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title:
                Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _deleteItem(item);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(lineItemsProvider).maybeWhen(
          data: (all) => all
              .where((i) =>
                  i.projectId == widget.projectId &&
                  i.systemType == widget.systemType)
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
          widget.systemType,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDark,
          ),
        ),
      ),
      bottomNavigationBar: RunningTotalBar(totalExGST: subtotal),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
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
                              onTap: () => _showItemOptions(context, item),
                              onConfirmDismiss: () => _deleteItem(item),
                            );
                          },
                        ),
            ),
          ),
          if (_deleting)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Deleting item...',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _deleting
            ? null
            : () => context.push(
                '/project/${widget.projectId}/system/${widget.systemType}/add-item'),
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

