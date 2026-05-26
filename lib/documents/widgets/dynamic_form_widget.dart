import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../models/document_template_models.dart' as tmpl;
import '../services/document_service.dart';

class DynamicFormWidget extends StatefulWidget {
  final tmpl.DocumentTemplateResponse template;
  final Map<String, dynamic> values;
  final ValueChanged<bool>? onUploadingStatusChanged;

  const DynamicFormWidget({
    super.key,
    required this.template,
    required this.values,
    this.onUploadingStatusChanged,
  });

  @override
  State<DynamicFormWidget> createState() => _DynamicFormWidgetState();
}

class _DynamicFormWidgetState extends State<DynamicFormWidget> {
  final Map<String, bool> _uploadingFields = {};
  final Map<String, String> _pickedFileNames = {};

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  @override
  void didUpdateWidget(covariant DynamicFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template.id != widget.template.id) {
      _initializeValues();
    }
  }

  void _initializeValues() {
    // Ensure all ARRAY fields are initialized with at least one empty map row
    widget.template.uiSchema.forEach((key, config) {
      if (config.type == tmpl.FieldType.ARRAY) {
        if (widget.values[key] == null || widget.values[key] is! List) {
          widget.values[key] = <Map<String, dynamic>>[{}];
        } else {
          final list = widget.values[key] as List;
          if (list.isEmpty) {
            list.add(<String, dynamic>{});
          }
        }
      }
    });
  }

  Future<void> _pickAndUploadFile(String key) async {
    setState(() {
      _uploadingFields[key] = true;
    });
    widget.onUploadingStatusChanged?.call(true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        final file = result.files.first;
        List<int> bytes;
        if (file.bytes != null) {
          bytes = file.bytes!;
        } else if (!kIsWeb && file.path != null) {
          bytes = await io.File(file.path!).readAsBytes();
        } else {
          throw Exception('No se pudieron leer los bytes del archivo');
        }

        final docService = Provider.of<DocumentService>(context, listen: false);
        final serverRelativeUrl = await docService.uploadFile(bytes, file.name);

        setState(() {
          widget.values[key] = serverRelativeUrl;
          _pickedFileNames[key] = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir archivo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingFields[key] = false;
        });
        final anyUploading = _uploadingFields.values.any((v) => v);
        widget.onUploadingStatusChanged?.call(anyUploading);
      }
    }
  }

  Future<void> _selectDate(String key, tmpl.FieldConfig config) async {
    final currentVal = widget.values[key] as String?;
    final dateToShow = currentVal != null ? DateFormat('yyyy-MM-dd').parse(currentVal) : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateToShow,
      firstDate: DateTime(1900),
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
    if (picked != null) {
      setState(() {
        widget.values[key] = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(String key, tmpl.FieldConfig config) async {
    final currentVal = widget.values[key] as String?;
    TimeOfDay timeToShow = TimeOfDay.now();
    if (currentVal != null) {
      final parts = currentVal.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        timeToShow = TimeOfDay(hour: hour, minute: minute);
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: timeToShow,
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

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        widget.values[key] = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedFields = widget.template.uiSchema.entries.toList()
      ..sort((a, b) => a.value.order.compareTo(b.value.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'FORMULARIO CLÍNICO DINÁMICO',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? Colors.tealAccent : AppTheme.primary,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(thickness: 1.5),
        ),
        ...sortedFields.map((field) {
          final key = field.key;
          final config = field.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: _buildField(key, config, isDark),
          );
        }),
      ],
    );
  }

  Widget _buildField(String key, tmpl.FieldConfig config, bool isDark) {
    switch (config.type) {
      case tmpl.FieldType.TEXT:
        return TextFormField(
          initialValue: widget.values[key]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: config.label,
            hintText: 'Ingrese texto',
            prefixIcon: const Icon(Icons.text_fields),
          ),
          validator: (val) {
            if (config.required && (val == null || val.trim().isEmpty)) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
          onChanged: (val) => widget.values[key] = val,
        );

      case tmpl.FieldType.TEXTAREA:
        return TextFormField(
          initialValue: widget.values[key]?.toString() ?? '',
          maxLines: 4,
          decoration: InputDecoration(
            labelText: config.label,
            hintText: 'Escriba una descripción detallada...',
            prefixIcon: const Icon(Icons.notes),
            alignLabelWithHint: true,
          ),
          validator: (val) {
            if (config.required && (val == null || val.trim().isEmpty)) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
          onChanged: (val) => widget.values[key] = val,
        );

      case tmpl.FieldType.EMAIL:
        return TextFormField(
          initialValue: widget.values[key]?.toString() ?? '',
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: config.label,
            hintText: 'ejemplo@correo.com',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          validator: (val) {
            if (config.required && (val == null || val.trim().isEmpty)) {
              return 'Este campo es obligatorio';
            }
            if (val != null && val.isNotEmpty && !val.contains('@')) {
              return 'Ingrese un correo electrónico válido';
            }
            return null;
          },
          onChanged: (val) => widget.values[key] = val,
        );

      case tmpl.FieldType.NUMBER:
        return TextFormField(
          initialValue: widget.values[key]?.toString() ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: config.label,
            hintText: '0.00',
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
          validator: (val) {
            if (config.required && (val == null || val.trim().isEmpty)) {
              return 'Este campo es obligatorio';
            }
            if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
              return 'Debe ser un número válido';
            }
            return null;
          },
          onChanged: (val) => widget.values[key] = num.tryParse(val) ?? val,
        );

      case tmpl.FieldType.DATE:
        return _buildDatePicker(key, config);

      case tmpl.FieldType.TIME:
        return _buildTimePicker(key, config);

      case tmpl.FieldType.SELECT:
        if (config.options.isEmpty) {
          return TextFormField(
            enabled: false,
            decoration: InputDecoration(
              labelText: config.label,
              hintText: 'Sin opciones definidas en plantilla',
              prefixIcon: const Icon(Icons.warning_amber),
            ),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: widget.values[key]?.toString(),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: config.label,
            prefixIcon: const Icon(Icons.list_alt),
          ),
          items: config.options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          validator: (val) {
            if (config.required && (val == null || val.isEmpty)) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
          onChanged: (val) {
            setState(() {
              widget.values[key] = val;
            });
          },
        );

      case tmpl.FieldType.RADIO:
        if (config.options.isEmpty) {
          return Text(
            '${config.label} (Sin opciones definidas)',
            style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          );
        }
        final currentVal = widget.values[key]?.toString();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: config.options.entries.map((opt) {
                final isSelected = currentVal == opt.key;
                return ChoiceChip(
                  label: Text(opt.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      widget.values[key] = selected ? opt.key : null;
                    });
                  },
                  selectedColor: AppTheme.primary.withOpacity(0.2),
                  checkmarkColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? (isDark ? Colors.tealAccent : AppTheme.primary) 
                        : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            if (config.required && currentVal == null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 12.0),
                child: Text(
                  'Este campo es obligatorio',
                  style: TextStyle(color: AppTheme.error, fontSize: 12),
                ),
              ),
          ],
        );

      case tmpl.FieldType.CHECKBOX:
        final currentVal = widget.values[key] == true;
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
          child: SwitchListTile.adaptive(
            title: Text(
              config.label,
              style: TextStyle(
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            activeColor: AppTheme.primary,
            value: currentVal,
            onChanged: (val) {
              setState(() {
                widget.values[key] = val;
              });
            },
          ),
        );

      case tmpl.FieldType.DISPLAY_TEXT:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.borderDark.withOpacity(0.15) : AppTheme.primary.withOpacity(0.04),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            border: const Border(
              left: BorderSide(
                color: AppTheme.primary,
                width: 4.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  config.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        );

      case tmpl.FieldType.FILE:
        return _buildFileField(key, config, isDark);

      case tmpl.FieldType.ARRAY:
        return _buildArrayField(key, config, isDark);

    }
  }

  Widget _buildDatePicker(String key, tmpl.FieldConfig config) {
    final dateFormat = DateFormat('dd / MM / yyyy');
    final currentVal = widget.values[key] as String?;
    final dateToShow = currentVal != null ? DateFormat('yyyy-MM-dd').parse(currentVal) : null;

    return InkWell(
      onTap: () => _selectDate(key, config),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: config.label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, color: AppTheme.primary),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          dateToShow != null ? dateFormat.format(dateToShow) : 'Seleccione una fecha',
          style: TextStyle(
            color: dateToShow != null ? null : Colors.grey,
            fontWeight: dateToShow != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String key, tmpl.FieldConfig config) {
    final currentVal = widget.values[key] as String?;

    return InkWell(
      onTap: () => _selectTime(key, config),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: config.label,
          suffixIcon: const Icon(Icons.access_time_outlined, color: AppTheme.primary),
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          currentVal ?? 'Seleccione una hora',
          style: TextStyle(
            color: currentVal != null ? null : Colors.grey,
            fontWeight: currentVal != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFileField(String key, tmpl.FieldConfig config, bool isDark) {
    final currentVal = widget.values[key] as String?;
    final isUploading = _uploadingFields[key] == true;
    final fileName = _pickedFileNames[key];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: currentVal != null
              ? AppTheme.primary
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
          width: currentVal != null ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  if (currentVal == null && !isUploading)
                    const Text(
                      'Ningún archivo seleccionado',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else if (isUploading)
                    const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Subiendo archivo...',
                          style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            fileName ?? 'Archivo subido con éxito',
                            style: TextStyle(
                              color: isDark ? Colors.tealAccent : AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (currentVal != null)
              IconButton(
                onPressed: isUploading
                    ? null
                    : () {
                        setState(() {
                          widget.values[key] = null;
                          _pickedFileNames.remove(key);
                        });
                      },
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                tooltip: 'Remover archivo',
              )
            else
              ElevatedButton.icon(
                onPressed: isUploading ? null : () => _pickAndUploadFile(key),
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: const Text('Adjuntar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrayField(String key, tmpl.FieldConfig config, bool isDark) {
    if (config.subSchema == null || config.subSchema!.isEmpty) {
      return Text(
        '${config.label} (Sub-esquema no definido)',
        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final List<dynamic> rows = widget.values[key] is List 
        ? widget.values[key] as List 
        : <Map<String, dynamic>>[];

    final sortedSubFields = config.subSchema!.entries.toList()
      ..sort((a, b) => a.value.order.compareTo(b.value.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Array Header
        Row(
          children: [
            const Icon(Icons.view_headline_rounded, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              config.label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isDark ? Colors.tealAccent : AppTheme.primary,
              ),
            ),
            if (config.required)
              const Text(' *', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),

        // Array Items Cards
        ...List.generate(rows.length, (index) {
          final rowData = rows[index] as Map<String, dynamic>;

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isDark ? AppTheme.borderDark : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header of the repeating Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.borderDark.withOpacity(0.2) : Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(9),
                      topRight: Radius.circular(9),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ítem #${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (rows.length > 1)
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                          onPressed: () {
                            setState(() {
                              rows.removeAt(index);
                            });
                          },
                          tooltip: 'Eliminar ítem',
                        ),
                    ],
                  ),
                ),

                // Sub-fields within the card
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Column(
                    children: sortedSubFields.map((subField) {
                      final subKey = subField.key;
                      final subConfig = subField.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildSubField(subKey, subConfig, rowData, index, isDark),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),

        // Add Row Button
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              rows.add(<String, dynamic>{});
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('AGREGAR ÍTEM'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubField(String subKey, tmpl.FieldConfig subConfig, Map<String, dynamic> rowData, int rowIndex, bool isDark) {
    // Each standard input / picker inside repeating cards should be styled compactly
    switch (subConfig.type) {
      case tmpl.FieldType.TEXT:
        return TextFormField(
          initialValue: rowData[subKey]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: subConfig.label,
            hintText: 'Ingrese texto',
            isDense: true,
          ),
          validator: (val) {
            if (subConfig.required && (val == null || val.trim().isEmpty)) {
              return 'Obligatorio';
            }
            return null;
          },
          onChanged: (val) => rowData[subKey] = val,
        );

      case tmpl.FieldType.NUMBER:
        return TextFormField(
          initialValue: rowData[subKey]?.toString() ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: subConfig.label,
            hintText: '0.00',
            isDense: true,
          ),
          validator: (val) {
            if (subConfig.required && (val == null || val.trim().isEmpty)) {
              return 'Obligatorio';
            }
            if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
              return 'Número inválido';
            }
            return null;
          },
          onChanged: (val) => rowData[subKey] = num.tryParse(val) ?? val,
        );

      case tmpl.FieldType.SELECT:
        if (subConfig.options.isEmpty) {
          return TextFormField(
            enabled: false,
            decoration: InputDecoration(
              labelText: subConfig.label,
              hintText: 'Sin opciones en plantilla',
              isDense: true,
            ),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: rowData[subKey]?.toString(),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: subConfig.label,
            isDense: true,
          ),
          items: subConfig.options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          validator: (val) {
            if (subConfig.required && (val == null || val.isEmpty)) {
              return 'Obligatorio';
            }
            return null;
          },
          onChanged: (val) {
            setState(() {
              rowData[subKey] = val;
            });
          },
        );

      case tmpl.FieldType.CHECKBOX:
        final currentVal = rowData[subKey] == true;
        return CheckboxListTile(
          title: Text(
            subConfig.label,
            style: TextStyle(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          activeColor: AppTheme.primary,
          value: currentVal,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() {
              rowData[subKey] = val;
            });
          },
        );

      default:
        // Fallback standard text
        return TextFormField(
          initialValue: rowData[subKey]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: subConfig.label,
            isDense: true,
          ),
          onChanged: (val) => rowData[subKey] = val,
        );
    }
  }
}
