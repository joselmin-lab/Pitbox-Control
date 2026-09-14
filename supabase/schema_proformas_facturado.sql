-- Este script debe ejecutarse manualmente en el SQL Editor de tu proyecto Supabase.
-- No se ejecuta automáticamente desde esta app Flutter.
-- IMPORTANTE: Ejecuta antes `schema_proformas.sql`. Este script extiende proformas con
-- facturado/no facturado y mantiene subtotal/descuento/total histórico.

alter table proformas
  add column if not exists facturado boolean not null default true;

alter table proformas
  add column if not exists subtotal numeric(12,2) not null default 0;

alter table proformas
  add column if not exists descuento_no_facturado numeric(12,2) not null default 0;

update proformas
set subtotal = coalesce(total, 0)
where subtotal is null or subtotal = 0;

update proformas
set descuento_no_facturado = 0
where descuento_no_facturado is null;

drop function if exists actualizar_proforma_con_items(
  uuid, uuid, uuid, date, text, text, text, text, text, text, numeric, jsonb
);

create or replace function actualizar_proforma_con_items(
  p_id uuid,
  p_cliente_id uuid,
  p_vehiculo_id uuid,
  p_fecha date,
  p_condiciones_pago text,
  p_validez text,
  p_tiempo_entrega text,
  p_tiempo_garantia text,
  p_forma_pago text,
  p_estado text,
  p_facturado boolean,
  p_subtotal numeric,
  p_descuento_no_facturado numeric,
  p_total numeric,
  p_items jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update proformas
  set
    cliente_id = p_cliente_id,
    vehiculo_id = p_vehiculo_id,
    fecha = p_fecha,
    condiciones_pago = p_condiciones_pago,
    validez = p_validez,
    tiempo_entrega = p_tiempo_entrega,
    tiempo_garantia = p_tiempo_garantia,
    forma_pago = p_forma_pago,
    estado = p_estado,
    facturado = coalesce(p_facturado, true),
    subtotal = coalesce(p_subtotal, 0),
    descuento_no_facturado = coalesce(p_descuento_no_facturado, 0),
    total = coalesce(p_total, 0)
  where id = p_id;

  if not found then
    raise exception 'Proforma no encontrada: %', p_id;
  end if;

  perform reemplazar_items_proforma(p_id, p_items);
end;
$$;

revoke all on function actualizar_proforma_con_items(
  uuid, uuid, uuid, date, text, text, text, text, text, text, boolean, numeric, numeric, numeric, jsonb
) from public;

grant execute on function actualizar_proforma_con_items(
  uuid, uuid, uuid, date, text, text, text, text, text, text, boolean, numeric, numeric, numeric, jsonb
) to anon, authenticated, service_role;
