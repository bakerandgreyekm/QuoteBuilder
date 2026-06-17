import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';
import '../utils/system_icons.dart';
import '../widgets/running_total_bar.dart';
import '../models/line_item.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';
import '../providers/systems_provider.dart';
import '../providers/line_items_provider.dart';
import '../providers/catalogue_provider.dart';
import 'add_system_sheet.dart';
import '../responsive.dart';
import '../widgets/edit_line_item_sheet.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  bool _deleting = false;
  bool _loadingSystems = true;
  bool _viewAreas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        ref.read(systemsProvider.notifier).loadForProject(widget.projectId),
        ref.read(lineItemsProvider.notifier).loadForProject(widget.projectId),
      ]);
      if (mounted) setState(() => _loadingSystems = false);
    });
  }

  Future<void> _confirmDelete(String refNumber, String projectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Project', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "$projectName" and all its systems and line items? This cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondaryOnCard)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(projectsProvider.notifier).deleteProject(refNumber);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
        );
      }
    }
  }

  void _showEditSheet(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: kSheetConstraints,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProjectSheet(
        project: project,
        onSave: (name, client, location, industry, tier) async {
          await ref.read(projectsProvider.notifier).updateProject(
                refNumber: project.refNumber,
                name: name,
                clientName: client,
                location: location,
                industry: industry,
                tier: tier,
              );
        },
      ),
    );
  }

  void _showAreasManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: kSheetConstraints,
      builder: (_) => _AreasManagerSheet(projectId: widget.projectId),
    );
  }

  void _showAddSystemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: kSheetConstraints,
      builder: (_) => AddSystemSheet(projectId: widget.projectId),
    );
  }

  void _showAreaItemOptions(BuildContext context, LineItem item) {
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
            title: Text('Edit', style: GoogleFonts.inter(color: AppColors.textOnCard)),
            onTap: () {
              Navigator.pop(ctx);
              _showAreaItemEdit(context, item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              ref.read(lineItemsProvider.notifier).deleteItem(item.projectId, item.id);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAreaItemEdit(BuildContext context, LineItem item) {
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

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Error: $e',
              style: GoogleFonts.inter(color: AppColors.textOnDark)),
        ),
      ),
      data: (projects) {
        final matches = projects.where((p) => p.id == widget.projectId).toList();
        if (matches.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text('Project not found',
                  style: GoogleFonts.inter(color: AppColors.textOnDark)),
            ),
          );
        }
        final project = matches.first;

        final systems = ref.watch(systemsProvider).maybeWhen(
              data: (s) =>
                  s.where((sys) => sys.projectId == widget.projectId).toList(),
              orElse: () => [],
            );
        final total = ref.watch(lineItemsProvider).maybeWhen(
              data: (items) => items
                  .where((i) => i.projectId == widget.projectId)
                  .fold(0.0, (s, i) => s + i.amount),
              orElse: () => 0.0,
            );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(
              project.name,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDark,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _deleting
                    ? null
                    : () => context.push('/project/${widget.projectId}/quote'),
                child: Text(
                  'View Quote',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditSheet(context, project);
                  } else if (value == 'delete') {
                    _confirmDelete(project.id, project.name);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('Edit Project', style: GoogleFonts.inter()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text('Delete Project',
                            style: GoogleFonts.inter(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: RunningTotalBar(totalExGST: total),
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                  child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D3D3D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 14,
                            color: AppColors.textSecondaryOnDark),
                        const SizedBox(width: 6),
                        Text(project.clientName,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textOnDark)),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondaryOnDark),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(project.location,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textOnDark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.tag,
                            size: 14,
                            color: AppColors.textSecondaryOnDark),
                        const SizedBox(width: 6),
                        Text(project.refNumber,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondaryOnDark)),
                        const SizedBox(width: 16),
                        const Icon(Icons.calendar_today,
                            size: 12,
                            color: AppColors.textSecondaryOnDark),
                        const SizedBox(width: 4),
                        Text(_formatDate(project.createdAt),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondaryOnDark)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (project.industry != null)
                          _InfoBadge(
                            icon: Icons.business_center_outlined,
                            label: project.industry!,
                          ),
                        if (project.tier != null)
                          _InfoBadge(
                            icon: Icons.star_outline,
                            label: project.tier!,
                            highlight: project.tier == 'Premium',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Systems',
                          selected: !_viewAreas,
                          onTap: () => setState(() => _viewAreas = false),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Areas',
                          selected: _viewAreas,
                          onTap: () => setState(() => _viewAreas = true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_viewAreas) ...[
                if (_loadingSystems)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (systems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Center(
                      child: Text(
                        'No systems added yet.\nTap "Add System" to get started.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondaryOnDark,
                        ),
                      ),
                    ),
                  )
                else
                  for (final system in systems)
                    _SystemRow(
                      projectId: widget.projectId,
                      system: system,
                      onTap: () => context.push(
                        '/project/${widget.projectId}/system/${system.systemType}',
                      ),
                    ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                    onTap: () => _showAreasManager(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune,
                              size: 13, color: AppColors.textOnCard),
                          const SizedBox(width: 6),
                          Text(
                            'Manage Areas',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnCard,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
                ..._buildAreaWidgets(project),
              ],
            ],
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
                        Text('Deleting project...',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSystemSheet(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add System',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAreaWidgets(Project project) {
    final lineItems = ref.watch(lineItemsProvider).maybeWhen(
          data: (items) =>
              items.where((i) => i.projectId == widget.projectId).toList(),
          orElse: () => <LineItem>[],
        );

    if (project.areas.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: Text(
              'No areas defined yet.\nTap "+ Add Area" above to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondaryOnDark),
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final area in project.areas) {
      final items = lineItems.where((i) => i.area == area).toList();
      widgets.add(_AreaSectionLabel(area));
      if (items.isEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
          child: Text('No items',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondaryOnDark)),
        ));
      } else {
        for (final item in items) {
          widgets.add(_AreaItemRow(
            item: item,
            onTap: () => _showAreaItemOptions(context, item),
          ));
        }
      }
    }

    final generalItems = lineItems.where((i) {
      final a = i.area;
      return a == null || a.isEmpty || !project.areas.contains(a);
    }).toList();
    if (generalItems.isNotEmpty) {
      widgets.add(const _AreaSectionLabel('GENERAL'));
      for (final item in generalItems) {
        widgets.add(_AreaItemRow(
          item: item,
          onTap: () => _showAreaItemOptions(context, item),
        ));
      }
    }

    return widgets;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _EditProjectSheet extends ConsumerStatefulWidget {
  final Project project;
  final Future<void> Function(String name, String client, String location,
      String? industry, String? tier) onSave;

  const _EditProjectSheet({required this.project, required this.onSave});

  @override
  ConsumerState<_EditProjectSheet> createState() => _EditProjectSheetState();
}

class _EditProjectSheetState extends ConsumerState<_EditProjectSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _clientCtrl;
  late final TextEditingController _locationCtrl;
  String? _industry;
  String? _tier;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.name);
    _clientCtrl = TextEditingController(text: widget.project.clientName);
    _locationCtrl = TextEditingController(text: widget.project.location);
    _industry = widget.project.industry;
    _tier = widget.project.tier;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(name, _clientCtrl.text.trim(),
          _locationCtrl.text.trim(), _industry, _tier);
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
    final industries = ref.watch(allIndustriesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),
            Text(
              'Edit Project',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnCard,
              ),
            ),
            const SizedBox(height: 20),
            _EditField(hint: 'Project Name', icon: Icons.business, controller: _nameCtrl),
            const SizedBox(height: 12),
            _EditField(hint: 'Client Name', icon: Icons.person, controller: _clientCtrl),
            const SizedBox(height: 12),
            _EditField(hint: 'Location', icon: Icons.location_on, controller: _locationCtrl),
            const SizedBox(height: 16),
            _IndustryTierFields(
              industries: industries,
              selectedIndustry: _industry,
              selectedTier: _tier,
              onIndustryChanged: (v) => setState(() => _industry = v),
              onTierChanged: (v) => setState(() => _tier = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
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
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _InfoBadge({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: highlight ? AppColors.primary : AppColors.textSecondaryOnDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: highlight ? AppColors.primary : AppColors.textSecondaryOnDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndustryTierFields extends StatelessWidget {
  final List<String> industries;
  final String? selectedIndustry;
  final String? selectedTier;
  final ValueChanged<String?> onIndustryChanged;
  final ValueChanged<String?> onTierChanged;

  const _IndustryTierFields({
    required this.industries,
    required this.selectedIndustry,
    required this.selectedTier,
    required this.onIndustryChanged,
    required this.onTierChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButton<String?>(
            value: selectedIndustry,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: Colors.white,
            style: GoogleFonts.inter(color: AppColors.textOnCard),
            hint: Row(
              children: [
                const Icon(Icons.business_center_outlined,
                    size: 20, color: AppColors.textSecondaryOnCard),
                const SizedBox(width: 8),
                Text('Industry (optional)',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondaryOnCard)),
              ],
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('Not specified',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondaryOnCard)),
              ),
              ...industries.map((ind) =>
                  DropdownMenuItem<String?>(value: ind, child: Text(ind))),
            ],
            onChanged: onIndustryChanged,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Tier:',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondaryOnCard)),
            const SizedBox(width: 12),
            ...['Value', 'Premium'].map((t) {
              final selected = selectedTier == t;
              return GestureDetector(
                onTap: () => onTierChanged(selected ? null : t),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondaryOnCard,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const _EditField({
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: AppColors.textOnCard),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondaryOnCard),
        prefixIcon: Icon(icon, color: AppColors.textSecondaryOnCard),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }
}

class _AreasManagerSheet extends ConsumerStatefulWidget {
  final String projectId;

  const _AreasManagerSheet({required this.projectId});

  @override
  ConsumerState<_AreasManagerSheet> createState() =>
      _AreasManagerSheetState();
}

class _AreasManagerSheetState extends ConsumerState<_AreasManagerSheet> {
  final _addCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  List<String> get _areas => ref.read(projectsProvider).maybeWhen(
        data: (projects) {
          try {
            return projects
                .firstWhere((p) => p.id == widget.projectId)
                .areas;
          } catch (_) {
            return <String>[];
          }
        },
        orElse: () => <String>[],
      );

  Future<void> _save(List<String> newAreas) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(projectsProvider.notifier)
          .updateAreas(widget.projectId, newAreas);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _add() async {
    final name = _addCtrl.text.trim();
    if (name.isEmpty || _areas.contains(name)) return;
    _addCtrl.clear();
    await _save([..._areas, name]);
  }

  Future<void> _delete(String name) async {
    await _save(_areas.where((a) => a != name).toList());
  }

  Future<void> _rename(String old) async {
    final ctrl = TextEditingController(text: old);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Rename Area',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDark)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.inter(color: AppColors.textOnDark),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Colors.white24)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary)),
          ),
          onSubmitted: (v) {
            final n = v.trim();
            if (n.isNotEmpty) Navigator.pop(ctx, n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondaryOnDark)),
          ),
          TextButton(
            onPressed: () {
              final n = ctrl.text.trim();
              if (n.isNotEmpty) Navigator.pop(ctx, n);
            },
            child: Text('Save',
                style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (updated == null || updated == old || !mounted) return;
    final newList = _areas.map((a) => a == old ? updated : a).toList();
    await _save(newList);
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(projectsProvider).maybeWhen(
          data: (projects) {
            try {
              return projects
                  .firstWhere((p) => p.id == widget.projectId)
                  .areas;
            } catch (_) {
              return <String>[];
            }
          },
          orElse: () => <String>[],
        );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Areas',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDark)),
                  ),
                  if (_saving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (areas.isNotEmpty) ...[
              const Divider(color: Colors.white12, height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: areas.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (_, i) {
                    final area = areas[i];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.fromLTRB(20, 0, 8, 0),
                      title: Text(area,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textOnDark)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18,
                                color: AppColors.textSecondaryOnDark),
                            onPressed:
                                _saving ? null : () => _rename(area),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            onPressed:
                                _saving ? null : () => _delete(area),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16,
                  MediaQuery.of(context).viewInsets.bottom + 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addCtrl,
                      style: GoogleFonts.inter(
                          color: AppColors.textOnDark),
                      textCapitalization: TextCapitalization.words,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'New area name',
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textSecondaryOnDark),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.white24)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primary)),
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _add,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                      ),
                      child: Text('Add',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondaryOnDark,
          ),
        ),
      ),
    );
  }
}

