# Pitbox Control

Pitbox Control es una app multiplataforma para la gestión de talleres mecánicos. Esta versión incluye **Fase 1 + Fase 2** y la primera fase operativa de **Trabajos**: base de interfaz modular y módulos funcionales de **Clientes**, **Vehículos**, **Servicios**, **Paquetes de servicios**, **Datos del taller**, **Proformas**, **Impuestos** y **Recepción de vehículos** con relación **1:N** (clientes/vehículos) y **N:N** (paquetes/servicios).

## Stack técnico

- Flutter 3.x / Dart con null safety
- `flutter_riverpod` para estado de UI desacoplado
- `go_router` para navegación declarativa
- `supabase_flutter` para backend real de Clientes, Vehículos, Servicios, Paquetes, Datos del taller y Proformas
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
- Módulo Proformas funcional: listado, creación/edición, vista previa estilo documento y exportación PDF.
- Módulo Impuestos funcional: configuración de porcentajes IVA e IT.
- Proformas con tipo Facturado/No facturado y descuento automático por IVA+IT.
- Bloqueo de creación de proformas nuevas cuando faltan datos del taller.
- Módulo Recepción de vehículos funcional: listado, formulario, detalle tipo documento, fotos, daños, inventario, firmas digitales y exportación PDF.
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
- [x] Módulo de Proformas (numeración anual, ítems y exportación PDF).
- [x] Configuración de Impuestos (IVA e IT) conectada a Supabase.
- [x] Proformas Facturado/No facturado con desglose de subtotal, descuento y total final.
- [x] Validación de Datos del Taller antes de crear nuevas proformas.
- [x] Módulo de Recepción de Vehículos con numeración anual, checklist, inventario, daños, fotos y firmas.
- [x] Navegación completa para crear/editar/ver detalle de clientes y vehículos.
- [x] KPIs de dashboard para totales reales desde repositorio de datos.

## Conexión a Supabase

Las tablas `clientes`, `vehiculos`, `servicios`, `paquetes_servicios`, `paquete_servicio_items`, `taller_info`, `configuracion_impuestos`, `proformas`, `proforma_items`, `proforma_contadores`, `recepciones_vehiculo` y `recepciones_contadores` deben crearse antes de usar la app con datos reales.

1. Entra a [supabase.com](https://supabase.com) y abre tu proyecto.
2. Ve a **SQL Editor**.
3. Abre el archivo `supabase/schema.sql` de este repositorio.
4. Copia/pega y ejecuta `supabase/schema.sql` para clientes/vehículos.
5. Luego copia/pega y ejecuta `supabase/schema_servicios.sql` para servicios/paquetes.
6. Luego copia/pega y ejecuta `supabase/schema_taller.sql` para datos generales del taller.
7. Luego copia/pega y ejecuta `supabase/schema_proformas.sql` para proformas e ítems.
8. Luego copia/pega y ejecuta `supabase/schema_impuestos.sql` para la configuración de IVA/IT.
9. Luego copia/pega y ejecuta `supabase/schema_proformas_facturado.sql` para extender proformas con facturado, subtotal, descuento y total histórico.
10. Luego copia/pega y ejecuta `supabase/schema_recepciones.sql` para Recepción de Vehículos y su numeración consecutiva independiente.
11. En **Storage** crea manualmente el bucket público `taller-logos`:
   - Storage → **New bucket**
   - Nombre: `taller-logos`
   - Activar **Public bucket**
   - Guardar
12. En **Storage** crea manualmente el bucket público `recepciones-fotos`:
   - Storage → **New bucket**
   - Nombre: `recepciones-fotos`
   - Activar **Public bucket**
   - Guardar
13. En **Storage** crea manualmente el bucket público `recepciones-firmas`:
   - Storage → **New bucket**
   - Nombre: `recepciones-firmas`
   - Activar **Public bucket**
   - Guardar
14. (Opcional recomendado) Revisa `supabase/storage_taller_logo.sql` para políticas SQL del bucket `taller-logos`.

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
- `SupabaseImpuestosRepository`
- `SupabaseProformaRepository`
- `SupabaseRecepcionRepository`

### Numeración de proformas por año

El script `supabase/schema_proformas.sql` crea la función SQL `generar_siguiente_numero_proforma(anio_actual integer)`.

- Usa `upsert` atómico sobre `proforma_contadores` para incrementar el consecutivo sin colisiones.
- Devuelve el formato `XXX-YYYY` (ej. `001-2026`) y reinicia por cada año.
- `proforma_contadores` no tiene políticas públicas de escritura: el acceso ocurre mediante la función SQL.

### Facturado / No facturado y descuento por IVA+IT

- En el formulario se puede elegir entre **Facturado** y **No facturado**.
- Si está en **No facturado**, se aplica descuento: `descuento = subtotal * (IVA + IT) / 100`.
- El resumen muestra `Subtotal`, `Descuento por no facturar` y `Total final` en formulario, detalle y PDF.
- Para mantener consistencia histórica, `proformas` persiste `facturado`, `subtotal`, `descuento_no_facturado` y `total`.
- Para crear una proforma nueva se exige tener Datos del Taller configurados con `nombre` y al menos `telefono` o `correo`.

### Numeración de recepciones por año

El script `supabase/schema_recepciones.sql` crea la función SQL `generar_siguiente_numero_recepcion(anio_actual integer)`.

- Usa `upsert` atómico sobre `recepciones_contadores` para incrementar el consecutivo sin colisiones.
- Devuelve el formato `XXX-YYYY` (ej. `001-2026`) y reinicia por cada año.
- Es independiente de la numeración de proformas.

### Recepción de vehículos

- La recepción reutiliza el patrón Cliente → Vehículo ya usado en Proformas.
- Permite registrar trabajo solicitado, observaciones libres, checklist de sistemas, inventario, combustible y daños preexistentes por vista.
- Soporta carga de fotografías del vehículo en el bucket público `recepciones-fotos`.
- Captura firma digital del prestador y del cliente y almacena las imágenes en el bucket público `recepciones-firmas`.
- El formulario exige ambas firmas para guardar la recepción.
- La vista de detalle y la exportación PDF muestran el logo configurado en Datos del Taller.

## Checklist de fase de datos

- [x] Conexión real de Clientes a Supabase.
- [x] Conexión real de Vehículos a Supabase.
- [x] Conexión real de Servicios a Supabase.
- [x] Conexión real de Paquetes e Items de paquete a Supabase.
- [x] Conexión real de Datos del taller a Supabase + Storage para logos.
- [x] Conexión real de Configuración de Impuestos (IVA/IT) a Supabase.
- [x] Conexión real de Proformas e Items a Supabase (incluye numeración anual atómica).
- [x] Conexión real de Recepción de Vehículos a Supabase + Storage para fotos y firmas.
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

Robustecer **Trabajos** a partir de las recepciones y conectar el flujo operativo completo:

- Crear flujo Recepción → Orden de trabajo → Entrega del vehículo.
- Vincular avance técnico, repuestos reales usados y mano de obra ejecutada con cada recepción.
- Consolidar trazabilidad histórica por impuesto si se requiere auditoría separada IVA vs IT por proforma.
- Conectar Trabajos con Contabilidad para registrar ingresos/costos reales.
- Habilitar autenticación y endurecer políticas RLS por usuario/rol.
