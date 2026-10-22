-- SNAB Vault: private per-user cloud storage and row-level security.
-- Run this once in Supabase Dashboard -> SQL Editor.

create table if not exists public.vault_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null default '{"records":[],"papers":[],"points":[]}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.vault_state enable row level security;

-- Users can only read their own vault row.
create policy "Users can read their own SNAB vault"
on public.vault_state for select
to authenticated
using ((select auth.uid()) = user_id);

-- Users can only create a vault row for their own auth ID.
create policy "Users can create their own SNAB vault"
on public.vault_state for insert
to authenticated
with check ((select auth.uid()) = user_id);

-- Users can only update their own vault row.
create policy "Users can update their own SNAB vault"
on public.vault_state for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- A private bucket holds original PDFs and cropped question images.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('snab-vault', 'snab-vault', false, 52428800, array['application/pdf','image/jpeg'])
on conflict (id) do update set
  public = false,
  file_size_limit = 52428800,
  allowed_mime_types = array['application/pdf','image/jpeg'];

-- File paths begin with the authenticated user's UUID:
-- <user-uuid>/papers/<paper-uuid>/original.pdf
-- <user-uuid>/regions/<region-uuid>.jpg
create policy "Users can read their own SNAB files"
on storage.objects for select
to authenticated
using (
  bucket_id = 'snab-vault'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "Users can upload their own SNAB files"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'snab-vault'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "Users can update their own SNAB files"
on storage.objects for update
to authenticated
using (
  bucket_id = 'snab-vault'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'snab-vault'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "Users can delete their own SNAB files"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'snab-vault'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
