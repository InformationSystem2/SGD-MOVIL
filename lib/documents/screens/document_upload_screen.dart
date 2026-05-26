import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../patients/services/patient_service.dart';
import '../models/document_models.dart';
import '../models/document_template_models.dart' as tmpl;
import '../services/document_service.dart';
import '../services/document_template_service.dart';
import '../widgets/dynamic_form_widget.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyTemplate = GlobalKey<FormState>();
  final _formKeyExternal = GlobalKey<FormState>();

  // Shared states
  String? _selectedPatientId;
  DateTime _issueDate = DateTime.now();

  // Template Tab state
  String? _selectedTemplateId;
  final Map<String, dynamic> _dynamicValues = {};
  bool _isUploadingDynamicFile = false;

  // External Tab state
  PlatformFile? _pickedFile;
  final _notesController = TextEditingController();
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _issueDate) {
      setState(() {
        _issueDate = picked;
      });
    }
  }

  // --- File picker logic ---
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // --- Submission triggers ---
  void _submitExternal() async {
    if (!_formKeyExternal.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un paciente')),
      );
      return;
    }
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un archivo para subir')),
      );
      return;
    }

    setState(() => _isUploadingFile = true);
    final docService = Provider.of<DocumentService>(context, listen: false);

    try {
      // 1. Read bytes from picked file (works on web and mobile)
      List<int> bytes;
      if (_pickedFile!.bytes != null) {
        bytes = _pickedFile!.bytes!;
      } else if (!kIsWeb && _pickedFile!.path != null) {
        bytes = await io.File(_pickedFile!.path!).readAsBytes();
      } else {
        throw Exception('No se pudieron leer los bytes del archivo');
      }

      // 2. Upload file to backend server
      final relativeUrl = await docService.uploadFile(bytes, _pickedFile!.name);

      // 3. Register external document link
      final req = ExternalDocumentRequest(
        patientId: _selectedPatientId!,
        fileUrl: relativeUrl,
        issueDate: _issueDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await docService.createExternalDocument(req);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Documento subido y registrado exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop(); // Back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar subida: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  void _submitTemplated() async {
    if (!_formKeyTemplate.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un paciente')),
      );
      return;
    }
    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione una plantilla')),
      );
      return;
    }
    if (_isUploadingDynamicFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor espere a que termine la subida de archivos adjuntos'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final docService = Provider.of<DocumentService>(context, listen: false);
    
    // Clean up nulls in clinical content
    final cleanClinicalContent = <String, dynamic>{};
    _dynamicValues.forEach((key, value) {
      if (value != null) {
        cleanClinicalContent[key] = value;
      }
    });

    try {
      final req = DocumentRequest(
        patientId: _selectedPatientId!,
        templateId: _selectedTemplateId!,
        clinicalContent: cleanClinicalContent,
        issueDate: _issueDate,
      );

      await docService.createDocument(req);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Documento clínico registrado con éxito'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar documento: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientService = Provider.of<PatientService>(context);
    final templateService = Provider.of<DocumentTemplateService>(context);
    final docService = Provider.of<DocumentService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tmpl.DocumentTemplateResponse? activeTemplate = _selectedTemplateId != null
        ? templateService.getById(_selectedTemplateId!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Documento'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Formulario Clínico'),
            Tab(icon: Icon(Icons.cloud_upload), text: 'Subir Archivo'),
          ],
        ),
      ),
      body: patientService.isLoading || templateService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Patient and Issue Date selection (Common fields at the top)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Patient select dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPatientId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Paciente',
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: patientService.patients.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(
                                  '${p.fullName} (CI: ${p.documentNumber})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPatientId = val;
                              });
                            },
                            validator: (val) => val == null ? 'Seleccione un paciente' : null,
                          ),
                          const SizedBox(height: 12),

                          // Issue Date Picker
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Emisión',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('dd / MM / yyyy').format(_issueDate),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Form views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Template forms
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKeyTemplate,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Template Selector Card
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedTemplateId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Plantilla de Documento',
                                      prefixIcon: Icon(Icons.description),
                                    ),
                                    items: templateService.templates.map((t) {
                                      return DropdownMenuItem<String>(
                                        value: t.id,
                                        child: Text(t.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedTemplateId = val;
                                        _dynamicValues.clear(); // reset dynamic inputs
                                      });
                                    },
                                    validator: (val) => val == null ? 'Seleccione una plantilla' : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dynamic Form Render
                              if (activeTemplate != null) ...[
                                DynamicFormWidget(
                                  template: activeTemplate,
                                  values: _dynamicValues,
                                  onUploadingStatusChanged: (status) {
                                    setState(() {
                                      _isUploadingDynamicFile = status;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: (docService.isLoading || _isUploadingDynamicFile)
                                      ? null
                                      : _submitTemplated,
                                  child: docService.isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('Registrar Documento'),
                                ),
                              ] else
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: const Center(
                                    child: Text(
                                      'Seleccione una plantilla clínica para comenzar',
                                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Tab 2: External document file uploads
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKeyExternal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Pick file module card
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _pickedFile == null 
                                        ? (isDark ? AppTheme.borderDark : AppTheme.borderLight)
                                        : AppTheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: _isUploadingFile ? null : _pickFile,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          _pickedFile == null ? Icons.cloud_upload_outlined : Icons.insert_drive_file,
                                          size: 56,
                                          color: _pickedFile == null ? Colors.grey : AppTheme.primary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _pickedFile == null 
                                              ? 'Seleccionar Archivo de Dispositivo' 
                                              : _pickedFile!.name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _pickedFile == null ? null : AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _pickedFile == null 
                                              ? 'Soporta PDF, imágenes o documentos de texto.' 
                                              : '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Notes Field
                              TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Notas adicionales',
                                  hintText: 'Describa el origen o notas de este documento externo...',
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Action Button
                              ElevatedButton(
                                onPressed: _isUploadingFile ? null : _submitExternal,
                                child: _isUploadingFile
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Subiendo archivo al servidor...'),
                                        ],
                                      )
                                    : const Text('Subir y Registrar Documento'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
