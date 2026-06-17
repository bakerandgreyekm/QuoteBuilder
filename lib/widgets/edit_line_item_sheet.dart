import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';
import '../models/line_item.dart';
import '../providers/projects_provider.dart';
import 'section_header.dart';
import 'voice_note_button.dart';

class EditLineItemSheet extends ConsumerStatefulWidget {
  final LineItem item;
  final Future<void> Function(int qty, String note, String? area) onSave;

  const EditLineItemSheet({super.key, required this.item, required this.onSave});

  @override
  ConsumerState<EditLineItemSheet> createState() => _EditLineItemSheetState();
}

class _EditLineItemSheetState extends ConsumerState<EditLineItemSheet> {
  late int _qty;
  late String? _area;
  String _lang = 'EN';
  bool _saving = false;
  bool _voiceRecording = false;
  late final TextEditingController _noteCtrl;

  double get _amount => widget.item.rate * _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.item.quantity;
    _area = widget.item.area;
    _noteCtrl = TextEditingController(text: widget.item.noteText);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_qty, _noteCtrl.text.trim(), _area);
      if (mounted) Navigator.pop(context);
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
    final projectAreas = ref.watch(projectsProvider).maybeWhen(
          data: (projects) {
            try {
              return projects
                  .firstWhere((p) => p.id == widget.item.projectId)
                  .areas;
            } catch (_) {
              return <String>[];
            }
          },
          orElse: () => <String>[],
        );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.productName,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnCard,
                      ),
                    ),
                    if (widget.item.brand.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.item.brand,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondaryOnCard,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SectionHeader(title: 'QUANTITY'),
              SheetCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            onPressed:
                                _qty > 1 ? () => setState(() => _qty--) : null,
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
                    const SizedBox(height: 4),
                    Text(
                      'Amount: ${formatINR(_amount)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (projectAreas.isNotEmpty) ...[
                SectionHeader(title: 'AREA (OPTIONAL)'),
                SheetCard(
                  child: DropdownButton<String?>(
                    value: _area,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    underline: const SizedBox.shrink(),
                    style: GoogleFonts.inter(color: AppColors.textOnCard),
                    hint: Text('No area',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondaryOnCard)),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No area',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondaryOnCard)),
                      ),
                      ...projectAreas.map((a) =>
                          DropdownMenuItem<String?>(value: a, child: Text(a))),
                    ],
                    onChanged: (v) => setState(() => _area = v),
                  ),
                ),
              ],
              SectionHeader(title: 'NOTES (OPTIONAL)'),
              SheetCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VoiceNoteButton(
                      currentLanguage: _lang,
                      onLanguageToggle: (l) => setState(() => _lang = l),
                      onRecordingChanged: (r) =>
                          setState(() => _voiceRecording = r),
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
                    Stack(
                      children: [
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          enabled: !_voiceRecording,
                          style:
                              GoogleFonts.inter(color: AppColors.textOnCard),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
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
                        if (_voiceRecording)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.primary, width: 1.5),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.mic,
                                        color: AppColors.primary, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Listening…',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
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
                            'Save Changes',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SheetCard extends StatelessWidget {
  final Widget child;
  const SheetCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
