// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../data/help_topics.dart';
import '../models/help_models.dart';

// ── Entry point: show the help sheet ─────────────────────────────────────────

void showHelpSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HelpSheet(),
  );
}

// ── Main sheet widget ─────────────────────────────────────────────────────────

class _HelpSheet extends StatefulWidget {
  const _HelpSheet();

  @override
  State<_HelpSheet> createState() => _HelpSheetState();
}

class _HelpSheetState extends State<_HelpSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  HelpCategory? _selectedCategory;
  HelpTopic? _selectedTopic;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgSurfaceDark : AppTheme.bgSurfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content — switches between views
              Expanded(
                child: _selectedTopic != null
                    ? _TopicDetailView(
                        topic: _selectedTopic!,
                        onBack: () => setState(() => _selectedTopic = null),
                        onClose: () => Navigator.of(context).pop(),
                        isDark: isDark,
                      )
                    : _MainView(
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        selectedCategory: _selectedCategory,
                        onSearchChanged: (q) => setState(() {
                          _searchQuery = q;
                          _selectedCategory = null;
                        }),
                        onCategorySelected: (c) => setState(() {
                          _selectedCategory = c;
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                        onBackToCategories: () => setState(() {
                          _selectedCategory = null;
                        }),
                        onTopicSelected: (t) => setState(() => _selectedTopic = t),
                        onClose: () => Navigator.of(context).pop(),
                        isDark: isDark,
                        scrollController: scrollController,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Main view: welcome / categories / topic list ──────────────────────────────

class _MainView extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final HelpCategory? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<HelpCategory> onCategorySelected;
  final VoidCallback onBackToCategories;
  final ValueChanged<HelpTopic> onTopicSelected;
  final VoidCallback onClose;
  final bool isDark;
  final ScrollController scrollController;

  const _MainView({
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onBackToCategories,
    required this.onTopicSelected,
    required this.onClose,
    required this.isDark,
    required this.scrollController,
  });

  static const _categories = [
    (cat: HelpCategory.documentos, label: 'Documentos', icon: Icons.description_outlined, color: Color(0xFF0D9488)),
    (cat: HelpCategory.pacientes, label: 'Pacientes', icon: Icons.people_outline_rounded, color: Color(0xFF3B82F6)),
    (cat: HelpCategory.escaneo, label: 'Escaneo', icon: Icons.document_scanner_rounded, color: Color(0xFF8B5CF6)),
    (cat: HelpCategory.general, label: 'General', icon: Icons.info_outline_rounded, color: Color(0xFF64748B)),
  ];

  static const _quickActions = [
    (label: 'Subir archivo', id: 'subir_archivo'),
    (label: 'Escanear documento', id: 'escanear_sin_ia'),
    (label: 'Registrar paciente', id: 'registrar_paciente'),
    (label: 'Procesar con IA', id: 'escanear_con_ia'),
    (label: 'Estados del documento', id: 'estados_documento'),
  ];

  @override
  Widget build(BuildContext context) {
    final topics = searchQuery.length >= 2
        ? searchTopics(searchQuery)
        : selectedCategory != null
            ? getTopicsByCategory(selectedCategory!)
            : <HelpTopic>[];

    final showFiltered = searchQuery.length >= 2 || selectedCategory != null;

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Centro de Ayuda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('SGD Clínico Móvil', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search bar
              TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar ayuda...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7), size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7), size: 18),
                          onPressed: () => onSearchChanged(''),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Body ──────────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              if (!showFiltered) ...[
                // Welcome text
                const Text(
                  '¿En qué podemos ayudarte?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecciona una categoría o busca un tema específico.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                ),
                const SizedBox(height: 20),

                // Quick actions
                Text(
                  'ACCIONES RÁPIDAS',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickActions.map((a) {
                    final topic = getTopicById(a.id);
                    if (topic == null) return const SizedBox.shrink();
                    return ActionChip(
                      label: Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                      backgroundColor: isDark ? AppTheme.bgCardDark : AppTheme.primary50,
                      side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => onTopicSelected(topic),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Categories
                Text(
                  'CATEGORÍAS',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: _categories.map((c) {
                    return _CategoryCard(
                      label: c.label,
                      icon: c.icon,
                      color: c.color,
                      isDark: isDark,
                      onTap: () => onCategorySelected(c.cat),
                    );
                  }).toList(),
                ),
              ] else ...[
                // Filtered list header
                Row(
                  children: [
                    if (selectedCategory != null)
                      TextButton.icon(
                        onPressed: onBackToCategories,
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Volver', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                      ),
                    const Spacer(),
                    Text(
                      '${topics.length} ${topics.length == 1 ? "resultado" : "resultados"}',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (topics.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        const SizedBox(height: 12),
                        const Text('No se encontraron guías', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Intenta con otras palabras clave.',
                          style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                        ),
                      ],
                    ),
                  )
                else
                  ...topics.map((t) => _TopicListItem(topic: t, isDark: isDark, onTap: () => onTopicSelected(t))),
              ],

              // Footer
              const SizedBox(height: 24),
              Divider(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
              const SizedBox(height: 12),
              Text(
                'SGD Clínico v1.0.0 — Para soporte adicional contacte al administrador del sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.bgCardDark : Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Topic list item ───────────────────────────────────────────────────────────

class _TopicListItem extends StatelessWidget {
  final HelpTopic topic;
  final bool isDark;
  final VoidCallback onTap;

  const _TopicListItem({required this.topic, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      topic.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${topic.steps.length} pasos',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Topic detail view ─────────────────────────────────────────────────────────

class _TopicDetailView extends StatelessWidget {
  final HelpTopic topic;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final bool isDark;

  const _TopicDetailView({
    required this.topic,
    required this.onBack,
    required this.onClose,
    required this.isDark,
  });

  Color _categoryColor() {
    return switch (topic.category) {
      HelpCategory.documentos => const Color(0xFF0D9488),
      HelpCategory.pacientes  => const Color(0xFF3B82F6),
      HelpCategory.escaneo    => const Color(0xFF8B5CF6),
      HelpCategory.general    => const Color(0xFF64748B),
    };
  }

  String _categoryLabel() {
    return switch (topic.category) {
      HelpCategory.documentos => 'Documentos',
      HelpCategory.pacientes  => 'Pacientes',
      HelpCategory.escaneo    => 'Escaneo',
      HelpCategory.general    => 'General',
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                    label: const Text('Volver', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_categoryLabel(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          topic.title,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topic.description,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Steps
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'PASOS (${topic.steps.length})',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...List.generate(topic.steps.length, (i) {
                final step = topic.steps[i];
                final isLast = i == topic.steps.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number + connector line
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: color,
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 40,
                              color: color.withOpacity(0.25),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(step.icon, size: 16, color: color),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        step.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),
              // Support banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('¿Necesitas más ayuda?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            'Si el problema persiste, contacta al administrador del sistema o revisa otras guías disponibles.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
