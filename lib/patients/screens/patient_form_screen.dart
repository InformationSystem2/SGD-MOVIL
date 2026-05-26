import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../models/patient_models.dart';
import '../services/patient_service.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _documentType = 'CI';
  String _gender = 'Masculino';
  DateTime? _birthDate;

  bool _isInit = false;
  PatientResponse? _existingPatient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Check if we passed a patient to edit
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args != null && args is PatientResponse) {
        _existingPatient = args;
        _firstNameController.text = _existingPatient!.firstName;
        _lastNameController.text = _existingPatient!.lastName;
        _documentType = _existingPatient!.documentType;
        _documentNumberController.text = _existingPatient!.documentNumber;
        _phoneController.text = _existingPatient!.phone ?? '';
        _addressController.text = _existingPatient!.address ?? '';
        if (_existingPatient!.gender != null) {
          _gender = _existingPatient!.gender!.toUpperCase() == 'FEMALE'
              ? 'Femenino'
              : 'Masculino';
        } else {
          _gender = 'Masculino';
        }
        _birthDate = _existingPatient!.birthDate;
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione la fecha de nacimiento')),
      );
      return;
    }

    final patientService = Provider.of<PatientService>(context, listen: false);

    try {
      final backendGender = _gender == 'Femenino' ? 'FEMALE' : 'MALE';
      if (_existingPatient == null) {
        // Create Mode
        final request = PatientCreateRequest(
          documentType: _documentType,
          documentNumber: _documentNumberController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          gender: backendGender,
          birthDate: _birthDate!,
        );
        await patientService.createPatient(request);
      } else {
        // Edit Mode
        final request = PatientUpdateRequest(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          documentType: _documentType,
          documentNumber: _documentNumberController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          gender: backendGender,
          birthDate: _birthDate!,
        );
        await patientService.updatePatient(_existingPatient!.id, request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingPatient == null
                  ? 'Paciente registrado con éxito'
                  : 'Paciente actualizado con éxito',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop(true); // Pop back to list and signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar paciente: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientService = Provider.of<PatientService>(context);
    final isEdit = _existingPatient != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Paciente' : 'Nuevo Paciente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DATOS PERSONALES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre(s)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Ingrese el nombre' : null,
                      ),
                      const SizedBox(height: 14),

                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Apellido(s)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Ingrese el apellido' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IDENTIFICACIÓN Y DETALLES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Document Type dropdown
                      DropdownButtonFormField<String>(
                        value: _documentType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Documento',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: ['CI', 'Pasaporte', 'Libreta Militar', 'Otro'].map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _documentType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Document Number
                      TextFormField(
                        controller: _documentNumberController,
                        keyboardType: TextInputType.visiblePassword, // simple text/numbers
                        decoration: const InputDecoration(
                          labelText: 'Número de Documento',
                          prefixIcon: Icon(Icons.numbers_outlined),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Ingrese el número de documento'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Birth Date picker
                      InkWell(
                        onTap: () => _selectBirthDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Nacimiento',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Text(
                            _birthDate != null
                                ? DateFormat('dd / MM / yyyy').format(_birthDate!)
                                : 'Seleccione fecha',
                            style: TextStyle(
                              color: _birthDate != null ? null : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Gender dropdown
                      DropdownButtonFormField<String>(
                        value: _gender,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Género',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: ['Masculino', 'Femenino'].map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _gender = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONTACTO Y UBICACIÓN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono de Contacto',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Dirección de Domicilio',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: patientService.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: patientService.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(isEdit ? 'Guardar Cambios' : 'Registrar Paciente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
