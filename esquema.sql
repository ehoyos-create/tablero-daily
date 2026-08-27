-- ═══════════════════════════════════════════════════════════════════════════
-- Tablero Daily · esquema completo
--
-- Se pega entero en el editor SQL de Supabase y se corre una sola vez.
-- Crea las dos tablas, sus disparadores, sus índices, sus políticas y el bucket
-- de imágenes de las notas.
-- ═══════════════════════════════════════════════════════════════════════════

-- ───────────────────────────── las tareas ─────────────────────────────
create table if not exists public.daily_tareas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  resultado_esperado text default ''::text,
  persona text default ''::text,          -- varios responsables, separados por coma
  talla text default ''::text,
  para_que text default ''::text,
  fecha date,                             -- fecha límite
  fecha_inicio date,
  estado text not null default 'Por hacer'::text,
  orden double precision default 0,       -- una sola prioridad para Board y Timeline
  progreso smallint not null default 0,
  notas text default ''::text,            -- HTML saneado por el editor
  piedra text,                            -- a qué objetivos empuja, separados por coma
  bloqueado boolean not null default false,
  bloqueo_motivo text,
  bloqueo_tarea uuid,
  archivada boolean not null default false,
  completada_en timestamptz,
  creado timestamptz not null default now(),
  actualizado timestamptz not null default now(),

  -- SMART vive en Postgres, no en el navegador. Es una columna generada, así
  -- que la regla está en un solo sitio y ninguna app puede saltársela.
  smart boolean generated always as (
    coalesce(nullif(btrim(nombre),''), null) is not null
    and coalesce(nullif(btrim(resultado_esperado),''), null) is not null
    and coalesce(nullif(btrim(persona),''), null) is not null
    and coalesce(nullif(btrim(talla),''), null) is not null
    and coalesce(nullif(btrim(para_que),''), null) is not null
    and fecha is not null
  ) stored
);

create index if not exists daily_tareas_estado_idx    on public.daily_tareas (estado, orden);
create index if not exists daily_tareas_fecha_idx     on public.daily_tareas (fecha);
create index if not exists daily_tareas_archivada_idx on public.daily_tareas (archivada);
create index if not exists daily_tareas_rango_idx     on public.daily_tareas (fecha_inicio, fecha);
create index if not exists daily_tareas_bloqueadas    on public.daily_tareas (bloqueado) where bloqueado;

-- ───────────────────────────── el pulso ─────────────────────────────
-- Una fila por semana, persona y métrica. La semana se guarda siempre por su
-- lunes, para que no existan dos claves distintas para la misma semana.
create table if not exists public.daily_pulso (
  id uuid primary key default gen_random_uuid(),
  semana date not null,
  persona text not null,
  metrica text not null,
  valor smallint not null default 0,
  creado timestamptz not null default now(),
  actualizado timestamptz not null default now(),
  unique (semana, persona, metrica)
);
create index if not exists daily_pulso_semana on public.daily_pulso (semana desc);

-- ───────────────────────────── los disparadores ─────────────────────────────
-- `creado` es el sello de nacimiento de la tarea y no se puede mover, ni
-- mandando otro valor desde el navegador. Por eso la antigüedad es comparable.
-- `completada_en` lo pone la base cuando la tarea entra a `Lista`: es lo que
-- permite deducir el esfuerzo sin pedirle a nadie que cronometre.
create or replace function public.daily_tareas_touch()
returns trigger language plpgsql security definer set search_path to '' as $$
begin
  new.actualizado = now();
  if TG_OP = 'INSERT' then
    new.creado = now();
    if new.estado = 'Lista' then new.completada_en = now();
    else new.completada_en = null; end if;
  else
    new.creado = old.creado;
    if new.estado = 'Lista' and old.estado <> 'Lista' then new.completada_en = now();
    elsif new.estado <> 'Lista' then new.completada_en = null; end if;
  end if;
  return new;
end; $$;

-- Una barra del Timeline no puede terminar antes de empezar.
create or replace function public.daily_tareas_rango()
returns trigger language plpgsql security definer set search_path to '' as $$
begin
  if new.fecha_inicio is not null and new.fecha is not null and new.fecha_inicio > new.fecha then
    new.fecha_inicio := new.fecha;
  end if;
  return new;
