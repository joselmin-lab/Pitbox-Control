# Pitbox Control

Pitbox Control es una app multiplataforma para la gestión de talleres mecánicos. Esta versión incluye **Fase 1 + Fase 2**: base de interfaz modular y módulos funcionales de **Clientes**, **Vehículos**, **Servicios**, **Paquetes de servicios** y **Datos del taller** con relación **1:N** (clientes/vehículos) y **N:N** (paquetes/servicios).

## Stack técnico

- Flutter 3.x / Dart con null safety
- `flutter_riverpod` para estado de UI desacoplado
- `go_router` para navegación declarativa
- `supabase_flutter` para backend real de Clientes, Vehículos, Servicios, Paquetes y Datos del taller
- `csv`, `file_picker` y `file_saver` para importar/exportar Servicios en CSV
- `flutter_lints` para lint estricto

## Cómo ejecutar

> Requiere tener Flutter 3.x instalado localmente.

### Dependencias

```bash
flutter pub get
```

### Web

```bash
flutter run -d chrome
```

### Android

```bash
flutter run -d android
```

### iOS

```bash
flutter run -d ios
```

### Análisis y pruebas

```bash
flutter analyze
flutter test
```

## Estructura de carpetas

```text
lib/
  core/
    config/          # constantes globales y configuración base
    router/          # configuración de go_router
    services/        # servicios transversales (inicialización Supabase)
    theme/           # tema, colores y espaciados
  shared/
    models/          # modelos compartidos de UI/navegación
    providers/       # estado de UI con Riverpod
    widgets/         # componentes reutilizables
  features/
    dashboard/
      presentation/
    clientes/
      presentation/
      domain/
      data/
    vehiculos/
      presentation/
      domain/
      data/
    proformas/
      presentation/
      domain/
      data/
    trabajos/
      presentation/
      domain/
      data/
    contabilidad/
      presentation/
      domain/
      data/
    configuracion/
      presentation/
      domain/
      data/
main.dart
```

## Decisiones de arquitectura

- **Riverpod**: se utiliza para manejar estado de UI simple (por ejemplo, colapso del sidebar) sin acoplar lógica a widgets.
- **go_router**: centraliza rutas y mantiene una navegación escalable para web, móvil y futuras rutas protegidas.
- **Modular por features**: cada módulo del taller está aislado por carpeta y preparado para evolucionar con capas `presentation`, `domain` y `data`.
- **Supabase conectado**: Clientes y Vehículos usan repositorios reales con `supabase_flutter`.

## Alcance implementado (Fase 1 + Fase 2)

- AppBar con branding simple.
- Sidebar colapsable en pantallas anchas.
- Drawer en móvil.
- Dashboard con KPIs mixtos (totales reales de clientes/vehículos + mocks de módulos pendientes).
- Módulo Clientes funcional: listado, búsqueda, alta, edición, detalle y eliminación.
- Módulo Vehículos funcional: listado, búsqueda, alta, edición, detalle y eliminación.
- Módulo Servicios funcional: listado, búsqueda/filtro, alta, edición, eliminación e importación/exportación CSV.
- Módulo Paquetes funcional: listado, detalle, alta, edición, eliminación y asociación dinámica de servicios.
- Módulo Datos del taller funcional: edición de nombre, dirección, teléfono, correo y logo del taller.
- Relación 1:N Cliente → Vehículos en detalle de cliente.
- Tema global claro con paleta rojo/negro, espaciados y estados interactivos.
- Componentes reutilizables: botones, cards, badges y tabla.

## Checklist de validación Fase 1 + Fase 2

