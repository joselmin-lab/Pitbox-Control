-- 1) Crea manualmente el bucket en Supabase Dashboard:
--    Storage -> New bucket -> Nombre: taller-logos -> Public bucket
--
-- 2) Ejecuta este script en SQL Editor para permitir subir logos desde la app web.
--    Incluye lectura pública e inserción/actualización/eliminación para roles anon y authenticated.
--
-- IMPORTANTE (fix): las versiones anteriores de este script usaban
--   name like 'logo\\_%' escape '\\'
-- lo cual es incorrecto: en PostgreSQL (con standard_conforming_strings = on,
-- que es el valor por defecto desde hace muchas versiones) los literales de
-- cadena '...' NO procesan las barras invertidas como escapes. Por lo tanto
-- '\\' se interpreta como DOS caracteres de barra invertida literales, y la
-- cláusula ESCAPE exige que el carácter de escape tenga exactamente UN
-- carácter. Esto provocaba el error de Postgres:
--   22025 invalid_escape_sequence
-- en cada intento de INSERT/UPDATE sobre storage.objects, es decir, en cada
-- subida de logo.
--
-- Además, el nombre de archivo generado por la app ahora usa guiones ("-")
-- en vez de guiones bajos ("_") como separador (ver
-- supabase_taller_repository.dart), por lo que ya no es necesario usar LIKE
-- con guion bajo ni cláusula ESCAPE en absoluto: basta con verificar el
-- prefijo "logo-".

drop policy if exists "Permitir lectura publica logos taller" on storage.objects;
drop policy if exists "Permitir insercion logos taller app" on storage.objects;
drop policy if exists "Permitir actualizacion logos taller app" on storage.objects;
drop policy if exists "Permitir eliminacion logos taller app" on storage.objects;

create policy "Permitir lectura publica logos taller"
on storage.objects for select
using (bucket_id = 'taller-logos');

create policy "Permitir insercion logos taller app"
on storage.objects for insert to anon, authenticated
with check (
  bucket_id = 'taller-logos'
  and name like 'logo-%'
);

create policy "Permitir actualizacion logos taller app"
on storage.objects for update to anon, authenticated
using (
  bucket_id = 'taller-logos'
  and name like 'logo-%'
)
with check (
  bucket_id = 'taller-logos'
  and name like 'logo-%'
);

create policy "Permitir eliminacion logos taller app"
on storage.objects for delete to anon, authenticated
using (
  bucket_id = 'taller-logos'
  and name like 'logo-%'
);
