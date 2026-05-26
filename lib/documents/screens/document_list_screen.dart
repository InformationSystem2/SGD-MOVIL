// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/navigation_drawer.dart';
import '../../security/services/auth_service.dart';
import '../models/document_models.dart';
import '../services/document_service.dart';
import '../../patients/services/patient_service.dart';
import '../services/document_template_service.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final docService = Provider.of<DocumentService>(context, listen: false);
    final patientService = Provider.of<PatientService>(context, listen: false);
    final templateService = Provider.of<DocumentTemplateService>(context, listen: false);
    
    await Future.wait([
      docService.fetchDocuments(),
      patientService.fetchPatients(),
      templateService.fetchTemplates(),
    ]);
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.DRAFT:
        return AppTheme.warning;
      case DocumentStatus.PENDING_REVIEW:
        return AppTheme.info;
      case DocumentStatus.REJECTED:
        return AppTheme.error;
      case DocumentStatus.FINALIZED:
        return AppTheme.success;
    }
  }

  String _getStatusLabel(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.DRAFT:
        return 'Borrador';
      case DocumentStatus.PENDING_REVIEW:
        return 'En Revisión';
      case DocumentStatus.REJECTED:
        return 'Rechazado';
      case DocumentStatus.FINALIZED:
        return 'Finalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final docService = Provider.of<DocumentService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter documents by search query
    final filteredDocs = docService.documents.where((doc) {
      final query = _searchQuery.toLowerCase();
      final patientMatch = doc.patientName.toLowerCase().contains(query);
      final docNumMatch = doc.patientDocumentNumber?.toLowerCase().contains(query) ?? false;
      final templateMatch = doc.templateName?.toLowerCase().contains(query) ?? false;
      final sourceMatch = (doc.isExternalSource ? 'externo' : 'plantilla').contains(query);
      return patientMatch || docNumMatch || templateMatch || sourceMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SGD Clínico',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          // Current User Profile Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.primary.withOpacity(0.1) : AppTheme.primary50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  authService.currentUser ?? 'User',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(activeRoute: '/documents'),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por paciente, documento o plantilla...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Main Documents List with Pull to Refresh
          Expanded(
            child: docService.isLoading && docService.documents.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: AppTheme.primary,
                    child: docService.errorMessage != null
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                              const SizedBox(height: 16),
                              const Text(
                                'Error al cargar documentos',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                docService.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _refreshData,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          )
                        : filteredDocs.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                  Icon(
                                    Icons.description_outlined,
                                    size: 72,
                                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Sin Documentos',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No se encontraron resultados para "$_searchQuery"'
                                        : 'Aún no se han registrado documentos en el sistema.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filteredDocs.length,
                                itemBuilder: (context, index) {
                                  final doc = filteredDocs[index];
                                  final statusColor = _getStatusColor(doc.status);
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          '/document-detail',
                                          arguments: doc,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Patient Header
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    doc.patientName,
                                                    style: theme.textTheme.titleMedium,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: statusColor.withOpacity(0.4),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _getStatusLabel(doc.status),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // CI Document Number if available
                                            if (doc.patientDocumentNumber != null &&
                                                doc.patientDocumentNumber!.isNotEmpty)
                                              Text(
                                                'CI: ${doc.patientDocumentNumber}',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            const Divider(height: 20),
                                            // Document Info
                                            Row(
                                              children: [
                                                Icon(
                                                  doc.isExternalSource
                                                      ? Icons.attachment_rounded
                                                      : Icons.assignment_outlined,
                                                  size: 16,
                                                  color: AppTheme.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    doc.isExternalSource
                                                        ? 'Documento Adjunto (Externo)'
                                                        : (doc.templateName ?? 'Documento Clínico'),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Uploader and Date footer
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person_outline,
                                                      size: 14,
                                                      color: isDark
                                                          ? AppTheme.textMutedDark
                                                          : AppTheme.textMutedLight,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      doc.uploaderName,
                                                      style: theme.textTheme.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  DateFormat('dd/MM/yyyy').format(doc.issueDate),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/document-upload');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Documento'),
      ),
    );
  }
}
