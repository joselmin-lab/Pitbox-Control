-- Este script debe ejecutarse manualmente en el SQL Editor de tu proyecto Supabase.
-- No se ejecuta automáticamente desde esta app Flutter.
-- IMPORTANTE: Las políticas definidas aquí son permisivas para fase sin autenticación.
-- Antes de producción, reemplazarlas por políticas por usuario/rol con auth habilitada.

create extension if not exists pgcrypto;

create table if not exists servicios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  descripcion text,
  precio numeric(10,2) not null,
  categoria text,
  activo boolean not null default true,
  fecha_creacion timestamptz not null default now()
);

create table if not exists paquetes_servicios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  descripcion text,
  precio_manual numeric(10,2),
  activo boolean not null default true,
  fecha_creacion timestamptz not null default now()
);

create table if not exists paquete_servicio_items (
  id uuid primary key default gen_random_uuid(),
  paquete_id uuid not null references paquetes_servicios(id) on delete cascade,
  servicio_id uuid not null references servicios(id) on delete cascade,
  cantidad integer not null default 1,
  constraint paquete_servicio_unico unique (paquete_id, servicio_id)
);

alter table servicios enable row level security;
alter table paquetes_servicios enable row level security;
alter table paquete_servicio_items enable row level security;

drop policy if exists "Permitir lectura publica servicios" on servicios;
drop policy if exists "Permitir insercion publica servicios" on servicios;
drop policy if exists "Permitir actualizacion publica servicios" on servicios;
drop policy if exists "Permitir eliminacion publica servicios" on servicios;

create policy "Permitir lectura publica servicios" on servicios for select using (true);
create policy "Permitir insercion publica servicios" on servicios for insert with check (true);
create policy "Permitir actualizacion publica servicios" on servicios for update using (true);
create policy "Permitir eliminacion publica servicios" on servicios for delete using (true);

drop policy if exists "Permitir lectura publica paquetes" on paquetes_servicios;
drop policy if exists "Permitir insercion publica paquetes" on paquetes_servicios;
drop policy if exists "Permitir actualizacion publica paquetes" on paquetes_servicios;
drop policy if exists "Permitir eliminacion publica paquetes" on paquetes_servicios;

create policy "Permitir lectura publica paquetes" on paquetes_servicios for select using (true);
create policy "Permitir insercion publica paquetes" on paquetes_servicios for insert with check (true);
create policy "Permitir actualizacion publica paquetes" on paquetes_servicios for update using (true);
create policy "Permitir eliminacion publica paquetes" on paquetes_servicios for delete using (true);

drop policy if exists "Permitir lectura publica items" on paquete_servicio_items;
drop policy if exists "Permitir insercion publica items" on paquete_servicio_items;
drop policy if exists "Permitir actualizacion publica items" on paquete_servicio_items;
drop policy if exists "Permitir eliminacion publica items" on paquete_servicio_items;

create policy "Permitir lectura publica items" on paquete_servicio_items for select using (true);
create policy "Permitir insercion publica items" on paquete_servicio_items for insert with check (true);
create policy "Permitir actualizacion publica items" on paquete_servicio_items for update using (true);
create policy "Permitir eliminacion publica items" on paquete_servicio_items for delete using (true);
