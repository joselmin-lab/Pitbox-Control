-- Este script debe ejecutarse manualmente en el SQL Editor de tu proyecto Supabase.
-- No se ejecuta automáticamente desde esta app Flutter.
-- IMPORTANTE: Las políticas definidas aquí son permisivas para fase sin autenticación.
-- Antes de producción, reemplazarlas por políticas por usuario/rol con auth habilitada.

create table if not exists configuracion_impuestos (
  id uuid primary key default '00000000-0000-0000-0000-000000000002',
  porcentaje_iva numeric not null default 13.0,
  porcentaje_it numeric not null default 3.0,
  fecha_actualizacion timestamptz not null default now(),
  constraint configuracion_impuestos_singleton_id
    check (id = '00000000-0000-0000-0000-000000000002')
);

insert into configuracion_impuestos (id, porcentaje_iva, porcentaje_it)
values ('00000000-0000-0000-0000-000000000002', 13.0, 3.0)
on conflict (id) do nothing;

alter table configuracion_impuestos enable row level security;

drop policy if exists "Permitir lectura publica configuracion_impuestos" on configuracion_impuestos;
drop policy if exists "Permitir insercion publica configuracion_impuestos" on configuracion_impuestos;
drop policy if exists "Permitir actualizacion publica configuracion_impuestos" on configuracion_impuestos;

create policy "Permitir lectura publica configuracion_impuestos"
on configuracion_impuestos for select
using (true);

create policy "Permitir insercion publica configuracion_impuestos"
on configuracion_impuestos for insert
with check (
  id = '00000000-0000-0000-0000-000000000002'
  and porcentaje_iva between 0 and 100
  and porcentaje_it between 0 and 100
);

create policy "Permitir actualizacion publica configuracion_impuestos"
on configuracion_impuestos for update
using (id = '00000000-0000-0000-0000-000000000002')
with check (
  id = '00000000-0000-0000-0000-000000000002'
  and porcentaje_iva between 0 and 100
  and porcentaje_it between 0 and 100
);
