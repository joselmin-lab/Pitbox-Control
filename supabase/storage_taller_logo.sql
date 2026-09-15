-- 1) Crea manualmente el bucket en Supabase Dashboard:
--    Storage -> New bucket -> Nombre: taller-logos -> Public bucket
--
-- 2) Ejecuta este script en SQL Editor para permitir subir logos desde la app web.
--    Incluye lectura pública e inserción/actualización/eliminación para roles anon y authenticated.

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
  and name like 'logo\\_%' escape '\\'
);

create policy "Permitir actualizacion logos taller app"
on storage.objects for update to anon, authenticated
using (
  bucket_id = 'taller-logos'
  and name like 'logo\\_%' escape '\\'
)
with check (
  bucket_id = 'taller-logos'
  and name like 'logo\\_%' escape '\\'
);

create policy "Permitir eliminacion logos taller app"
on storage.objects for delete to anon, authenticated
using (
  bucket_id = 'taller-logos'
  and name like 'logo\\_%' escape '\\'
);
