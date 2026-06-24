import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/api_config.dart';
import '../../core/services/tenant_service.dart';
import '../../patients/services/patient_service.dart';
import '../models/document_models.dart';
import '../models/document_template_models.dart' as tmpl;
import '../services/document_service.dart';
import '../services/document_template_service.dart';
import '../widgets/dynamic_form_widget.dart';
import '../../help/widgets/help_sheet.dart';
import 'package:pdf/widgets.dart' as pdf_lib;
import 'scanner_screen.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyTemplate = GlobalKey<FormState>();
  final _formKeyExternal = GlobalKey<FormState>();
  final _formKeyScan = GlobalKey<FormState>();

  // Shared states
  String? _selectedPatientId;
  DateTime _issueDate = DateTime.now();

  // Template Tab state
  String? _selectedTemplateId;
  final Map<String, dynamic> _dynamicValues = {};
  bool _isUploadingDynamicFile = false;

  // External Tab state
  PlatformFile? _pickedFile;
  final _externalTitleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isUploadingFile = false;

  // Scan Tab state
  final List<XFile> _scannedImages = [];
  String _selectedFilter = 'NORMAL'; // 'NORMAL', 'GRIS', 'BINARIZADO'
  final _scanTitleController = TextEditingController();
  final _scanNotesController = TextEditingController();
  bool _isUploadingScan = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final tenantService = Provider.of<TenantService>(context, listen: false);
    final canScan = tenantService.canUseScan;
    _tabController = TabController(length: canScan ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _externalTitleController.dispose();
    _notesController.dispose();
    _scanTitleController.dispose();
    _scanNotesController.dispose();
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

  // --- Open Adobe Scan-style scanner ---
  Future<void> _scanDocument() async {
    final result = await Navigator.of(context).push<List<XFile>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ScannerScreen(initialPages: List.from(_scannedImages)),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _scannedImages
        ..clear()
        ..addAll(result));
    }
  }

  // --- Shared: validate scan pre-conditions ---
  bool _validateScanForm() {
    if (!_formKeyScan.currentState!.validate()) return false;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un paciente')),
      );
      return false;
    }
    if (_scannedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escanee al menos un documento con la cámara')),
      );
      return false;
    }
    if (_scanTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese un título para el documento')),
      );
      return false;
    }
    return true;
  }

  // --- Shared: generate PDF and upload to backend ---
  Future<void> _buildAndUploadScan({
    required String title,
    required String notes,
    required DocumentService docService,
    Map<String, dynamic> aiKeyData = const {},
    String aiDetectedType = '',
    bool aiSuccess = false,
    Map<String, dynamic> fullOcrResult = const {},
  }) async {
    final pdfDoc = pdf_lib.Document();
    for (final imgFile in _scannedImages) {
      final imgBytes = await imgFile.readAsBytes();
      final pdfImage = pdf_lib.MemoryImage(imgBytes);
      pdfDoc.addPage(
        pdf_lib.Page(
          build: (pdf_lib.Context context) {
            return pdf_lib.Center(
              child: pdf_lib.Image(pdfImage, fit: pdf_lib.BoxFit.contain),
            );
          },
        ),
      );
    }

    final pdfBytes = await pdfDoc.save();
    final pdfFilename = 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final relativeUrl = await docService.uploadFile(pdfBytes, pdfFilename);

    final req = ExternalDocumentRequest(
      patientId: _selectedPatientId!,
      fileUrl: relativeUrl,
      issueDate: _issueDate,
      title: title,
      notes: notes.isNotEmpty ? notes : null,
    );

    final createdDoc = await docService.createExternalDocument(req);

    if (aiSuccess && fullOcrResult.isNotEmpty) {
      await docService.saveOcrResult(createdDoc.id, fullOcrResult);
    }
  }

  // --- Submission: Save scanned document directly (no AI) ---
  void _saveScannedDirect() async {
    if (!_validateScanForm()) return;

    final title = _scanTitleController.text.trim();
    final notes = _scanNotesController.text.trim();
    final docService = Provider.of<DocumentService>(context, listen: false);

    setState(() => _isUploadingScan = true);
    try {
      await _buildAndUploadScan(title: title, notes: notes, docService: docService);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento "$title" guardado exitosamente en PDF'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar documento: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingScan = false);
    }
  }

  // --- Submission: Process scanned document with AI, then review + save ---
  void _processScannedWithAI() async {
    if (!_validateScanForm()) return;

    final docService = Provider.of<DocumentService>(context, listen: false);

    Map<String, dynamic> ocrResult = {};
    Map<String, dynamic> structured = {};
    String detectedType = 'Escaneo Médico';
    Map<String, dynamic> detectedKeyData = {};
    bool aiSuccess = false;

    setState(() => _isUploadingScan = true);
    try {
      final List<List<int>> filesBytes = [];
      final List<String> filenames = [];
      for (int i = 0; i < _scannedImages.length; i++) {
        final bytes = await _scannedImages[i].readAsBytes();
        filesBytes.add(bytes);
        filenames.add('scan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      }
      ocrResult = await docService.extractOcrFromMultipleFiles(filesBytes, filenames);
      structured = ocrResult['structured_data'] ?? {};
      detectedType = structured['tipo_documento'] ?? 'Escaneo Médico';
      detectedKeyData = structured['datos_clave'] ?? {};
      aiSuccess = true;
    } catch (e) {
      debugPrint('FastAPI OCR falló: $e (URL: ${ApiConfig.fastapiUrl}/ocr/extract-multiple)');
    }
    setState(() => _isUploadingScan = false);

    if (!mounted) return;

    // El título ya fue ingresado por el usuario antes de procesar
    final title = _scanTitleController.text.trim();
    final notesController = TextEditingController(text: _scanNotesController.text.trim());

    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                aiSuccess ? Icons.auto_awesome : Icons.document_scanner,
                color: aiSuccess ? Colors.amber : AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(aiSuccess ? 'Resultado de IA' : 'Guardar Documento'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    aiSuccess
                        ? 'La IA analizó el documento. Revise los datos detectados y edite las notas si lo desea:'
                        : 'No se pudo conectar con la IA. El documento se guardará con el título que ingresó.',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (aiSuccess)
                    Card(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Texto extraído:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            const SizedBox(height: 4),
                            Text(
                              ocrResult['raw_text']?.toString() ?? '(Vacío)',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                            const Divider(height: 16),
                            Text('Datos Clave Detectados:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            const SizedBox(height: 4),
                            if (detectedKeyData.isEmpty)
                              const Text('Ninguno', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))
                            else
                              ...detectedKeyData.entries.map((e) => Text(
                                    '- ${e.key}: ${e.value}',
                                    style: const TextStyle(fontSize: 12),
                                  )),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Muestra el título ingresado (solo lectura en el diálogo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.title, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas / Observación (opcional)',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmar y Guardar'),
            ),
          ],
        );
      },
    );

    if (proceed != true) return;

    setState(() => _isUploadingScan = true);
    try {
      await _buildAndUploadScan(
        title: title,
        notes: notesController.text.trim(),
        docService: docService,
        aiKeyData: detectedKeyData,
        aiDetectedType: detectedType,
        aiSuccess: aiSuccess,
        fullOcrResult: ocrResult,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento "$title" guardado exitosamente en PDF'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar documento: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingScan = false);
    }
  }

  // --- Submission: External file ---
  void _submitExternal() async {
    if (!_formKeyExternal.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un paciente')),
      );
      return;
    }
    if (_externalTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese un título para el documento')),
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
      List<int> bytes;
      if (_pickedFile!.bytes != null) {
        bytes = _pickedFile!.bytes!;
      } else if (!kIsWeb && _pickedFile!.path != null) {
        bytes = await io.File(_pickedFile!.path!).readAsBytes();
      } else {
        throw Exception('No se pudieron leer los bytes del archivo');
      }

      final relativeUrl = await docService.uploadFile(bytes, _pickedFile!.name);

      final req = ExternalDocumentRequest(
        patientId: _selectedPatientId!,
        fileUrl: relativeUrl,
        issueDate: _issueDate,
        title: _externalTitleController.text.trim(),
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
        Navigator.of(context).pop();
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

  // --- Submission: Templated document ---
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
    final tenantService = Provider.of<TenantService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canScan = tenantService.canUseScan;

    // Check if routed specifically for scanOnly
    final args = ModalRoute.of(context)?.settings.arguments;
    final bool isScanOnly = args is Map && args['scanOnly'] == true;

    final tmpl.DocumentTemplateResponse? activeTemplate = _selectedTemplateId != null
        ? templateService.getById(_selectedTemplateId!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isScanOnly ? 'Escanear Documento' : 'Nuevo Documento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Ayuda',
            onPressed: () => showHelpSheet(context),
          ),
        ],
        bottom: isScanOnly
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  const Tab(icon: Icon(Icons.assignment), text: 'Formulario'),
                  const Tab(icon: Icon(Icons.cloud_upload), text: 'Subir Archivo'),
                  if (canScan)
                    const Tab(icon: Icon(Icons.document_scanner_rounded), text: 'Escanear'),
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
                          DropdownButtonFormField<String>(
                            value: patientService.patients.any((p) => p.id == _selectedPatientId) ? _selectedPatientId : null,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Paciente',
                              prefixIcon: const Icon(Icons.person),
                              hintText: patientService.isLoading 
                                  ? 'Cargando pacientes...' 
                                  : patientService.patients.isEmpty 
                                      ? 'No hay pacientes registrados' 
                                      : 'Seleccione un paciente',
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
                            onChanged: patientService.isLoading || patientService.patients.isEmpty 
                                ? null 
                                : (val) {
                                    setState(() {
                                      _selectedPatientId = val;
                                    });
                                  },
                            validator: (val) => val == null ? 'Seleccione un paciente' : null,
                          ),
                          const SizedBox(height: 12),
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
                  child: isScanOnly
                      ? _buildScanTab(isDark)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Template forms
                            _buildTemplateTab(templateService, docService, activeTemplate),

                            // Tab 2: External document file uploads
                            _buildExternalTab(isDark),

                            // Tab 3: Camera scanner (only if plan allows)
                            if (canScan) _buildScanTab(isDark),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  // ── Tab 1: Template forms ──────────────────────────────────────────────────

  Widget _buildTemplateTab(
      DocumentTemplateService templateService,
      DocumentService docService,
      tmpl.DocumentTemplateResponse? activeTemplate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyTemplate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedTemplateId,
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
                      _dynamicValues.clear();
                    });
                  },
                  validator: (val) => val == null ? 'Seleccione una plantilla' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
    );
  }

  // ── Tab 2: External file upload ────────────────────────────────────────────

  Widget _buildExternalTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyExternal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            TextFormField(
              controller: _externalTitleController,
              decoration: const InputDecoration(
                labelText: 'Título del documento',
                hintText: 'Ej: Análisis de sangre, Receta médica...',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Ingrese un título para el documento' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas adicionales (opcional)',
                hintText: 'Describa el origen o notas de este documento externo...',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 32),
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
    );
  }

  // ── Tab 3: Camera scanner ──────────────────────────────────────────────────

  Widget _buildScanTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyScan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lighting / Visual filter selector
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'NORMAL',
                    label: Text('Normal'),
                    icon: Icon(Icons.wb_sunny_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'GRIS',
                    label: Text('Escala Grises'),
                    icon: Icon(Icons.filter_hdr_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'BINARIZADO',
                    label: Text('B/N Contraste'),
                    icon: Icon(Icons.camera_enhance_outlined),
                  ),
                ],
                selected: <String>{_selectedFilter},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedFilter = newSelection.first;
                  });
                },
              ),
            ),

            // Scanner area card supporting multi-page preview
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _scannedImages.isEmpty
                      ? (isDark ? AppTheme.borderDark : AppTheme.borderLight)
                      : AppTheme.primary,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    if (_scannedImages.isEmpty)
                      InkWell(
                        onTap: _isUploadingScan ? null : _scanDocument,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: AppTheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.document_scanner_rounded,
                                  size: 48,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Escanear Documento',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Toque para abrir el escáner.\nCapture con cámara o importe desde galería.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Páginas capturadas: ${_scannedImages.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: _isUploadingScan ? null : _scanDocument,
                                icon: const Icon(Icons.add_a_photo_outlined),
                                label: const Text('Añadir Página'),
                              ),
                            ],
                          ),
                          const Divider(),
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _scannedImages.length,
                              itemBuilder: (context, idx) {
                                final imgFile = _scannedImages[idx];
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      // Render display image depending on visual filter setting
                                      ColorFiltered(
                                        colorFilter: _selectedFilter == 'GRIS'
                                            ? const ColorFilter.matrix(<double>[
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0,      0,      0,      1, 0,
                                              ])
                                            : _selectedFilter == 'BINARIZADO'
                                                ? const ColorFilter.matrix(<double>[
                                                    1.5, 1.5, 1.5, 0, -128,
                                                    1.5, 1.5, 1.5, 0, -128,
                                                    1.5, 1.5, 1.5, 0, -128,
                                                    0,   0,   0,   1, 0,
                                                  ])
                                                : const ColorFilter.matrix(<double>[
                                                    1, 0, 0, 0, 0,
                                                    0, 1, 0, 0, 0,
                                                    0, 0, 1, 0, 0,
                                                    0, 0, 0, 1, 0,
                                                  ]),
                                        child: Image.file(
                                          io.File(imgFile.path),
                                          height: 200,
                                          width: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 4,
                                        top: 4,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black.withOpacity(0.6),
                                          radius: 16,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, size: 14, color: Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _scannedImages.removeAt(idx);
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 8,
                                        bottom: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          color: Colors.black.withOpacity(0.6),
                                          child: Text(
                                            'Pág. ${idx + 1}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título del documento
            TextFormField(
              controller: _scanTitleController,
              decoration: const InputDecoration(
                labelText: 'Título del documento',
                hintText: 'Ej: Radiografía de tórax, Análisis de sangre...',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Ingrese un título para el documento' : null,
            ),
            const SizedBox(height: 12),

            // Notas del escaneo
            TextFormField(
              controller: _scanNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas adicionales (opcional)',
                hintText: 'Ej: Diagnóstico o detalles clínicos adicionales...',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            if (_isUploadingScan)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Procesando...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _scannedImages.isEmpty ? null : _saveScannedDirect,
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Guardar Documento'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _scannedImages.isEmpty ? null : _processScannedWithAI,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Procesar con IA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
