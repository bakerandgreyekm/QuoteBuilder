import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils.dart';
import '../utils/system_icons.dart';
import '../widgets/running_total_bar.dart';
import '../providers/projects_provider.dart';
import '../providers/systems_provider.dart';
import '../providers/line_items_provider.dart';
import 'add_system_sheet.dart';

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

  void _showAddSystemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSystemSheet(projectId: widget.projectId),
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
                  if (value == 'delete') {
                    _confirmDelete(project.id, project.name);
                  }
                },
                itemBuilder: (_) => [
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
              ListView(
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'SYSTEMS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryOnDark,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (_loadingSystems)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (systems.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                for (final system in systems) ...[
                  _SystemRow(
                    projectId: widget.projectId,
                    system: system,
                    onTap: () => context.push(
                      '/project/${widget.projectId}/system/${system.systemType}',
                    ),
                  ),
                ],
            ],
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
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
