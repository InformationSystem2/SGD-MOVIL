// ignore_for_file: constant_identifier_names

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'document_template_models.g.dart';

@JsonEnum(alwaysCreate: true)
enum FieldType {
  TEXT,
  TEXTAREA,
  EMAIL,
  NUMBER,
  DATE,
  TIME,
  SELECT,
  RADIO,
  CHECKBOX,
  FILE,
  DISPLAY_TEXT,
  ARRAY
}

@JsonSerializable(explicitToJson: true)
class FieldConfig extends Equatable {
  final FieldType type;
  final bool required;
  final String label;
  final int order;
  
  @JsonKey(defaultValue: <String, String>{})
  final Map<String, String> options;
  
  final Map<String, FieldConfig>? subSchema;

  const FieldConfig({
    required this.type,
    required this.required,
    required this.label,
    required this.order,
    required this.options,
    this.subSchema,
  });

  factory FieldConfig.fromJson(Map<String, dynamic> json) => _$FieldConfigFromJson(json);
  Map<String, dynamic> toJson() => _$FieldConfigToJson(this);

  @override
  List<Object?> get props => [type, required, label, order, options, subSchema];
}

@JsonSerializable(explicitToJson: true)
class DocumentTemplateResponse extends Equatable {
  final String id;
  final String name;
  final String description;
  final Map<String, FieldConfig> uiSchema;

  const DocumentTemplateResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.uiSchema,
  });

  factory DocumentTemplateResponse.fromJson(Map<String, dynamic> json) => _$DocumentTemplateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentTemplateResponseToJson(this);

  @override
  List<Object?> get props => [id, name, description, uiSchema];
}
