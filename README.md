# Pitbox Control

Pitbox Control es una app multiplataforma para la gestión de talleres mecánicos. Esta versión incluye **Fase 1 + Fase 2**: base de interfaz modular y módulos funcionales de **Clientes** y **Vehículos** con relación **1:N**.

## Stack técnico

- Flutter 3.x / Dart con null safety
- `flutter_riverpod` para estado de UI desacoplado
- `go_router` para navegación declarativa
- `supabase_flutter` para backend real de Clientes y Vehículos
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
- [x] Navegación completa para crear/editar/ver detalle de clientes y vehículos.
- [x] KPIs de dashboard para totales reales desde repositorio de datos.

## Conexión a Supabase

Las tablas `clientes` y `vehiculos` deben crearse antes de usar la app con datos reales.

1. Entra a [supabase.com](https://supabase.com) y abre tu proyecto.
2. Ve a **SQL Editor**.
3. Abre el archivo `supabase/schema.sql` de este repositorio.
4. Copia/pega su contenido y ejecútalo en el SQL Editor.

> El script SQL se ejecuta manualmente desde Supabase (no desde esta app).

Las credenciales del proyecto (URL y anon key) ya están configuradas en:

- `lib/core/config/supabase_config.dart`

> Recomendación para producción: mover estas credenciales a `--dart-define` o `.env`.

La app inicializa Supabase en `main.dart` y los providers inyectan repositorios reales:

- `SupabaseClienteRepository`
- `SupabaseVehiculoRepository`

## Checklist de fase de datos

- [x] Conexión real de Clientes a Supabase.
- [x] Conexión real de Vehículos a Supabase.
- [x] Relación 1:N Cliente → Vehículos persistida con FK en base de datos.
- [x] Script SQL con RLS y políticas básicas para fase sin autenticación.

## Siguiente fase recomendada

Implementar **Proformas + Trabajos** sobre Supabase y agregar autenticación/roles:

- Crear tablas y repositorios Supabase para Proformas y Trabajos desde el inicio.
- Definir flujo operativo Proforma → Trabajo con estados y trazabilidad.
- Habilitar autenticación y endurecer políticas RLS por usuario/rol.
