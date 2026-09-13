-- Este script debe ejecutarse manualmente en el SQL Editor de tu proyecto Supabase.
-- No se ejecuta automáticamente desde esta app Flutter.
-- IMPORTANTE: Las políticas definidas aquí son permisivas para fase sin autenticación.
-- Antes de producción, reemplazarlas por políticas por usuario/rol con auth habilitada.
-- Además, crea manualmente el bucket público `taller-logos` en Storage (ver storage_taller_logo.sql).

create extension if not exists pgcrypto;

create table if not exists taller_info (
  id uuid primary key default '00000000-0000-0000-0000-000000000001',
  nombre text not null,
  direccion text,
  telefono text,
  correo text,
  logo_url text,
  fecha_actualizacion timestamptz not null default now(),
  constraint taller_info_singleton check (id = '00000000-0000-0000-0000-000000000001')
);

alter table taller_info alter column id set default '00000000-0000-0000-0000-000000000001';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'taller_info_singleton'
  ) then
    alter table taller_info
      add constraint taller_info_singleton
      check (id = '00000000-0000-0000-0000-000000000001');
  end if;
end $$;

alter table taller_info enable row level security;

drop policy if exists "Permitir lectura publica taller_info" on taller_info;
drop policy if exists "Permitir insercion publica taller_info" on taller_info;
drop policy if exists "Permitir actualizacion publica taller_info" on taller_info;

create policy "Permitir lectura publica taller_info" on taller_info for select using (true);
create policy "Permitir insercion publica taller_info" on taller_info
  for insert
  with check (id = '00000000-0000-0000-0000-000000000001');
create policy "Permitir actualizacion publica taller_info" on taller_info
  for update
  using (id = '00000000-0000-0000-0000-000000000001')
  with check (id = '00000000-0000-0000-0000-000000000001');