class _AreaSectionLabel extends StatelessWidget {
  final String label;

  const _AreaSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryOnDark.withValues(alpha: 0.6),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaItemRow extends StatelessWidget {
  final LineItem item;
  final VoidCallback onTap;

  const _AreaItemRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnCard,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.systemType,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantity} × ${formatINR(item.rate)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondaryOnCard,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            formatINR(item.amount),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnCard,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SystemRow extends ConsumerWidget {
  final String projectId;
  final dynamic system;
  final VoidCallback onTap;

  const _SystemRow({
    required this.projectId,
    required this.system,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sysItems = ref.watch(lineItemsProvider).maybeWhen(
          data: (items) => items
              .where((i) =>
                  i.projectId == projectId &&
                  i.systemType == system.systemType)
              .toList(),
          orElse: () => [],
        );
    final itemCount = sysItems.length;
    final subtotal = sysItems.fold(0.0, (s, i) => s + i.amount);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Icon(iconForSystem(system.systemType),
                color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    system.systemType,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnCard,
                    ),
                  ),
                  if (itemCount > 0)
                    Text(
                      '$itemCount item${itemCount != 1 ? 's' : ''} · ${formatINR(subtotal)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondaryOnCard,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryOnCard,
            ),
          ],
        ),
      ),
    );
  }
}
