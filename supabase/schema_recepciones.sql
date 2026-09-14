-- Este script debe ejecutarse manualmente en el SQL Editor de tu proyecto Supabase.
-- No se ejecuta automáticamente desde esta app Flutter.
-- IMPORTANTE: Las políticas definidas aquí son permisivas para fase sin autenticación.
-- Antes de producción, reemplazarlas por políticas por usuario/rol con auth habilitada.
-- Este script replica deliberadamente el esquema abierto de desarrollo usado por módulos
-- anteriores del proyecto. No debe usarse sin endurecer RLS cuando exista autenticación.
--
-- Storage requerido (crear manualmente en Supabase Dashboard, igual que `taller-logos`):
--   1. Bucket público `recepciones-fotos`
--   2. Bucket público `recepciones-firmas`
--
-- Pasos:
--   Storage -> New bucket -> Nombre -> activar "Public bucket" -> Guardar

create extension if not exists pgcrypto;

create table if not exists recepciones_vehiculo (
  id uuid primary key default gen_random_uuid(),
  numero text not null unique,
  cliente_id uuid not null references clientes(id) on delete restrict,
  vehiculo_id uuid not null references vehiculos(id) on delete restrict,
  fecha_ingreso timestamptz not null default now(),
  fecha_salida_estimada timestamptz,
  kilometraje text,
  ingreso_en_grua boolean not null default false,
  trabajo_a_realizar text,
  observaciones text,
  checklist_sistemas jsonb not null default '[]'::jsonb,
  inventario jsonb not null default '[]'::jsonb,
  nivel_combustible numeric(4,3) not null default 0,
  danos_preexistentes jsonb not null default '[]'::jsonb,
  fotografias jsonb not null default '[]'::jsonb,
  firma_prestador_url text,
  firma_cliente_url text,
  estado text not null default 'abierta' check (estado in ('abierta', 'vehiculo_entregado')),
  fecha_creacion timestamptz not null default now()
);

create table if not exists recepciones_contadores (
  anio integer primary key,
  ultimo_numero integer not null default 0
);

create or replace function generar_siguiente_numero_recepcion(anio_actual integer)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  siguiente integer;
  numero_formateado text;
begin
  if anio_actual is null then
    raise exception 'anio_actual no puede ser null';
  end if;

  insert into recepciones_contadores (anio, ultimo_numero)
  values (anio_actual, 1)
  on conflict (anio)
  do update set ultimo_numero = recepciones_contadores.ultimo_numero + 1
  returning ultimo_numero into siguiente;

  numero_formateado := lpad(siguiente::text, 3, '0') || '-' || anio_actual::text;
  return numero_formateado;
end;
$$;

revoke all on function generar_siguiente_numero_recepcion(integer) from public;
grant execute on function generar_siguiente_numero_recepcion(integer) to anon, authenticated, service_role;

alter table recepciones_vehiculo enable row level security;
alter table recepciones_contadores enable row level security;

drop policy if exists "Permitir lectura publica recepciones_vehiculo" on recepciones_vehiculo;
drop policy if exists "Permitir insercion publica recepciones_vehiculo" on recepciones_vehiculo;
drop policy if exists "Permitir actualizacion publica recepciones_vehiculo" on recepciones_vehiculo;

create policy "Permitir lectura publica recepciones_vehiculo" on recepciones_vehiculo for select using (true);
create policy "Permitir insercion publica recepciones_vehiculo" on recepciones_vehiculo for insert with check (true);
create policy "Permitir actualizacion publica recepciones_vehiculo" on recepciones_vehiculo for update using (true);
-- No se expone borrado público para recepciones.
-- Las políticas anteriores son sólo para desarrollo local/sin auth.

drop policy if exists "Permitir lectura publica recepciones_contadores" on recepciones_contadores;
drop policy if exists "Permitir insercion publica recepciones_contadores" on recepciones_contadores;
drop policy if exists "Permitir actualizacion publica recepciones_contadores" on recepciones_contadores;
drop policy if exists "Permitir eliminacion publica recepciones_contadores" on recepciones_contadores;

-- Sin políticas públicas en `recepciones_contadores`:
-- su acceso se realiza únicamente mediante la función
-- `generar_siguiente_numero_recepcion` (security definer).