- [x] Proyecto base Flutter preparado para Android, iOS y Web.
- [x] Dependencias agregadas: Riverpod, go_router y supabase_flutter.
- [x] Arquitectura modular por features con separación `presentation/domain/data`.
- [x] Layout principal con AppBar, menú lateral y contenido central.
- [x] Sidebar colapsable en web/tablet y Drawer en móvil.
- [x] Rutas configuradas para Dashboard, Clientes, Vehículos, Proformas, Trabajos, Contabilidad y Configuración.
- [x] Dashboard con KPI mock y widgets reutilizables.
- [x] Tema global centralizado y constantes reutilizables.
- [x] Conexión real a Supabase para Clientes y Vehículos.
- [x] README documentado en español.
- [x] CRUD de Clientes con validaciones y búsqueda.
- [x] CRUD de Vehículos con validaciones y selector de cliente.
- [x] Relación 1:N (un cliente con varios vehículos) visible en detalle de cliente.
- [x] Módulo de Servicios (CRUD + CSV de importación/exportación).
- [x] Módulo de Paquetes de servicios (CRUD + selección de servicios + precio dinámico/manual).
- [x] Módulo de Datos del taller (nombre, dirección, teléfono, correo y logo en Storage).
- [x] Navegación completa para crear/editar/ver detalle de clientes y vehículos.
- [x] KPIs de dashboard para totales reales desde repositorio de datos.

## Conexión a Supabase

Las tablas `clientes`, `vehiculos`, `servicios`, `paquetes_servicios`, `paquete_servicio_items` y `taller_info` deben crearse antes de usar la app con datos reales.

1. Entra a [supabase.com](https://supabase.com) y abre tu proyecto.
2. Ve a **SQL Editor**.
3. Abre el archivo `supabase/schema.sql` de este repositorio.
4. Copia/pega y ejecuta `supabase/schema.sql` para clientes/vehículos.
5. Luego copia/pega y ejecuta `supabase/schema_servicios.sql` para servicios/paquetes.
6. Luego copia/pega y ejecuta `supabase/schema_taller.sql` para datos generales del taller.
7. En **Storage** crea manualmente el bucket público `taller-logos`:
   - Storage → **New bucket**
   - Nombre: `taller-logos`
   - Activar **Public bucket**
   - Guardar
8. (Opcional recomendado) Revisa `supabase/storage_taller_logo.sql` para políticas SQL del bucket `taller-logos`.

> El script SQL se ejecuta manualmente desde Supabase (no desde esta app).

Las credenciales del proyecto (URL y anon key) ya están configuradas en:

- `lib/core/config/supabase_config.dart`

> Recomendación para producción: mover estas credenciales a `--dart-define` o `.env`.

La app inicializa Supabase en `main.dart` y los providers inyectan repositorios reales:

- `SupabaseClienteRepository`
- `SupabaseVehiculoRepository`
- `SupabaseServicioRepository`
- `SupabasePaqueteServicioRepository`
- `SupabaseTallerRepository`

## Checklist de fase de datos

- [x] Conexión real de Clientes a Supabase.
- [x] Conexión real de Vehículos a Supabase.
- [x] Conexión real de Servicios a Supabase.
- [x] Conexión real de Paquetes e Items de paquete a Supabase.
- [x] Conexión real de Datos del taller a Supabase + Storage para logos.
- [x] Relación 1:N Cliente → Vehículos persistida con FK en base de datos.
- [x] Relación N:N Paquetes ↔ Servicios persistida con tabla intermedia.
- [x] Script SQL con RLS y políticas básicas para fase sin autenticación.

## Importar/Exportar CSV de servicios

El módulo de Servicios permite:

- **Exportar CSV** con columnas: `nombre,descripcion,precio,categoria,activo`.
- **Importar CSV** con el mismo formato para crear/actualizar en lote.

Reglas del importador:

- `nombre` y `precio` son obligatorios.
- `precio` debe ser numérico y mayor a 0.
- `activo` acepta `true/false` (también `1/0`, `si/no`).
- Si una fila es inválida, se omite y se reporta en el resumen final.

## Siguiente fase recomendada

Implementar **Proformas** usando Servicios/Paquetes como base de cotización y aprovechar los datos de taller en plantillas/impresión:

- Crear módulo de Proformas con líneas por servicio/paquete y cálculo de totales/impuestos.
- Incluir nombre/logo/datos del taller en encabezado de proformas y documentos exportables.
- Definir flujo Proforma → Aprobación → Trabajo con estados y trazabilidad.
- Habilitar autenticación y endurecer políticas RLS por usuario/rol.
