# Pitbox Control

Pitbox Control es una app multiplataforma para la gestión de talleres mecánicos. Esta **Fase 1** entrega una base de interfaz en Flutter con navegación modular, dashboard inicial y preparación para integrar Supabase en fases posteriores.

## Stack técnico

- Flutter 3.x / Dart con null safety
- `flutter_riverpod` para estado de UI desacoplado
- `go_router` para navegación declarativa
- `supabase_flutter` agregado como preparación para backend futuro
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
    services/        # servicios transversales (scaffold Supabase)
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
- **Supabase preparado**: se agregó `supabase_flutter` y se dejó un scaffold seguro con placeholders para URL y anon key, sin conexión real en esta fase.

## Alcance de la Fase 1

- AppBar con branding simple.
- Sidebar colapsable en pantallas anchas.
- Drawer en móvil.
- Dashboard inicial con KPI mock estáticos.
- Placeholders por módulo con estilo consistente.
- Tema global claro con paleta rojo/negro, espaciados y estados interactivos.
- Componentes reutilizables: botones, cards, badges y tabla.

## Checklist de validación Fase 1

- [x] Proyecto base Flutter preparado para Android, iOS y Web.
- [x] Dependencias agregadas: Riverpod, go_router y supabase_flutter.
- [x] Arquitectura modular por features con separación `presentation/domain/data`.
- [x] Layout principal con AppBar, menú lateral y contenido central.
- [x] Sidebar colapsable en web/tablet y Drawer en móvil.
- [x] Rutas configuradas para Dashboard, Clientes, Vehículos, Proformas, Trabajos, Contabilidad y Configuración.
- [x] Dashboard con KPI mock y widgets reutilizables.
- [x] Tema global centralizado y constantes reutilizables.
- [x] Scaffolding de Supabase sin credenciales reales.
- [x] README documentado en español.

## Siguiente fase recomendada

Implementar **Clientes + Vehículos** con relación **1:N**. Esto implicará:

- Modelos de dominio (`Cliente`, `Vehiculo`) y validaciones.
- Repositorios y fuentes de datos con Supabase.
- Formularios de alta/edición.
- Listados filtrables y navegación entre cliente y sus vehículos.
- Primera relación real entre módulos con estructura lista para crecer.
