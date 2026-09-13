-- Este script debe ejecutarse manualmente en el SQL Editor de tu proyecto Supabase.
-- No se ejecuta automáticamente desde esta app Flutter.
-- IMPORTANTE: Las políticas definidas aquí son permisivas para fase sin autenticación.
-- Antes de producción, reemplazarlas por políticas por usuario/rol con auth habilitada.
-- Además, crea manualmente el bucket público `taller-logos` en Storage (ver storage_taller_logo.sql).

create extension if not exists pgcrypto;

create table if not exists taller_info (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  direccion text,
  telefono text,
  correo text,
  logo_url text,
  fecha_actualizacion timestamptz not null default now()
);

alter table taller_info enable row level security;

drop policy if exists "Permitir lectura publica taller_info" on taller_info;
drop policy if exists "Permitir insercion publica taller_info" on taller_info;
drop policy if exists "Permitir actualizacion publica taller_info" on taller_info;

create policy "Permitir lectura publica taller_info" on taller_info for select using (true);
create policy "Permitir insercion publica taller_info" on taller_info for insert with check (true);
create policy "Permitir actualizacion publica taller_info" on taller_info for update using (true);
