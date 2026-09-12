-- Este script debe ejecutarse manualmente en el SQL Editor de tu proyecto Supabase.
-- No se ejecuta automáticamente desde esta app Flutter.

create extension if not exists pgcrypto;

create table if not exists clientes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  apellido text not null,
  telefono text not null,
  email text,
  direccion text,
  fecha_registro timestamptz not null default now()
);

create table if not exists vehiculos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references clientes(id) on delete cascade,
  placa text not null,
  marca text not null,
  modelo text not null,
  anio integer not null,
  color text,
  kilometraje integer,
  fecha_registro timestamptz not null default now()
);

alter table clientes enable row level security;
alter table vehiculos enable row level security;

drop policy if exists "Permitir lectura publica clientes" on clientes;
drop policy if exists "Permitir insercion publica clientes" on clientes;
drop policy if exists "Permitir actualizacion publica clientes" on clientes;
drop policy if exists "Permitir eliminacion publica clientes" on clientes;

create policy "Permitir lectura publica clientes" on clientes for select using (true);
create policy "Permitir insercion publica clientes" on clientes for insert with check (true);
create policy "Permitir actualizacion publica clientes" on clientes for update using (true);
create policy "Permitir eliminacion publica clientes" on clientes for delete using (true);

drop policy if exists "Permitir lectura publica vehiculos" on vehiculos;
drop policy if exists "Permitir insercion publica vehiculos" on vehiculos;
drop policy if exists "Permitir actualizacion publica vehiculos" on vehiculos;
drop policy if exists "Permitir eliminacion publica vehiculos" on vehiculos;

create policy "Permitir lectura publica vehiculos" on vehiculos for select using (true);
create policy "Permitir insercion publica vehiculos" on vehiculos for insert with check (true);
create policy "Permitir actualizacion publica vehiculos" on vehiculos for update using (true);
create policy "Permitir eliminacion publica vehiculos" on vehiculos for delete using (true);

-- Inserts opcionales de ejemplo:
-- insert into clientes (id, nombre, apellido, telefono, email, direccion, fecha_registro) values
-- ('6fc5b8f9-1f2f-48f1-aa0e-c44da31f903d', 'Ana', 'Rojas', '70012345', 'ana.rojas@gmail.com', 'Av. Blanco Galindo #123', '2026-01-10T00:00:00Z'),
-- ('8103007a-07c5-4d42-aa5e-e39693fd4d7b', 'Carlos', 'Pérez', '72123456', 'carlos.perez@hotmail.com', 'Zona Norte, Calle 7', '2026-02-18T00:00:00Z'),
-- ('42ed73f6-fc47-4adf-8903-ffcf03cb9e0d', 'María', 'López', '73456789', 'maria.lopez@gmail.com', 'Av. América km 4', '2026-03-04T00:00:00Z'),
-- ('5809df64-a79d-4a16-872b-6fca8d69ce5f', 'José', 'Quispe', '71234567', null, 'Pacata Alta, lote 21', '2026-05-30T00:00:00Z');
--
-- insert into vehiculos (id, cliente_id, placa, marca, modelo, anio, color, kilometraje, fecha_registro) values
-- ('2a4f0a15-693a-4388-8b13-a7dcf6dcf4a0', '6fc5b8f9-1f2f-48f1-aa0e-c44da31f903d', '2874-LSC', 'Toyota', 'Corolla', 2018, 'Plata', 64300, '2026-01-10T00:00:00Z'),
-- ('bce63ee6-eedc-4a6c-90ee-46f36914f0d4', '6fc5b8f9-1f2f-48f1-aa0e-c44da31f903d', '4912-KGA', 'Kia', 'Rio', 2020, 'Rojo', 48200, '2026-01-18T00:00:00Z'),
-- ('be9fdcd1-3ec8-4f78-aa39-af8bfc652530', '8103007a-07c5-4d42-aa5e-e39693fd4d7b', '3920-UYR', 'Nissan', 'Sentra', 2017, 'Blanco', 90350, '2026-02-19T00:00:00Z'),
-- ('f4544b7c-3439-49c2-9db3-28ef89f0db2f', '42ed73f6-fc47-4adf-8903-ffcf03cb9e0d', '6165-HZO', 'Suzuki', 'Vitara', 2021, 'Negro', 27800, '2026-03-04T00:00:00Z'),
-- ('95d8b75a-4ec2-440b-bfb8-2a4ceb11ea3e', '5809df64-a79d-4a16-872b-6fca8d69ce5f', '8451-BNP', 'Hyundai', 'Accent', 2016, null, 112000, '2026-06-01T00:00:00Z');
