import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../models/document_models.dart';
import '../services/document_service.dart';

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key});

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
        return 'Borrador (Editable)';
      case DocumentStatus.PENDING_REVIEW:
        return 'En Revisión';
      case DocumentStatus.REJECTED:
        return 'Rechazado (Requiere corrección)';
      case DocumentStatus.FINALIZED:
        return 'Finalizado (Firmado / Inmutable)';
    }
  }

  String _formatKey(String key) {
    // Converts e.g. "fecha_nacimiento" or "sintomasGenerales" to "Fecha nacimiento" or "Sintomas generales"
    if (key.isEmpty) return '';
    
    // Replace underscores and camelCase
    String result = key.replaceAll('_', ' ');
    
    // Split camelCase
    final pattern = RegExp(r'(?<=[a-z])(?=[A-Z])');
    result = result.replaceAllMapped(pattern, (match) => ' ${match.group(0)}');
    
    // Capitalize first letter
    return result[0].toUpperCase() + result.substring(1).toLowerCase();
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is bool) return value ? 'Sí' : 'No';
    if (value is List) {
      if (value.isEmpty) return 'Ninguno';
      return value.map((x) => _formatValue(x)).join(', ');
    }
    if (value is Map) {
      if (value.isEmpty) return '{}';
      return value.entries.map((e) => '${_formatKey(e.key)}: ${_formatValue(e.value)}').join('\n');
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final doc = ModalRoute.of(context)!.settings.arguments as DocumentResponse;
    final docService = Provider.of<DocumentService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final statusColor = _getStatusColor(doc.status);
    final fullFileUrl = doc.fileUrl != null ? docService.getFullFileUrl(doc.fileUrl!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Documento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    doc.status == DocumentStatus.FINALIZED 
                        ? Icons.verified_user 
                        : doc.status == DocumentStatus.REJECTED 
                            ? Icons.cancel 
                            : Icons.info,
                    color: statusColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estado Legal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _getStatusLabel(doc.status),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patient Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATOS DEL PACIENTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppTheme.primary50,
                          child: Icon(Icons.person, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.patientName,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nro Documento: ${doc.patientDocumentNumber ?? "Sin CI"}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'METADATOS DEL DOCUMENTO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetaRow(
                      context,
                      label: 'Registrado por:',
                      value: doc.uploaderName,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 10),
                    _buildMetaRow(
                      context,
                      label: 'Fecha de emisión:',
                      value: DateFormat('dd/MM/yyyy').format(doc.issueDate),
                      icon: Icons.calendar_today_outlined,
                    ),
                    if (doc.expiryDate != null) ...[
                      const SizedBox(height: 10),
                      _buildMetaRow(
                        context,
                        label: 'Fecha de vencimiento:',
                        value: DateFormat('dd/MM/yyyy').format(doc.expiryDate!),
                        icon: Icons.event_busy_outlined,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildMetaRow(
                      context,
                      label: 'Origen del documento:',
                      value: doc.isExternalSource ? 'Fuente Externa / Archivo' : 'Basado en Plantilla',
                      icon: doc.isExternalSource ? Icons.cloud_upload_outlined : Icons.description_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Document Content / File URL Card
            if (doc.isExternalSource && fullFileUrl != null) ...[
              Card(
                color: isDark ? AppTheme.primary.withOpacity(0.08) : const Color(0xFFF0FDF8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppTheme.primary.withOpacity(isDark ? 0.3 : 0.5),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.attachment_rounded, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text(
                            'ARCHIVO ADJUNTO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Este es un documento externo almacenado en el servidor.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ruta: ${doc.fileUrl}',
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: fullFileUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enlace copiado al portapapeles'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar Enlace del Archivo'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Display a dialog with full URL as selectable text
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Enlace del Archivo'),
                              content: SelectableText(
                                fullFileUrl,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cerrar'),
                                )
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.link),
                        label: const Text('Mostrar URL Completa'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Templated Document: Render dynamic clinicalContent keys/values
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_outlined, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              doc.templateName ?? 'CONTENIDO CLÍNICO',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (doc.clinicalContent.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              'Documento sin contenido clínico registrado.',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: doc.clinicalContent.length,
                          separatorBuilder: (context, index) => const Divider(height: 20),
                          itemBuilder: (context, index) {
                            final entry = doc.clinicalContent.entries.elementAt(index);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatKey(entry.key),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatValue(entry.value),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Optionally show attached file if template has a file
              if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.attach_file, color: AppTheme.primary),
                    title: const Text('Archivo adjunto complementario'),
                    subtitle: Text(doc.fileUrl!, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullFileUrl!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enlace de adjunto copiado')),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