end; $$;

create or replace function public.daily_pulso_touch()
returns trigger language plpgsql security definer set search_path to '' as $$
begin
  new.actualizado = now();
  new.creado = old.creado;
  return new;
end; $$;

drop trigger if exists daily_tareas_touch_trg on public.daily_tareas;
create trigger daily_tareas_touch_trg before insert or update on public.daily_tareas
  for each row execute function public.daily_tareas_touch();

drop trigger if exists daily_tareas_rango_trg on public.daily_tareas;
create trigger daily_tareas_rango_trg before insert or update on public.daily_tareas
  for each row execute function public.daily_tareas_rango();

drop trigger if exists daily_pulso_touch on public.daily_pulso;
create trigger daily_pulso_touch before update on public.daily_pulso
  for each row execute function public.daily_pulso_touch();

-- ───────────────────────────── los permisos ─────────────────────────────
-- ⚠️ Leé esto antes de correrlo.
--
-- Tal como está, CUALQUIERA QUE TENGA EL ENLACE PUEDE LEER Y EDITAR. No hay
-- cuentas ni contraseña, a propósito: así el equipo entra sin registrarse.
-- Es la decisión correcta para un tablero interno de tres personas cuyo enlace
-- no circula. No lo es para nada con datos sensibles.
--
-- Si necesitás cerrarlo, la salida es activar Supabase Auth y cambiar
-- `to anon, authenticated` por `to authenticated` en las ocho políticas.
alter table public.daily_tareas enable row level security;
alter table public.daily_pulso  enable row level security;

drop policy if exists daily_tareas_leer   on public.daily_tareas;
drop policy if exists daily_tareas_crear  on public.daily_tareas;
drop policy if exists daily_tareas_editar on public.daily_tareas;
drop policy if exists daily_tareas_borrar on public.daily_tareas;
create policy daily_tareas_leer   on public.daily_tareas for select to anon, authenticated using (true);
create policy daily_tareas_crear  on public.daily_tareas for insert to anon, authenticated with check (btrim(nombre) <> '');
create policy daily_tareas_editar on public.daily_tareas for update to anon, authenticated using (true) with check (true);
create policy daily_tareas_borrar on public.daily_tareas for delete to anon, authenticated using (true);

drop policy if exists daily_pulso_leer   on public.daily_pulso;
drop policy if exists daily_pulso_crear  on public.daily_pulso;
drop policy if exists daily_pulso_editar on public.daily_pulso;
drop policy if exists daily_pulso_borrar on public.daily_pulso;
create policy daily_pulso_leer   on public.daily_pulso for select to anon, authenticated using (true);
create policy daily_pulso_crear  on public.daily_pulso for insert to anon, authenticated with check (btrim(persona) <> '');
create policy daily_pulso_editar on public.daily_pulso for update to anon, authenticated using (true) with check (true);
create policy daily_pulso_borrar on public.daily_pulso for delete to anon, authenticated using (true);

-- ──────────────────── las imágenes de las notas ────────────────────
-- Van a Storage y no incrustadas en la columna: el tablero se trae TODAS las
-- tareas cada 45 s, y unas cuantas capturas en base64 lo vuelven lentísimo.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('notas','notas',true, 10485760,
        array['image/png','image/jpeg','image/gif','image/webp'])
on conflict (id) do update
  set public=true, file_size_limit=10485760, allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists notas_leer   on storage.objects;
drop policy if exists notas_subir  on storage.objects;
drop policy if exists notas_borrar on storage.objects;
create policy notas_leer   on storage.objects for select to anon, authenticated using (bucket_id='notas');
create policy notas_subir  on storage.objects for insert to anon, authenticated with check (bucket_id='notas');
create policy notas_borrar on storage.objects for delete to anon, authenticated using (bucket_id='notas');

-- ═══════════════════════════════════════════════════════════════════════════
-- Listo. Ahora llená CONFIG.supabase en index.html y abrí el archivo.
-- ═══════════════════════════════════════════════════════════════════════════
