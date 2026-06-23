# SGD-HC Mobile — Cliente Flutter del Sistema de Gestión Documental y Clínico

**Sistemas de Información II — Universidad Autónoma Gabriel René Moreno (UAGRM)**

## Entregables

| Recurso | Enlace |
|---|---|
| Repositorio público | https://github.com/InformationSystem2/SI2-SGD-HC-mobile |

---

## Información del Proyecto

Este directorio contiene la aplicación móvil de **SGD-HC (Sistema de Gestión Documental y Clínico)**, desarrollada utilizando **Flutter (Dart)** bajo el patrón de arquitectura por capas y utilizando **Provider** para la gestión reactiva del estado del sistema.

La aplicación móvil está optimizada para la portabilidad y la eficiencia en el flujo de trabajo clínico, integrando características clave tales como:
* **Gestión Documental sobre la Marcha**: Navegación rápida, búsqueda y lectura de expedientes e historias clínicas directamente desde el dispositivo móvil.
* **Carga de Documentos con Cámara y Galería**: Integración de cámara nativa y selector de archivos para cargar expedientes en PDF o imágenes directamente al motor de OCR.
* **Persistencia de Sesión Segura**: Comprobación dinámica de autenticación en arranque y almacenamiento seguro local de tokens.

---

## Arquitectura de Flujo de Datos

```
   Arranca la App (main.dart) 
          │  
          ▼
   AuthGate ──► Consulta estado de autenticación en StorageService
          ├── Autenticado: Redirige a DocumentListScreen
          └── No Autenticado: Redirige a LoginScreen
          
   Petición HTTP (Mobile) 
          │  
          ▼
   ApiClient (core/services) ──► Inyecta JWT en cabecera 'Authorization'
          │
          ▼
   Services (document_service, patient_service, etc.) ──► Consume Endpoints del Backend
          │
          ▼
   ChangeNotifier (Provider) ──► Notifica y actualiza la UI de forma reactiva
```

---

## Estructura del Proyecto

```
sgd_futter/
├── lib/
│   ├── core/                       # Núcleo de la aplicación móvil
│   │   ├── config/                 # Configuraciones base (URL base de la API, etc.)
│   │   ├── services/               # Clientes HTTP (ApiClient) y persistencia local
│   │   ├── theme/                  # Temas gráficos (claro, oscuro y variables de color)
│   │   └── widgets/                # Componentes y elementos de UI comunes
│   │
│   ├── documents/                  # Módulo de Documentos Clínicos
│   │   ├── models/                 # Modelos de datos de documentos y plantillas
│   │   ├── screens/                # Vistas (lista, detalle, carga)
│   │   ├── services/               # Lógica de consumo de API de documentos
│   │   └── widgets/                # Componentes específicos del módulo
│   │
│   ├── patients/                   # Módulo de Pacientes
│   │   ├── models/                 # Modelo del Paciente e Historia Clínica
│   │   ├── screens/                # Lista e historial de pacientes, formulario
│   │   └── services/               # Lógica de consumo de API de pacientes
│   │
│   ├── security/                   # Módulo de Autenticación y Acceso
│   │   ├── models/                 # Schemas de usuario y auth token
│   │   ├── screens/                # Pantalla de Login
│   │   └── services/               # Lógica de inicio de sesión y gestión de sesión
│   │
│   └── main.dart                   # Punto de inicio (inicialización de Providers y Rutas)
│
├── assets/                         # Logotipos y recursos de imagen estáticos
├── pubspec.yaml                    # Gestión de dependencias y recursos de Flutter
└── README.md
```

---

## Tecnologías

### Core & Framework
| Tecnología | Versión | Uso |
|---|---|---|
| Flutter SDK | ^3.12.0 | Framework multiplataforma de Google para desarrollo móvil |
| Dart | ^3.x | Lenguaje de programación optimizado para interfaces de usuario |
| Provider | ^6.1.5 | Gestor de estado simple, escalable y oficial |

