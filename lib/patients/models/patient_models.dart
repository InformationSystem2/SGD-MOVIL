import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patient_models.g.dart';

class CustomDateTimeConverter implements JsonConverter<DateTime, String> {
  const CustomDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    try {
      return DateFormat('yyyy-MM-dd').parse(json);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  String toJson(DateTime object) {
    return DateFormat('yyyy-MM-dd').format(object);
  }
}

@JsonSerializable()
class PatientResponse extends Equatable {
  final String id;
  final String documentType;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final String? gender;
  
  @JsonKey(fromJson: _parseDate, toJson: _formatDate)
  final DateTime? birthDate;

  const PatientResponse({
    required this.id,
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
    this.gender,
    this.birthDate,
  });

  String get fullName => '$firstName $lastName';

  static DateTime? _parseDate(String? json) {
    if (json == null) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(json);
    } catch (_) {
      return null;
    }
  }

  static String? _formatDate(DateTime? object) {
    if (object == null) return null;
    return DateFormat('yyyy-MM-dd').format(object);
  }

  factory PatientResponse.fromJson(Map<String, dynamic> json) => _$PatientResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PatientResponseToJson(this);

  @override
  List<Object?> get props => [
        id,
        documentType,
        documentNumber,
        firstName,
        lastName,
        phone,
        address,
        gender,
        birthDate,
      ];
}

@JsonSerializable()
class PatientCreateRequest extends Equatable {
  final String documentType;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final String? gender;
  
  @CustomDateTimeConverter()
  final DateTime birthDate;

  const PatientCreateRequest({
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
    this.gender,
    required this.birthDate,
  });

  factory PatientCreateRequest.fromJson(Map<String, dynamic> json) => _$PatientCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PatientCreateRequestToJson(this);

  @override
  List<Object?> get props => [
        documentType,
        documentNumber,
        firstName,
        lastName,
        phone,
        address,
        gender,
        birthDate,
      ];
}

@JsonSerializable()
class PatientUpdateRequest extends Equatable {
  final String firstName;
  final String lastName;
  final String documentType;
  final String documentNumber;
  final String? phone;
  final String? address;
  final String? gender;
  
  @CustomDateTimeConverter()
  final DateTime birthDate;

  const PatientUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    this.phone,
    this.address,
    this.gender,
    required this.birthDate,
  });

  factory PatientUpdateRequest.fromJson(Map<String, dynamic> json) => _$PatientUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PatientUpdateRequestToJson(this);

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        documentType,
        documentNumber,
        phone,
        address,
        gender,
        birthDate,
      ];
}
