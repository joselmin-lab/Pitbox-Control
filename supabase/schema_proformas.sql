-- Este script debe ejecutarse manualmente en el SQL Editor de tu proyecto Supabase.
-- No se ejecuta automáticamente desde esta app Flutter.
-- IMPORTANTE: Las políticas definidas aquí son permisivas para fase sin autenticación.
-- Antes de producción, reemplazarlas por políticas por usuario/rol con auth habilitada.

create extension if not exists pgcrypto;

create table if not exists proformas (
  id uuid primary key default gen_random_uuid(),
  numero text not null unique,
  cliente_id uuid not null references clientes(id) on delete restrict,
  vehiculo_id uuid not null references vehiculos(id) on delete restrict,
  fecha date not null default current_date,
  condiciones_pago text,
  validez text,
  tiempo_entrega text,
  tiempo_garantia text,
  forma_pago text,
  estado text not null default 'borrador' check (estado in ('borrador', 'emitida', 'aceptada', 'rechazada')),
  total numeric(12,2) not null default 0,
  fecha_creacion timestamptz not null default now()
);

create table if not exists proforma_items (
  id uuid primary key default gen_random_uuid(),
  proforma_id uuid not null references proformas(id) on delete cascade,
  tipo_item text not null check (tipo_item in ('servicio', 'paquete', 'repuesto_insumo')),
  referencia_id uuid,
  descripcion text not null,
  cantidad numeric(12,2) not null default 1,
  precio_unitario numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0
);

create table if not exists proforma_contadores (
  anio integer primary key,
  ultimo_numero integer not null default 0
);

create or replace function generar_siguiente_numero_proforma(anio_actual integer)
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

  insert into proforma_contadores (anio, ultimo_numero)
  values (anio_actual, 1)
  on conflict (anio)
  do update set ultimo_numero = proforma_contadores.ultimo_numero + 1
  returning ultimo_numero into siguiente;

  numero_formateado := lpad(siguiente::text, 3, '0') || '-' || anio_actual::text;
  return numero_formateado;
end;
$$;

create or replace function reemplazar_items_proforma(
  p_proforma_id uuid,
  p_items jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from proforma_items
  where proforma_id = p_proforma_id;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    return;
  end if;

  insert into proforma_items (
    proforma_id,
    tipo_item,
    referencia_id,
    descripcion,
    cantidad,
    precio_unitario,
    total
  )
  select
    p_proforma_id,
    coalesce(item->>'tipo_item', 'repuesto_insumo'),
    nullif(item->>'referencia_id', '')::uuid,
    coalesce(item->>'descripcion', ''),
    coalesce((item->>'cantidad')::numeric, 1),
    coalesce((item->>'precio_unitario')::numeric, 0),
    coalesce((item->>'total')::numeric, 0)
  from jsonb_array_elements(p_items) as item;
end;
$$;

revoke all on function generar_siguiente_numero_proforma(integer) from public;
grant execute on function generar_siguiente_numero_proforma(integer) to anon, authenticated, service_role;

revoke all on function reemplazar_items_proforma(uuid, jsonb) from public;
grant execute on function reemplazar_items_proforma(uuid, jsonb) to anon, authenticated, service_role;

alter table proformas enable row level security;
alter table proforma_items enable row level security;
alter table proforma_contadores enable row level security;

drop policy if exists "Permitir lectura publica proformas" on proformas;
drop policy if exists "Permitir insercion publica proformas" on proformas;
drop policy if exists "Permitir actualizacion publica proformas" on proformas;
drop policy if exists "Permitir eliminacion publica proformas" on proformas;

create policy "Permitir lectura publica proformas" on proformas for select using (true);
create policy "Permitir insercion publica proformas" on proformas for insert with check (true);
create policy "Permitir actualizacion publica proformas" on proformas for update using (true);
create policy "Permitir eliminacion publica proformas" on proformas for delete using (true);

drop policy if exists "Permitir lectura publica proforma_items" on proforma_items;
drop policy if exists "Permitir insercion publica proforma_items" on proforma_items;
drop policy if exists "Permitir actualizacion publica proforma_items" on proforma_items;
drop policy if exists "Permitir eliminacion publica proforma_items" on proforma_items;

create policy "Permitir lectura publica proforma_items" on proforma_items for select using (true);
create policy "Permitir insercion publica proforma_items" on proforma_items for insert with check (true);
create policy "Permitir actualizacion publica proforma_items" on proforma_items for update using (true);
create policy "Permitir eliminacion publica proforma_items" on proforma_items for delete using (true);

drop policy if exists "Permitir lectura publica proforma_contadores" on proforma_contadores;
drop policy if exists "Permitir insercion publica proforma_contadores" on proforma_contadores;
drop policy if exists "Permitir actualizacion publica proforma_contadores" on proforma_contadores;
drop policy if exists "Permitir eliminacion publica proforma_contadores" on proforma_contadores;

-- Sin políticas públicas en `proforma_contadores`:
-- su acceso se realiza únicamente mediante la función
-- `generar_siguiente_numero_proforma` (security definer).
