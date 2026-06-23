import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/navigation_drawer.dart';
import '../models/patient_models.dart';
import '../services/patient_service.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPatients() async {
    await Provider.of<PatientService>(context, listen: false).fetchPatients();
  }

  String _getInitials(String? firstName, String? lastName) {
    String init = '';
    if (firstName != null && firstName.isNotEmpty) init += firstName[0];
    if (lastName != null && lastName.isNotEmpty) init += lastName[0];
    return init.toUpperCase();
  }

  void _deletePatient(PatientResponse patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Eliminar Paciente'),
          ],
        ),
        content: Text(
          '¿Está seguro de que desea eliminar al paciente "${patient.fullName}"? '
          'Esta acción es irreversible y podría afectar documentos asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final patientService = Provider.of<PatientService>(context, listen: false);
              try {
                if (patient.id == null) throw Exception('El ID del paciente es nulo');
                await patientService.deletePatient(patient.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paciente eliminado con éxito'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar paciente: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientService = Provider.of<PatientService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredPatients = patientService.patients.where((p) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = p.fullName.toLowerCase().contains(query);
      final docMatch = (p.documentNumber ?? '').toLowerCase().contains(query);
      return nameMatch || docMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pacientes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      drawer: const NavigationDrawerWidget(activeRoute: '/patients'),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar paciente por nombre o documento...',
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

          // Patients list
          Expanded(
            child: patientService.isLoading && patientService.patients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshPatients,
                    color: AppTheme.primary,
                    child: patientService.errorMessage != null
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                              const SizedBox(height: 16),
                              const Text(
                                'Error al cargar pacientes',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                patientService.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _refreshPatients,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          )
                        : filteredPatients.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                  Icon(
                                    Icons.people_outline,
                                    size: 72,
                                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Sin Pacientes',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No se encontraron resultados para "$_searchQuery"'
                                        : 'Aún no hay pacientes registrados en el sistema.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filteredPatients.length,
                                itemBuilder: (context, index) {
                                  final p = filteredPatients[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: AppTheme.primary.withOpacity(0.12),
                                                child: Text(
                                                  _getInitials(p.firstName, p.lastName),
                                                  style: const TextStyle(
                                                    color: AppTheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      p.fullName,
                                                      style: theme.textTheme.titleMedium,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${p.documentType ?? "Sin Tipo"}: ${p.documentNumber ?? "Sin CI"}',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Popup menu buttons
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert),
                                                onSelected: (val) {
                                                  if (val == 'edit') {
                                                    Navigator.of(context).pushNamed(
                                                      '/patient-form',
                                                      arguments: p,
                                                    );
                                                  } else if (val == 'delete') {
                                                    _deletePatient(p);
                                                  }
                                                },
                                                itemBuilder: (ctx) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, size: 18),
                                                        SizedBox(width: 8),
                                                        Text('Editar'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                                        SizedBox(width: 8),
                                                        Text('Eliminar', style: TextStyle(color: AppTheme.error)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 24),
                                          // Details rows
                                          _buildDetailRow(
                                            context,
                                            icon: Icons.cake_outlined,
                                            label: 'Fecha Nacimiento',
                                            value: p.birthDate != null
                                                ? DateFormat('dd/MM/yyyy').format(p.birthDate!)
                                                : 'No registrada',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDetailRow(
                                            context,
                                            icon: (p.gender?.toUpperCase() == 'FEMALE' || p.gender?.toLowerCase() == 'femenino')
                                                ? Icons.female
                                                : (p.gender?.toUpperCase() == 'MALE' || p.gender?.toLowerCase() == 'masculino')
                                                    ? Icons.male
                                                    : Icons.wc_outlined,
                                            label: 'Género',
                                            value: (p.gender?.toUpperCase() == 'FEMALE' || p.gender?.toLowerCase() == 'femenino')
                                                ? 'Femenino'
                                                : (p.gender?.toUpperCase() == 'MALE' || p.gender?.toLowerCase() == 'masculino')
                                                    ? 'Masculino'
                                                    : (p.gender ?? 'No registrado'),
                                          ),
                                          if (p.phone != null && p.phone!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            _buildDetailRow(
                                              context,
                                              icon: Icons.phone_outlined,
                                              label: 'Teléfono',
                                              value: p.phone!,
                                            ),
                                          ],
                                          if (p.address != null && p.address!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            _buildDetailRow(
                                              context,
                                              icon: Icons.location_on_outlined,
                                              label: 'Dirección',
                                              value: p.address!,
                                            ),
                                          ],
                                        ],
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
          Navigator.of(context).pushNamed('/patient-form');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Paciente'),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