### Librerías de Integración y Utilidades
| Tecnología | Versión | Uso |
|---|---|---|
| HTTP | ^1.6.0 | Cliente HTTP para consumir la API de Spring Boot y FastAPI |
| Shared Preferences | ^2.5.5 | Persistencia en disco local para almacenar configuraciones y tokens JWT |
| File Picker | ^8.0.0 | Componente para selección de archivos PDF e imágenes en el dispositivo |
| Equatable | ^2.0.8 | Simplificación de comparación de objetos de Dart |

---

## Instalación y Ejecución

### 1. Requisitos Previos
* Flutter SDK (v3.12.x o superior) configurado.
* Android SDK y/o Xcode instalados para emulación o pruebas físicas.
* Dispositivo móvil o emulador en ejecución.

### 2. Configurar Variables de Entorno
Configure la dirección IP o dominio del backend principal en `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8080/api'; // O la IP local de su servidor
}
```

### 3. Compilar e Iniciar la Aplicación

Obtener los paquetes de dependencias de Flutter:
```bash
flutter pub get
```

Ejecutar generadores de código si fuera necesario (p. ej., serialización JSON):
```bash
flutter pub run build_runner build
```

Iniciar la aplicación en el emulador o dispositivo conectado:
```bash
flutter run
```

La aplicación compilará e iniciará el ciclo de vida cargando en el dispositivo móvil seleccionado.

---

## Pantallas Principales

| Ruta / Widget | Flujo / Pantalla | Descripción |
|---|---|---|
| `LoginScreen` | Inicio de Sesión | Autenticación del usuario y almacenamiento del token JWT |
| `DocumentListScreen` | Explorador Clínico | Panel principal que lista documentos de la clínica |
| `DocumentDetailScreen` | Detalle del Documento | Muestra metadatos y contenido clínico estructurado de un documento |
| `DocumentUploadScreen` | Subida de Archivos | Captura o selección de archivos para el servicio de digitalización OCR |
| `PatientListScreen` | Directorio de Pacientes | Listado y búsqueda rápida de pacientes de la clínica activa |
| `PatientFormScreen` | Registro de Pacientes | Formulario de adición y edición de datos demográficos y clínicos |

---

## Módulo de Seguridad y Persistencia

### Gestión de Sesión Segura y Auto-login
Al iniciar la aplicación, la puerta de enlace `AuthGate` comprueba la existencia de un JWT válido y del Tenant ID guardados en `shared_preferences`. Si están presentes y no han expirado, el usuario es redirigido de forma transparente al panel de documentos (`DocumentListScreen`), evitando la necesidad de iniciar sesión constantemente en el dispositivo.

### Control de Visibilidad y Edición Granular
Los widgets de formulario y visualización de datos aplican lógica condicional para asegurar que la información no autorizada no se renderice:
1. **Comprobación de Roles**: Acceso a roles directos del usuario autenticado para mostrar/ocultar paneles administrativos.
2. **Restricción de Atributos**: Campos sensibles del historial clínico del paciente se ocultan o se renderizan como deshabilitados si el rol del usuario no tiene los permisos requeridos asignados en el backend.

---

## Por qué control de accesos a nivel de atributos y no de endpoints simple

| Tipo de Control | Permite ocultar campos sensibles | Flexibilidad por Rol | Complejidad de UI |
|---|---|---|---|
| **Control por Endpoint (`/paciente/{id}`)** | No (Muestra la pantalla completa o no) | Baja | Baja |
| **Control a nivel de Atributo (SGD-HC)** | **Sí** (Oculta campos sensibles de texto) | **Alta** (Granularidad según permisos) | Media (Widgets condicionales) |

---

## Equipo

| Integrante | Rol |
|---|---|
| **Evert Rodríguez Araúz** | Backend Developer / Arquitecto de Software |
| *[Integrante 2]* | *[Rol]* |
| *[Integrante 3]* | *[Rol]* |

---

*Proyecto desarrollado para la materia de Sistemas de Información II — UAGRM*
