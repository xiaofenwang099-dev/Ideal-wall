-- User accounts, private wishes, and custom categories.
-- Safe to run once on the existing Ideal Wall Supabase project.

begin;

alter table public.wishes
  add column if not exists user_id uuid references auth.users(id) on delete cascade default auth.uid(),
  add column if not exists is_public boolean not null default true;

alter table public.wishes drop constraint if exists wishes_category_check;
alter table public.wishes drop constraint if exists wishes_category_length_check;
alter table public.wishes add constraint wishes_category_length_check
  check (char_length(btrim(category)) between 1 and 24);

create index if not exists wishes_user_id_created_at_idx
  on public.wishes (user_id, created_at desc);
create index if not exists wishes_public_created_at_idx
  on public.wishes (is_public, created_at desc);

drop policy if exists "Wishes are public to read" on public.wishes;
drop policy if exists "Signed-in visitors may submit wishes" on public.wishes;
drop policy if exists "Admins may edit wishes" on public.wishes;
drop policy if exists "Admins may delete wishes" on public.wishes;
drop policy if exists "Public wishes are viewable" on public.wishes;
drop policy if exists "Owners and admins can view private wishes" on public.wishes;
drop policy if exists "Registered users may submit wishes" on public.wishes;
drop policy if exists "Owners and admins may edit wishes" on public.wishes;
drop policy if exists "Owners and admins may delete wishes" on public.wishes;

revoke all on table public.wishes from anon, authenticated;
grant select on table public.wishes to anon, authenticated;
grant insert (text, category, nickname, is_public) on public.wishes to authenticated;
grant update (text, category, nickname, is_public) on public.wishes to authenticated;
grant delete on public.wishes to authenticated;

create policy "Public wishes are viewable"
  on public.wishes for select to anon, authenticated
  using (is_public = true);

create policy "Owners and admins can view private wishes"
  on public.wishes for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_ideal_wall_admin()));

create policy "Registered users may submit wishes"
  on public.wishes for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean, false)
    and char_length(btrim(text)) between 4 and 120
    and char_length(btrim(category)) between 1 and 24
    and char_length(nickname) <= 24
  );

create policy "Owners and admins may edit wishes"
  on public.wishes for update to authenticated
  using (user_id = (select auth.uid()) or (select public.is_ideal_wall_admin()))
  with check (user_id = (select auth.uid()) or (select public.is_ideal_wall_admin()));

create policy "Owners and admins may delete wishes"
  on public.wishes for delete to authenticated
  using (user_id = (select auth.uid()) or (select public.is_ideal_wall_admin()));

drop policy if exists "Visitors may like once per wish" on public.wish_likes;
create policy "Visitors may like public wishes once"
  on public.wish_likes for insert to authenticated
  with check (
    voter_id = (select auth.uid())
    and exists (select 1 from public.wishes w where w.id = wish_id and w.is_public = true)
  );

commit;
