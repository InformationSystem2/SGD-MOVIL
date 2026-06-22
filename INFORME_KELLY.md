# Informe de Implementación — Misión de Kelly (SGD Móvil)

Este documento resume el trabajo realizado en la aplicación móvil **SGD-MOVIL** para cumplir con los requerimientos asignados a Kelly. Las funcionalidades implementadas utilizan recursos nativos y se adaptan a las restricciones de planes de suscripción de los tenants (QA).

---

## 1. Escáner de Documentos usando la Cámara (Nativo)
Se implementó un escáner integrado directamente utilizando la cámara nativa del celular a través del plugin oficial `image_picker`.
* **Ubicación:** Pestaña **Escanear** en la pantalla "Nuevo Documento" (`document_upload_screen.dart`).
* **Características:**
  * Acceso seguro y controlado a la cámara trasera del celular.
  * Vista previa interactiva de la imagen capturada.
  * Opción de **Re-escanear** en caso de que la foto no sea legible.
  * Lógica para convertir la captura en bytes (`Uint8List`) y subirla al backend Spring Boot a través del servicio de documentos como un documento externo.

---

## 2. Subida de Documentos desde el Almacenamiento
Se integró la funcionalidad para seleccionar archivos y documentos almacenados en el celular.
* **Ubicación:** Pestaña **Subir Archivo** en la pantalla "Nuevo Documento" (`document_upload_screen.dart`).
* **Características:**
  * Uso del plugin `file_picker` compatible con múltiples plataformas.
  * Soporte para múltiples extensiones (PDF, imágenes, archivos de texto).
  * Lectura eficiente de los bytes en memoria y envío directo al servidor backend (`uploadFile`).
  * Formulario con campo para añadir notas adicionales descriptivas antes del registro.

---

## 3. Interfaz Móvil del Asistente IA (Premium)
Se diseñó y desarrolló una interfaz interactiva de chat con estética moderna y fluida para interactuar con la inteligencia artificial del sistema.
* **Ubicación:** Pantalla del Asistente IA (`/assistant`, `assistant_screen.dart`).
* **Características:**
  * **Estilo Visual Premium:** Burbujas de chat diferenciadas por color para usuario y asistente, soporte completo para modo claro/oscuro (glassmorphism y paletas dinámicas HSL).
  * **Sugerencias Rápidas:** Chips interactivos para preguntas comunes (ej: *"¿Cuántos pacientes tenemos?"*).
  * **Micro-animación de Escritura:** Indicador de tres puntos parpadeando rítmicamente mientras el asistente procesa la respuesta.
  * **Gestión de Sesión:** Opción para limpiar el historial de la conversación actual en cualquier momento.
  * **Resiliencia ante Errores:** Mensajes amigables y controlados si el servicio de IA no está activo en el backend.

---

## 4. Validación QA: Restricciones por Plan de Tenant
Para garantizar el cumplimiento de los contratos comerciales, se implementó un sistema de control de accesos basado en el plan del tenant actual (`BASIC`, `PRO`, `ENTERPRISE`).

### Estructura de Restricciones:
| Funcionalidad | Plan BASIC | Plan PRO | Plan ENTERPRISE |
| :--- | :---: | :---: | :---: |
| **Subir archivos locales** | ✅ Permitido | ✅ Permitido | ✅ Permitido |
| **Escáner de cámara** | ❌ Bloqueado | ✅ Permitido | ✅ Permitido |
| **Asistente IA** | ❌ Bloqueado | ❌ Bloqueado | ✅ Permitido |

### Implementación del Bloqueo:
1. **Lógica de Negocio (`tenant_service.dart`):** Consulta el endpoint del backend `/api/tenants/current/info` para determinar el plan actual y expone getters como `canUseScan` y `canUseAssistant`.
2. **Control en Menú Lateral (`navigation_drawer.dart`):**
   * Las opciones no permitidas muestran visualmente un candado amarillo con la etiqueta del plan requerido (`PRO` o `ENTERPRISE`).
   * Intentar hacer clic en una opción bloqueada muestra un `SnackBar` advirtiendo al usuario de la restricción del plan.
3. **Protección a Nivel de Pantalla:**
   * En `document_upload_screen.dart`, la pestaña **Escanear** solo se renderiza si el plan lo permite.
   * En `assistant_screen.dart`, se realiza un doble chequeo. Si se accede directamente a la ruta `/assistant`, se muestra una pantalla de bloqueo informativa para impedir el acceso ilícito.

---

## 5. Resumen de Archivos Afectados

### 📁 Nuevos Archivos Creados:
* [tenant_service.dart](file:///d:/Universidad/Si212026/SGD-MOVIL/lib/core/services/tenant_service.dart): Control centralizado de planes.
* [assistant_models.dart](file:///d:/Universidad/Si212026/SGD-MOVIL/lib/assistant/models/assistant_models.dart): Modelos de datos del chat.
* [assistant_service.dart](file:///d:/Universidad/Si212026/SGD-MOVIL/lib/assistant/services/assistant_service.dart): Servicio de comunicación con el backend de IA.
* [assistant_screen.dart](file:///d:/Universidad/Si212026/SGD-MOVIL/lib/assistant/screens/assistant_screen.dart): Interfaz premium del chat del asistente.

### 📝 Archivos Modificados:
* [pubspec.yaml](file:///d:/Universidad/Si212026/SGD-MOVIL/pubspec.yaml): Registro de la dependencia `image_picker`.
* [main.dart](file:///d:/Universidad/Si212026/SGD-MOVIL/lib/main.dart): Registro de los nuevos providers de servicios y la ruta del asistente.
* [navigation_drawer.dart](file:///d:/Universidad/Si212026/SGD-MOVIL/lib/core/widgets/navigation_drawer.dart): Inclusión de las opciones bloqueables por plan.
* [document_upload_screen.dart](file:///d:/Universidad/Si212026/SGD-MOVIL/lib/documents/screens/document_upload_screen.dart): Separación de vistas por pestañas y adición del escáner con cámara.
* [AndroidManifest.xml](file:///d:/Universidad/Si212026/SGD-MOVIL/android/app/src/main/AndroidManifest.xml): Permisos nativos de Android para el uso de la cámara.
* [Info.plist](file:///d:/Universidad/Si212026/SGD-MOVIL/ios/Runner/Info.plist): Permisos de cámara y descripción de uso para iOS.
