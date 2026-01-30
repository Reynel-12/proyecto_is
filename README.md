# 📦 Sistema de Inventario y Facturación (Proyecto IS)

Bienvenido a la documentación oficial del **Sistema de Inventario y Facturación**. Este es un proyecto desarrollado en **Flutter** diseñado para funcionar de manera nativa tanto en **Windows** como en **Android**. El sistema permite gestionar inventarios, ventas, proveedores, control de caja y facturación cumpliendo con normativas fiscales (SAR Honduras).

---

## 📑 Índice

1. [Características Principales](#-características-principales)
2. [Tecnologías Utilizadas](#-tecnologías-utilizadas)
3. [Arquitectura del Proyecto](#-arquitectura-del-proyecto)
4. [Requisitos del Sistema](#-requisitos-del-sistema)
5. [Instalación y Configuración](#-instalación-y-configuración)
6. [Estructura de Carpetas](#-estructura-de-carpetas)
7. [Guía de Uso](#-guía-de-uso)

---

## 🚀 Características Principales

*   **Gestión de Inventario**: Altas, bajas y modificaciones de productos. Control de stock y alertas de existencias bajas.
*   **Punto de Venta (POS)**: Interfaz ágil para realizar ventas, cálculo automático de impuestos (ISV) y descuentos.
*   **Facturación SAR**: Soporte para CAI, rangos de facturación y fechas límite, adaptado a la normativa hondureña.
*   **Gestión de Proveedores**: Base de datos de proveedores y sus productos asociados.
*   **Control de Caja**: Apertura y cierre de caja, registro de movimientos (ingresos/egresos) y arqueo.
*   **Múltiples Usuarios**: Roles de usuario (Administrador, Vendedor) con permisos diferenciados.
*   **Reportes**: Historial de ventas, gráficos de rendimiento y reportes de inventario.
*   **Escáner de Códigos de Barra**: Integración con cámara para escaneo rápido de productos.
*   **Soporte Multiplataforma**: Experiencia optimizada para escritorio (Windows) y dispositivos móviles (Android).
*   **Modo Oscuro/Claro**: Adaptabilidad visual según la preferencia del usuario.

---

## 🛠 Tecnologías Utilizadas

*   **Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **Gestión de Estado**: `Provider` + `setState` para manejo local y global.
*   **Base de Datos Local**: `sqflite` (Android) / `sqflite_common_ffi` (Windows).
*   **Impresión**: `pdf` y `printing` para generación de facturas térmicas y reportes.
*   **Utilidades UI**: `awesome_dialog`, `awesome_snackbar_content`, `shimmer`, `flutter_speed_dial`.
*   **Versiones**: Gestión de versión de Flutter mediante **FVM**.

---

## 🏗 Arquitectura del Proyecto

El proyecto sigue una arquitectura por capas para separar la lógica de negocio de la interfaz de usuario:

### 1. **Model (Modelos)**
Ubicado en `lib/model`.
Define las estructuras de datos (Clases POJO) que representan las entidades del negocio, como `Producto`, `Venta`, `Usuario`, `Caja`. Incluyen métodos `toMap` y `fromMap` para la serialización con la base de datos.

### 2. **Controller (Repositorios)**
Ubicado en `lib/controller`.
Actúa como la capa de acceso a datos (Data Access Layer). Aquí se encuentran los `Repository` (ej. `RepositoryProducto`, `RepositoryVenta`) que contienen la lógica para interactuar con la base de datos SQLite (CRUD).
*   **`database.dart`**: Clase Singleton que gestiona la conexión a la base de datos y la creación/migración de tablas.

### 3. **View (Vistas)**
Ubicado en `lib/view`.
Contiene todos los Widgets y pantallas de la aplicación.
*   Las vistas se comunican con los **Controladores** para obtener o guardar datos.
*   Utiliza `StatefulWidget` para lógica local y `Provider` (como `TemaProveedor`) para estado global.

---

## 📋 Requisitos del Sistema

### 🛠️ Herramientas de Desarrollo
-   **Git**: Para control de versiones.
-   **FVM (Flutter Version Management)**: Recomendado para sincronizar la versión de Flutter.
-   **Java JDK 17**: Necesario para compilar en Android.

### 🤖 Android
-   **Android Studio**: Última versión estable.
-   **SDK Android**: API Level 34+.
-   **Build-Tools**: 34.0.0.

### 💻 Windows
-   **Visual Studio 2022**: Con la carga de trabajo "Desarrollo para el escritorio con C++".
-   **CMake**: 3.14+.

---

## ⚙️ Instalación y Configuración

Sigue estos pasos para levantar el entorno de desarrollo:

### 1. Clonar el Repositorio
```bash
git clone <url-del-repositorio>
cd proyecto_is
```

### 2. Configurar Flutter con FVM
Este proyecto usa una versión específica de Flutter.
```bash
# Instalar FVM si no lo tienes globalmente
dart pub global activate fvm

# Instalar la versión configurada en .fvmrc
fvm install
fvm use
```

### 3. Instalar Dependencias
```bash
fvm flutter pub get
```

### 4. Ejecutar la Aplicación
**Para Windows:**
```bash
fvm flutter run -d windows
```

**Para Android:**
Conecta tu dispositivo o inicia un emulador.
```bash
fvm flutter run -d android
```

---

## 📂 Estructura de Carpetas

```
lib/
├── controller/         # Lógica de acceso a datos (Repositorios y DB)
│   ├── database.dart   # Configuración de SQLite
│   ├── repository_*.dart
├── model/              # Clases de entidades (Producto, Usuario, Venta, etc.)
├── utils/              # Utilidades generales
├── view/               # Pantallas y Widgets de la UI
│   ├── widgets/        # Widgets reutilizables
│   ├── login_wrapper.dart
│   ├── ... (Pantallas específicas: ventas, inventario, etc.)
├── main.dart           # Punto de entrada de la aplicación
```

---

## 📖 Guía de Uso

1.  **Inicio de Sesión**:
    *   Al iniciar, se cargará la pantalla de Login.
    *   Si es la primera vez, el sistema puede requerir crear un usuario administrador inicial o usar credenciales por defecto (consultar base de datos si aplica).

2.  **Navegación Principal**:
    *   El **Dashboard (Principal)** muestra tarjetas de acceso rápido a Ventas, Inventario, Caja, etc.
    *   Usa el menú lateral (si está disponible) o los iconos para navegar.

3.  **Realizar una Venta**:
    *   Ve a **Ventas**.
    *   Escanea un producto o búscalo manualmente.
    *   Ajusta cantidades.
    *   Selecciona "Cobrar", elige el método de pago e imprime la factura.

4.  **Cierre de Caja**:
    *   Al finalizar el turno, ve a **Caja**.
    *   Selecciona "Cerrar Caja".
    *   Ingresa el monto real en efectivo contado. El sistema calculará sobrantes o faltantes.

---

## 🤝 Contribución

Para colaborar en el proyecto:
1.  Asegúrate de estar en la rama `dev` o crear una nueva rama para tu feature: `git checkout -b feature/nueva-funcionalidad`.
2.  Sigue los estándares de código de Flutter (WIdgets separados, nombres descriptivos).
3.  Prueba tus cambios en ambas plataformas (Windows y Android) si es posible.
4.  Haz Push y crea un Pull Request.

---
**Desarrollado para la clase de Ingeniería de Software.**
