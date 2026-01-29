# Proyecto IS

Aplicación Flutter multiplataforma diseñada para ejecutarse en **Android** y **Windows**. Para garantizar la consistencia entre diferentes entornos de desarrollo, este proyecto utiliza **FVM (Flutter Version Management)**.

---

## 📋 Requisitos del Sistema

Para compilar y ejecutar este proyecto correctamente, asegúrate de cumplir con los siguientes requisitos:

### 🛠️ Herramientas Generales
- **Git**: Para el control de versiones.
- **FVM**: Para gestionar la versión específica de Flutter del proyecto.
- **Java JDK 17**: Requerido para las compilaciones de Android.

### 🤖 Android
- **Android Studio**: (Versión estable más reciente).
- **Android SDK**: API Level 34 (o superior).
- **Android SDK Build-Tools**: 34.0.0.
- **Gradle**: 8.14 (gestionado automáticamente por el proyecto).

### 💻 Windows
- **Visual Studio 2022**: Con la carga de trabajo "Desarrollo para el escritorio con C++" instalada.
- **CMake**: 3.14 o superior.

---

## 🚀 Configuración del Proyecto

Sigue estos pasos para configurar el entorno de desarrollo:

### 1. Instalar FVM
Si aún no tienes FVM instalado globalmente, ejecútalo desde tu terminal:
```bash
dart pub global activate fvm
```
*Nota: Asegúrate de tener el directorio de binarios de Dart en tu PATH (ej. `%USERPROFILE%\AppData\Local\Pub\Cache\bin`).*

### 2. Clonar el Proyecto
```bash
git clone <url-del-repositorio>
cd proyecto_is
```

### 3. Instalar la Versión de Flutter
El proyecto ya incluye un archivo `.fvmrc` con la versión necesaria (3.38.3). Instálala ejecutando:
```bash
fvm install
fvm use
```

### 4. Obtener Dependencias
```bash
fvm flutter pub get
```

---

## 🏃 Ejecución

Para ejecutar el proyecto en la plataforma deseada:

### Android
```bash
fvm flutter run -d android
```

### Windows
```bash
fvm flutter run -d windows
```

---

## � Notas Adicionales
- **VS Code**: Si usas VS Code, se recomienda instalar la extensión de Flutter y configurar el SDK path para que apunte a `.fvm/flutter_sdk`.
- **Errores de Compilación**: Si tienes problemas con Android, verifica que `JAVA_HOME` apunte a un JDK 17.
```
