import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';
import '../models/line_item.dart';
import '../models/product.dart';
import '../widgets/section_header.dart';
import '../widgets/voice_note_button.dart';
import '../providers/catalogue_provider.dart';
import '../providers/line_items_provider.dart';

class AddLineItemScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String systemType;

  const AddLineItemScreen({
    super.key,
    required this.projectId,
    required this.systemType,
  });

  @override
  ConsumerState<AddLineItemScreen> createState() => _AddLineItemScreenState();
}

class _AddLineItemScreenState extends ConsumerState<AddLineItemScreen> {
  String? _category;
  Product? _product;
  int _qty = 1;
  String _lang = 'EN';
  bool _saving = false;
  final _noteCtrl = TextEditingController();

  double get _amount => _product != null ? _product!.rate * _qty : 0;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_product == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(lineItemsProvider.notifier).addItem(
            LineItem(
              id: '',
              projectId: widget.projectId,
              systemType: widget.systemType,
              category: _category!,
              productName: _product!.name,
              brand: _product!.brand,
              unit: _product!.unit,
              quantity: _qty,
              rate: _product!.rate,
              noteText: _noteCtrl.text.trim(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item added ✓', style: GoogleFonts.inter()),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogueAsync = ref.watch(catalogueProvider);
    final catalogueLoading = catalogueAsync.isLoading;
    final categories = ref.watch(categoriesForSystemProvider(widget.systemType));
    final products = _category != null
        ? ref.watch(productsByCategoryProvider(_category!))
        : <Product>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Item',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  SectionHeader(title: 'CATEGORY'),
                  _FormCard(
                    child: catalogueLoading
                        ? Row(children: [
                            const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary)),
                            const SizedBox(width: 12),
                            Text('Loading catalogue...',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondaryOnCard)),
                          ])
                        : DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            underline: const SizedBox.shrink(),
                            style: GoogleFonts.inter(
                                color: AppColors.textOnCard),
                            hint: Text(
                              'Select category',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondaryOnCard),
                            ),
                            items: categories
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _category = v;
                              _product = null;
                            }),
                          ),
                  ),
                  SectionHeader(title: 'PRODUCT'),
                  _FormCard(
                    child: DropdownButton<Product>(
                      value: _product,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      underline: const SizedBox.shrink(),
                      style: GoogleFonts.inter(
                          color: AppColors.textOnCard, fontSize: 14),
                      hint: Text(
                        _category == null
                            ? 'Select category first'
                            : 'Select product',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondaryOnCard),
                      ),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '${p.name} — ${formatINR(p.rate)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: _category == null
                          ? null
                          : (v) => setState(() => _product = v),
                    ),
                  ),
                  SectionHeader(title: 'QUANTITY'),
                  _FormCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                onPressed: _qty > 1
                                    ? () => setState(() => _qty--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                                color: AppColors.primary,
                                iconSize: 28,
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Text(
                                '$_qty',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textOnCard,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                onPressed: () => setState(() => _qty++),
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppColors.primary,
                                iconSize: 28,
                              ),
                            ),
                          ],
                        ),
                        if (_product != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Amount: ${formatINR(_amount)}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SectionHeader(title: 'NOTES (OPTIONAL)'),
                  _FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VoiceNoteButton(
                          currentLanguage: _lang,
                          onLanguageToggle: (l) => setState(() => _lang = l),
                          onTranscript: (t) {
                            final appended = _noteCtrl.text.isEmpty
                                ? t
                                : '${_noteCtrl.text} $t';
                            _noteCtrl.value = _noteCtrl.value.copyWith(
                              text: appended,
                              selection: TextSelection.collapsed(
                                  offset: appended.length),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          style:
                              GoogleFonts.inter(color: AppColors.textOnCard),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.divider),
                            ),
                            hintText:
                                'Tap mic to add a voice note, or type here',
                            hintStyle: GoogleFonts.inter(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondaryOnCard,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_product != null && !_saving) ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Item',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
