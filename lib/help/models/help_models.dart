import 'package:flutter/material.dart';

enum HelpCategory {
  documentos,
  pacientes,
  escaneo,
  general,
}

class HelpStep {
  final String title;
  final String description;
  final IconData icon;

  const HelpStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class HelpTopic {
  final String id;
  final String title;
  final String description;
  final HelpCategory category;
  final List<String> tags;
  final List<HelpStep> steps;

  const HelpTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.steps,
  });
}
