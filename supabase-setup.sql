-- Run this once in the Supabase SQL editor for this project
-- (Project settings > SQL Editor > New query)

create table if not exists public.site_data (
  id bigint generated always as identity primary key,
  key text not null unique,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh on every write
create or replace function public.touch_site_data_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_touch_site_data on public.site_data;
create trigger trg_touch_site_data
before update on public.site_data
for each row execute function public.touch_site_data_updated_at();

-- Enable Row Level Security
alter table public.site_data enable row level security;

-- Allow the anon key to read all rows (public site content)
create policy if not exists "Public can read site data"
on public.site_data for select
to anon
using (true);

-- Allow the anon key to insert/update (admin panel is client-side only,
-- so anyone with the anon key can write — fine for a single-admin site,
-- but lock this down further with real auth if you need stricter control)
create policy if not exists "Public can write site data"
on public.site_data for insert
to anon
with check (true);

create policy if not exists "Public can update site data"
on public.site_data for update
to anon
using (true)
with check (true);
