import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils/system_icons.dart';
import '../providers/systems_provider.dart';
import '../providers/system_types_provider.dart';
import '../providers/catalogue_provider.dart';
import '../providers/projects_provider.dart';

class AddSystemSheet extends ConsumerStatefulWidget {
  final String projectId;

  const AddSystemSheet({super.key, required this.projectId});

  @override
  ConsumerState<AddSystemSheet> createState() => _AddSystemSheetState();
}

class _AddSystemSheetState extends ConsumerState<AddSystemSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final systemTypesAsync = ref.watch(systemTypesProvider);
    final industryMap = ref.watch(systemIndustriesProvider).value ?? {};
    final projectIndustry = ref.watch(projectsProvider).maybeWhen(
          data: (projects) {
            try {
              return projects.firstWhere((p) => p.id == widget.projectId).industry;
            } catch (_) {
              return null;
            }
          },
          orElse: () => null,
        );
    final addedSystems = ref.watch(systemsProvider).maybeWhen(
          data: (systems) => systems
              .where((s) => s.projectId == widget.projectId)
              .map((s) => s.systemType)
              .toSet(),
          orElse: () => const <String>{},
        );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose System Type',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnCard,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(color: AppColors.textOnCard),
                decoration: InputDecoration(
                  hintText: 'Search systems...',
                  hintStyle:
                      GoogleFonts.inter(color: AppColors.textSecondaryOnCard),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondaryOnCard),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: systemTypesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Failed to load systems',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondaryOnCard)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(systemTypesProvider),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (systemTypes) {
                  final filtered = systemTypes
                      .where((s) =>
                          s.toLowerCase().contains(_query.toLowerCase()))
                      .toList();

                  // flat list when no industry set on project
                  if (projectIndustry == null) {
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _buildTile(
                          filtered[i], addedSystems.contains(filtered[i])),
                    );
                  }

                  // sectioned list when industry is set
                  final recommended = filtered
                      .where((s) =>
                          (industryMap[s] ?? []).contains(projectIndustry))
                      .toList();
                  final others = filtered
                      .where((s) =>
                          !(industryMap[s] ?? []).contains(projectIndustry))
                      .toList();

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    children: [
                      if (recommended.isNotEmpty) ...[
                        _SectionLabel('RECOMMENDED FOR $projectIndustry'.toUpperCase()),
                        ...recommended.map((s) =>
                            _buildTile(s, addedSystems.contains(s))),
                      ],
                      if (others.isNotEmpty) ...[
                        _SectionLabel('ALL SYSTEMS'),
                        ...others
                            .map((s) => _buildTile(s, addedSystems.contains(s))),
                      ],
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Done',
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

  Widget _buildTile(String systemType, bool isAdded) {
    return _SystemTile(
      systemType: systemType,
      icon: iconForSystem(systemType),
      isAdded: isAdded,
      onTap: () {
        if (isAdded) {
          ref
              .read(systemsProvider.notifier)
              .removeSystem(widget.projectId, systemType);
        } else {
          ref
              .read(systemsProvider.notifier)
              .addSystem(widget.projectId, systemType);
        }
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryOnCard,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SystemTile extends StatelessWidget {
  final String systemType;
  final IconData icon;
  final bool isAdded;
  final VoidCallback onTap;

  const _SystemTile({
    required this.systemType,
    required this.icon,
    required this.isAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isAdded ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAdded ? AppColors.primary : AppColors.divider,
            width: isAdded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isAdded
                    ? AppColors.primary
                    : AppColors.textSecondaryOnCard,
                size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                systemType,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isAdded ? FontWeight.w600 : FontWeight.w400,
                  color: isAdded ? AppColors.primary : AppColors.textOnCard,
                ),
              ),
            ),
            if (isAdded)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              )
            else
              const Icon(Icons.add,
                  size: 20, color: AppColors.textSecondaryOnCard),
          ],
        ),
      ),
    );
  }
}
