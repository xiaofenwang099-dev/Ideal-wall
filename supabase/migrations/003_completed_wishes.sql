-- Add a completion state for each wish.
-- Run once in Supabase Dashboard > SQL Editor on the existing project.

begin;

alter table public.wishes
  add column if not exists is_completed boolean not null default false;

-- The existing RLS update policies from 002 still restrict this field to the
-- wish owner or an administrator.
grant update (is_completed) on table public.wishes to authenticated;

commit;

