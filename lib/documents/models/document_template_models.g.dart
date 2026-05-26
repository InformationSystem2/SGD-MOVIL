// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_template_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldConfig _$FieldConfigFromJson(Map<String, dynamic> json) => FieldConfig(
  type: $enumDecode(_$FieldTypeEnumMap, json['type']),
  required: json['required'] as bool,
  label: json['label'] as String,
  order: (json['order'] as num).toInt(),
  options:
      (json['options'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      {},
  subSchema: (json['subSchema'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, FieldConfig.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$FieldConfigToJson(FieldConfig instance) =>
    <String, dynamic>{
      'type': _$FieldTypeEnumMap[instance.type]!,
      'required': instance.required,
      'label': instance.label,
      'order': instance.order,
      'options': instance.options,
      'subSchema': instance.subSchema?.map((k, e) => MapEntry(k, e.toJson())),
    };

const _$FieldTypeEnumMap = {
  FieldType.TEXT: 'TEXT',
  FieldType.TEXTAREA: 'TEXTAREA',
  FieldType.EMAIL: 'EMAIL',
  FieldType.NUMBER: 'NUMBER',
  FieldType.DATE: 'DATE',
  FieldType.TIME: 'TIME',
  FieldType.SELECT: 'SELECT',
  FieldType.RADIO: 'RADIO',
  FieldType.CHECKBOX: 'CHECKBOX',
  FieldType.FILE: 'FILE',
  FieldType.DISPLAY_TEXT: 'DISPLAY_TEXT',
  FieldType.ARRAY: 'ARRAY',
};

DocumentTemplateResponse _$DocumentTemplateResponseFromJson(
  Map<String, dynamic> json,
) => DocumentTemplateResponse(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  uiSchema: (json['uiSchema'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, FieldConfig.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$DocumentTemplateResponseToJson(
  DocumentTemplateResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'uiSchema': instance.uiSchema.map((k, e) => MapEntry(k, e.toJson())),
};
