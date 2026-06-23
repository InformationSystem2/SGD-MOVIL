import 'package:flutter/material.dart';
import '../models/help_models.dart';

const List<HelpTopic> helpTopics = [

  // ── DOCUMENTOS ─────────────────────────────────────────────────────────────

  HelpTopic(
    id: 'ver_documentos',
    title: 'Ver lista de documentos',
    description: 'Cómo navegar y buscar documentos registrados en el sistema.',
    category: HelpCategory.documentos,
    tags: ['lista', 'buscar', 'documentos', 'historial'],
    steps: [
      HelpStep(
        title: 'Pantalla principal',
        description: 'Al iniciar sesión, la pantalla principal muestra todos los documentos registrados en el sistema.',
        icon: Icons.description_outlined,
      ),
      HelpStep(
        title: 'Buscar un documento',
        description: 'Use la barra de búsqueda en la parte superior para filtrar por nombre del paciente, CI o título del documento.',
        icon: Icons.search,
      ),
      HelpStep(
        title: 'Ver el detalle',
        description: 'Toque cualquier documento de la lista para ver su información completa: datos del paciente, metadatos, notas y archivo adjunto.',
        icon: Icons.open_in_new_rounded,
      ),
      HelpStep(
        title: 'Actualizar la lista',
        description: 'Deslice hacia abajo (pull to refresh) para recargar la lista con los documentos más recientes.',
        icon: Icons.refresh_rounded,
      ),
    ],
  ),

  HelpTopic(
    id: 'subir_archivo',
    title: 'Subir documento externo',
    description: 'Cómo adjuntar un archivo PDF o imagen del dispositivo a un paciente.',
    category: HelpCategory.documentos,
    tags: ['subir', 'archivo', 'pdf', 'imagen', 'externo', 'adjuntar'],
    steps: [
      HelpStep(
        title: 'Abrir el formulario',
        description: 'Toque el botón "Nuevo Documento" (botón flotante en la esquina inferior derecha).',
        icon: Icons.add_circle_outline,
      ),
      HelpStep(
        title: 'Ir a la pestaña "Subir Archivo"',
        description: 'Seleccione la segunda pestaña "Subir Archivo" en la parte superior del formulario.',
        icon: Icons.cloud_upload_outlined,
      ),
      HelpStep(
        title: 'Seleccionar paciente y fecha',
        description: 'En la parte superior elija el paciente al que pertenece el documento y la fecha de emisión.',
        icon: Icons.person_outline,
      ),
      HelpStep(
        title: 'Ingresar título',
        description: 'Escriba un título descriptivo para el documento (ej: "Análisis de sangre", "Receta médica").',
        icon: Icons.title,
      ),
      HelpStep(
        title: 'Seleccionar el archivo',
        description: 'Toque el área punteada para abrir el selector de archivos del dispositivo. Se aceptan PDF, imágenes y documentos de texto.',
        icon: Icons.attach_file,
      ),
      HelpStep(
        title: 'Registrar',
        description: 'Pulse "Subir y Registrar Documento". El archivo se subirá al servidor y quedará asociado al paciente.',
        icon: Icons.save_alt_rounded,
      ),
    ],
  ),

  HelpTopic(
    id: 'formulario_plantilla',
    title: 'Registrar documento con plantilla',
    description: 'Cómo crear un documento clínico estructurado usando una plantilla predefinida.',
    category: HelpCategory.documentos,
    tags: ['plantilla', 'formulario', 'clinico', 'registrar', 'historia'],
    steps: [
      HelpStep(
        title: 'Abrir el formulario',
        description: 'Toque "Nuevo Documento" en la pantalla principal.',
        icon: Icons.add_circle_outline,
      ),
      HelpStep(
        title: 'Pestaña "Formulario"',
        description: 'La primera pestaña "Formulario" permite crear documentos basados en plantillas clínicas.',
        icon: Icons.assignment_outlined,
      ),
      HelpStep(
        title: 'Seleccionar paciente y fecha',
        description: 'Elija el paciente y la fecha de emisión del documento.',
        icon: Icons.person_outline,
      ),
      HelpStep(
        title: 'Elegir plantilla',
        description: 'Seleccione la plantilla adecuada (ej: Historia Clínica, Receta, Informe). El formulario se generará automáticamente.',
        icon: Icons.description_outlined,
      ),
      HelpStep(
        title: 'Completar los campos',
        description: 'Rellene los campos del formulario según el tipo de plantilla seleccionada.',
        icon: Icons.edit_outlined,
      ),
      HelpStep(
        title: 'Guardar',
        description: 'Pulse "Registrar Documento" para guardar el documento clínico en el sistema.',
        icon: Icons.save_outlined,
      ),
    ],
  ),

  HelpTopic(
    id: 'detalle_documento',
    title: 'Ver detalle de un documento',
    description: 'Qué información se muestra al abrir un documento.',
    category: HelpCategory.documentos,
    tags: ['detalle', 'ver', 'metadatos', 'archivo', 'ia'],
    steps: [
      HelpStep(
        title: 'Abrir el documento',
        description: 'Toque cualquier documento de la lista principal para abrir su vista de detalle.',
        icon: Icons.open_in_new_rounded,
      ),
      HelpStep(
        title: 'Estado del documento',
        description: 'La barra superior muestra el estado: Borrador, En Revisión, Rechazado o Finalizado.',
        icon: Icons.info_outline,
      ),
      HelpStep(
        title: 'Datos del paciente',
        description: 'Nombre completo y número de CI del paciente al que pertenece el documento.',
        icon: Icons.person_outline,
      ),
      HelpStep(
        title: 'Metadatos',
        description: 'Quién registró el documento, fecha de emisión y origen (plantilla o archivo externo).',
        icon: Icons.data_object_rounded,
      ),
      HelpStep(
        title: 'Información y notas',
        description: 'Para documentos externos: título, notas del usuario y —si fue procesado con IA— los datos detectados automáticamente.',
        icon: Icons.auto_awesome,
      ),
      HelpStep(
        title: 'Archivo adjunto',
        description: 'Si el documento tiene un archivo, puede copiar el enlace o ver la URL completa para acceder desde un navegador.',
        icon: Icons.attachment_rounded,
      ),
    ],
  ),

  // ── PACIENTES ──────────────────────────────────────────────────────────────

  HelpTopic(
    id: 'registrar_paciente',
    title: 'Registrar nuevo paciente',
    description: 'Cómo agregar un paciente al sistema desde la app móvil.',
    category: HelpCategory.pacientes,
    tags: ['paciente', 'registrar', 'nuevo', 'agregar', 'ci'],
    steps: [
      HelpStep(
        title: 'Ir a Pacientes',
        description: 'Abra el menú lateral (ícono ☰ en la esquina superior izquierda) y toque "Pacientes".',
        icon: Icons.people_outline_rounded,
      ),
      HelpStep(
        title: 'Nuevo paciente',
        description: 'Toque el botón flotante "Nuevo Paciente" en la esquina inferior derecha.',
        icon: Icons.person_add_outlined,
      ),
      HelpStep(
        title: 'Completar el formulario',
        description: 'Ingrese nombre, apellido, CI, fecha de nacimiento y demás datos requeridos.',
        icon: Icons.edit_outlined,
      ),
      HelpStep(
        title: 'Guardar',
        description: 'Pulse "Registrar Paciente" para guardar. El paciente estará disponible al crear documentos.',
        icon: Icons.save_outlined,
      ),
    ],
  ),

  HelpTopic(
    id: 'buscar_paciente',
    title: 'Buscar un paciente',
    description: 'Cómo encontrar a un paciente en la lista.',
    category: HelpCategory.pacientes,
    tags: ['buscar', 'paciente', 'filtrar', 'ci', 'nombre'],
    steps: [
      HelpStep(
        title: 'Ir a Pacientes',
        description: 'Abra el menú lateral y seleccione "Pacientes".',
        icon: Icons.people_outline_rounded,
      ),
      HelpStep(
        title: 'Usar la búsqueda',
        description: 'Escriba el nombre o número de CI en la barra de búsqueda superior para filtrar la lista.',
        icon: Icons.search,
      ),
      HelpStep(
        title: 'Ver o editar',
        description: 'Toque el paciente para ver su información o acceder a sus documentos.',
        icon: Icons.open_in_new_rounded,
      ),
    ],
  ),

  // ── ESCANEO ────────────────────────────────────────────────────────────────

  HelpTopic(
    id: 'escanear_sin_ia',
    title: 'Escanear y guardar sin IA',
    description: 'Cómo capturar un documento con la cámara y guardarlo directamente.',
    category: HelpCategory.escaneo,
    tags: ['escanear', 'camara', 'guardar', 'pdf', 'scan'],
    steps: [
      HelpStep(
        title: 'Abrir el escáner',
        description: 'Pulse "Nuevo Documento" y vaya a la pestaña "Escanear", o use "Escanear Documento" en el menú lateral.',
        icon: Icons.document_scanner_rounded,
      ),
      HelpStep(
        title: 'Seleccionar paciente y fecha',
        description: 'Elija el paciente y la fecha de emisión en la parte superior.',
        icon: Icons.person_outline,
      ),
      HelpStep(
        title: 'Capturar el documento',
        description: 'Toque el área de escaneo para abrir la cámara. Enfoque el documento y tome la foto.',
        icon: Icons.camera_alt_outlined,
      ),
      HelpStep(
        title: 'Agregar más páginas (opcional)',
        description: 'Si el documento tiene varias páginas, toque "Añadir Página" para capturar cada una.',
        icon: Icons.add_a_photo_outlined,
      ),
      HelpStep(
        title: 'Ingresar título',
        description: 'Escriba un título descriptivo para identificar el documento (campo obligatorio).',
        icon: Icons.title,
      ),
      HelpStep(
        title: 'Guardar',
        description: 'Pulse "Guardar Documento". Las imágenes se convierten automáticamente a PDF y se registran en el sistema.',
        icon: Icons.save_alt_rounded,
      ),
    ],
  ),

  HelpTopic(
    id: 'escanear_con_ia',
    title: 'Procesar escaneo con IA',
    description: 'Cómo usar la inteligencia artificial para extraer datos del documento escaneado.',
    category: HelpCategory.escaneo,
    tags: ['ia', 'ocr', 'inteligencia', 'artificial', 'extraer', 'datos', 'gemini'],
    steps: [
      HelpStep(
        title: 'Escanear el documento',
        description: 'Capture el documento con la cámara siguiendo los pasos normales de escaneo.',
        icon: Icons.document_scanner_rounded,
      ),
      HelpStep(
        title: 'Ingresar título',
        description: 'Escriba el título que tendrá el documento. La IA lo usará como referencia pero no lo modifica.',
        icon: Icons.title,
      ),
      HelpStep(
        title: 'Pulsar "Procesar con IA"',
        description: 'Toque el botón secundario "Procesar con IA" (ícono de estrella). El sistema enviará las imágenes al servicio de OCR.',
        icon: Icons.auto_awesome,
      ),
      HelpStep(
        title: 'Revisar los datos detectados',
        description: 'Se mostrará un diálogo con el texto extraído y los datos clave identificados (tipo de documento, medicamentos, diagnóstico, etc.).',
        icon: Icons.preview_rounded,
      ),
      HelpStep(
        title: 'Editar notas (opcional)',
        description: 'Puede agregar o modificar las notas antes de confirmar. El título ya fue definido previamente.',
        icon: Icons.edit_note_rounded,
      ),
      HelpStep(
        title: 'Confirmar y guardar',
        description: 'Toque "Confirmar y Guardar". Los datos de la IA quedarán visibles en el detalle del documento.',
        icon: Icons.check_circle_outline,
      ),
    ],
  ),

  HelpTopic(
    id: 'filtros_imagen',
    title: 'Filtros de imagen al escanear',
    description: 'Cómo mejorar la legibilidad del documento usando filtros visuales.',
    category: HelpCategory.escaneo,
    tags: ['filtro', 'imagen', 'gris', 'blanco', 'negro', 'contraste'],
    steps: [
      HelpStep(
        title: 'Selector de filtros',
        description: 'En la pantalla de escaneo, encontrará tres opciones de filtro: Normal, Escala de Grises y B/N Contraste.',
        icon: Icons.filter_b_and_w_outlined,
      ),
      HelpStep(
        title: 'Normal',
        description: 'Mantiene los colores originales de la foto. Ideal para documentos con colores importantes.',
        icon: Icons.wb_sunny_outlined,
      ),
      HelpStep(
        title: 'Escala de Grises',
        description: 'Convierte la imagen a tonos grises. Reduce el tamaño y mejora la legibilidad en documentos impresos.',
        icon: Icons.filter_hdr_outlined,
      ),
      HelpStep(
        title: 'B/N Contraste',
        description: 'Aplica binarización: blanco y negro extremo. Ideal para documentos con texto negro sobre fondo claro.',
        icon: Icons.camera_enhance_outlined,
      ),
    ],
  ),

  // ── GENERAL ────────────────────────────────────────────────────────────────

  HelpTopic(
    id: 'menu_navegacion',
    title: 'Navegar por la aplicación',
    description: 'Cómo usar el menú lateral para acceder a todas las secciones.',
    category: HelpCategory.general,
    tags: ['menu', 'navegar', 'secciones', 'lateral', 'drawer'],
    steps: [
      HelpStep(
        title: 'Abrir el menú',
        description: 'Toque el ícono ☰ en la esquina superior izquierda o deslice desde el borde izquierdo de la pantalla.',
        icon: Icons.menu_rounded,
      ),
      HelpStep(
        title: 'Secciones disponibles',
        description: 'El menú incluye: Pacientes, Documentos y Escanear Documento.',
        icon: Icons.list_rounded,
      ),
      HelpStep(
        title: 'Funciones según plan',
        description: 'Algunas funciones pueden estar bloqueadas según el plan contratado. Aparecerán con un ícono de candado.',
        icon: Icons.lock_outline,
      ),
    ],
  ),

  HelpTopic(
    id: 'cerrar_sesion',
    title: 'Cerrar sesión',
    description: 'Cómo salir de la aplicación de forma segura.',
    category: HelpCategory.general,
    tags: ['logout', 'salir', 'cerrar', 'sesion'],
    steps: [
      HelpStep(
        title: 'Abrir el menú lateral',
        description: 'Toque el ícono ☰ o deslice desde el borde izquierdo.',
        icon: Icons.menu_rounded,
      ),
      HelpStep(
        title: 'Pulsar "Cerrar Sesión"',
        description: 'En la parte inferior del menú encontrará la opción "Cerrar Sesión" en rojo.',
        icon: Icons.logout_rounded,
      ),
      HelpStep(
        title: 'Confirmación',
        description: 'La sesión se cierra y será redirigido a la pantalla de inicio de sesión.',
        icon: Icons.check_circle_outline,
      ),
    ],
  ),

  HelpTopic(
    id: 'estados_documento',
    title: 'Estados de un documento',
    description: 'Qué significa cada estado que puede tener un documento.',
    category: HelpCategory.general,
    tags: ['estado', 'borrador', 'revision', 'rechazado', 'finalizado'],
    steps: [
      HelpStep(
        title: 'Borrador',
        description: 'El documento fue creado pero aún no ha sido enviado a revisión. Puede ser modificado.',
        icon: Icons.edit_outlined,
      ),
      HelpStep(
        title: 'En Revisión',
        description: 'El documento fue enviado para ser revisado por un responsable. En espera de aprobación.',
        icon: Icons.hourglass_empty_rounded,
      ),
      HelpStep(
        title: 'Rechazado',
        description: 'El documento fue revisado y no fue aprobado. Puede ser corregido y vuelto a enviar.',
        icon: Icons.cancel_outlined,
      ),
      HelpStep(
        title: 'Finalizado',
        description: 'El documento fue aprobado y está firmado digitalmente. Es inmutable y no puede modificarse.',
        icon: Icons.verified_outlined,
      ),
    ],
  ),
];

// Helpers
List<HelpTopic> getTopicsByCategory(HelpCategory category) =>
    helpTopics.where((t) => t.category == category).toList();

List<HelpTopic> searchTopics(String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return helpTopics;
  return helpTopics.where((t) {
    return t.title.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q) ||
        t.tags.any((tag) => tag.contains(q));
  }).toList();
}

HelpTopic? getTopicById(String id) {
  try {
    return helpTopics.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
}
