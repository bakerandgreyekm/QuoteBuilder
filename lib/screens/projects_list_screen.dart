import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';
import '../providers/projects_provider.dart';
import '../providers/systems_provider.dart';
import '../providers/line_items_provider.dart';
import '../providers/worker_provider.dart';
import '../providers/employees_provider.dart';
import '../providers/catalogue_provider.dart';
import '../widgets/loading_widgets.dart';
import '../responsive.dart';
import '../utils/web_share.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  String _query = '';
  bool _creatingProject = false;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(workerNameProvider) == 'Field Worker') {
        _showWorkerNameSheet();
      }
      _loadStats();
      // warm up so industries are ready before the New Project sheet opens
      ref.read(systemIndustriesProvider.future).ignore();
    });
  }

  Future<void> _loadStats() async {
    try {
      final projects = await ref.read(projectsProvider.future);
      await Future.wait(projects.map((p) async {
        await Future.wait([
          ref.read(systemsProvider.notifier).loadForProject(p.id),
          ref.read(lineItemsProvider.notifier).loadForProject(p.id),
        ]);
      }));
    } catch (_) {}
    if (mounted) setState(() => _statsLoaded = true);
  }

  void _showWorkerNameSheet({bool dismissible = false}) {
    showModalBottomSheet(
      context: context,
      isDismissible: dismissible,
      enableDrag: dismissible,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: kSheetConstraints,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WorkerNameSheet(),
    );
  }

  void _showNewProjectSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: kSheetConstraints,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewProjectSheet(onValidSubmit: _createProject),
    );
  }

  void _createProject(String name, String client, String location,
      String? industry, String? tier) async {
    setState(() => _creatingProject = true);
    try {
      final workerName = ref.read(workerNameProvider);
      final refNumber = await ref
          .read(projectsProvider.notifier)
          .addProject(name, client, location, workerName,
              industry: industry, tier: tier);
      if (mounted) context.push('/project/$refNumber');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingProject = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workerName = ref.watch(workerNameProvider);
    final initial = workerName.isNotEmpty ? workerName[0].toUpperCase() : 'U';
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: AppColors.textOnDark),
          tooltip: 'Open Sheets',
          onSelected: openUrl,
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              value:
                  'https://docs.google.com/spreadsheets/d/1zZQOmWe02oF7awuRkqgsMsJU1GwgcINyaXBNfUADkS4/edit',
              child: _SheetLink(label: 'Project Workbook'),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value:
                  'https://docs.google.com/spreadsheets/d/1tdLzOTnnXIVVKrgEgQtS5YVnsZT3Sepo1E4LcKuRR6Y/edit',
              child: _SheetLink(label: 'Reference Workbook'),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value:
                  'https://docs.google.com/spreadsheets/d/1CnwJR9CvDv2TV47dAPGLx-hwZUcEsnXgYYGHVaRB7ts/edit',
              child: _SheetLink(label: 'Catalogue Workbook'),
            ),
          ],
        ),
        title: Text(
          'B&G',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryOnDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showWorkerNameSheet(dismissible: true),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: Column(
            children: [
              Container(
                color: AppColors.surfaceDark,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.inter(color: AppColors.textOnCard),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textSecondaryOnCard),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondaryOnCard),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: projectsAsync.when(
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load projects',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondaryOnDark),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(projectsProvider),
                          child: Text('Retry',
                              style: GoogleFonts.inter(
                                  color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  data: (allProjects) {
                    final projects = _query.isEmpty
                        ? allProjects
                        : allProjects
                            .where((p) =>
                                p.name
                                    .toLowerCase()
                                    .contains(_query.toLowerCase()) ||
                                p.clientName
                                    .toLowerCase()
                                    .contains(_query.toLowerCase()))
                            .toList();
                    Widget buildCard(int i, {bool gridMode = false}) {
                      final p = projects[i];
                      final systemCount =
                          ref.watch(systemsProvider).maybeWhen(
                                data: (systems) => systems
                                    .where((s) => s.projectId == p.id)
                                    .length,
                                orElse: () => 0,
                              );
                      final total =
                          ref.watch(lineItemsProvider).maybeWhen(
                                data: (items) => items
                                    .where((item) => item.projectId == p.id)
                                    .fold(0.0, (s, item) => s + item.amount),
                                orElse: () => 0.0,
                              );
                      return _ProjectCard(
                        project: p,
                        systemCount: _statsLoaded ? systemCount : null,
                        total: _statsLoaded ? total : null,
                        onTap: () => context.push('/project/${p.id}'),
                        margin: gridMode
                            ? EdgeInsets.zero
                            : const EdgeInsets.only(bottom: 12),
                      );
                    }

                    if (isDesktop(context)) {
                      final rowCount = (projects.length / 2).ceil();
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rowCount,
                        itemBuilder: (_, row) {
                          final left = row * 2;
                          final right = left + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: buildCard(left, gridMode: true)),
                                const SizedBox(width: 12),
                                if (right < projects.length)
                                  Expanded(
                                      child: buildCard(right, gridMode: true))
                                else
                                  const Expanded(child: SizedBox()),
                              ],
                            ),
                          );
                        },
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: projects.length,
                      itemBuilder: (_, i) => buildCard(i),
                    );
                  },
                ),
              ),
            ],
          ),
            ),
          ),
          if (_creatingProject)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Creating project...',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewProjectSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final dynamic project;
  final int? systemCount;
  final double? total;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  const _ProjectCard({
    required this.project,
    required this.systemCount,
    required this.total,
    required this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    project.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnCard,
                    ),
                  ),
                  Text(
                    _formatDate(project.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondaryOnCard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                project.clientName,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondaryOnCard,
                ),
              ),
              Text(
                project.location,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondaryOnCard,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  systemCount == null
                      ? const ShimmerBox(
                          width: 80,
                          height: 12,
                          color: AppColors.textSecondaryOnCard,
                        )
                      : Text(
                          '$systemCount system${systemCount != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondaryOnCard,
                          ),
                        ),
                  total == null
                      ? const ShimmerBox(
                          width: 68,
                          height: 20,
                          color: AppColors.primary,
                        )
                      : Text(
                          formatINR(total!),
                          style: GoogleFonts.inter(
                            fontSize: 18,
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
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _WorkerNameSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WorkerNameSheet> createState() => _WorkerNameSheetState();
}

class _WorkerNameSheetState extends ConsumerState<_WorkerNameSheet> {
  String? _selected;

  void _submit() {
    if (_selected == null) return;
    ref.read(workerNameProvider.notifier).state = _selected!;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
              'Who are you?',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnCard,
              ),
            ),
            const SizedBox(height: 20),
            employeesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Text(
                'Failed to load names: $e',
                style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
              ),
              data: (employees) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButton<String>(
                  value: _selected,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Colors.white,
                  style: GoogleFonts.inter(color: AppColors.textOnCard),
                  hint: Row(
                    children: [
                      const Icon(Icons.person,
                          color: AppColors.textSecondaryOnCard, size: 20),
                      const SizedBox(width: 8),
                      Text('Select your name',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondaryOnCard)),
                    ],
                  ),
                  items: employees
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selected = v),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selected != null ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Continue',
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

class _NewProjectSheet extends ConsumerStatefulWidget {
  final void Function(String name, String client, String location,
      String? industry, String? tier) onValidSubmit;

  const _NewProjectSheet({required this.onValidSubmit});

  @override
  ConsumerState<_NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends ConsumerState<_NewProjectSheet> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _industry;
  String? _tier;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final client = _clientCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context);
    widget.onValidSubmit(name, client, location, _industry, _tier);
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
              'New Project',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnCard,
              ),
            ),
            const SizedBox(height: 20),
            _Field(hint: 'Project Name', icon: Icons.business, controller: _nameCtrl),
            const SizedBox(height: 12),
            _Field(hint: 'Client Name', icon: Icons.person, controller: _clientCtrl),
            const SizedBox(height: 12),
            _Field(hint: 'Location', icon: Icons.location_on, controller: _locationCtrl),
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
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Start Project',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class _Field extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const _Field({
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

/// Shared industry dropdown + tier chip row used in New/Edit project sheets.
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
        // Industry dropdown
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
        // Tier chips
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

class _SheetLink extends StatelessWidget {
  final String label;

  const _SheetLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.open_in_new,
            size: 16, color: AppColors.textSecondaryOnDark),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDark)),
      ],
    );
  }
}
