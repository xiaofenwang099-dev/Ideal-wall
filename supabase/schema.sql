-- Ideal Wall shared database for Supabase.
-- Run this once in Supabase Dashboard > SQL Editor.

create table if not exists public.wishes (
  id uuid primary key default gen_random_uuid(),
  text text not null check (char_length(btrim(text)) between 4 and 120),
  category text not null check (category in ('生活', '旅行', '事业', '关系', '成长', '世界')),
  nickname text not null default '匿名' check (char_length(nickname) <= 24),
  like_count integer not null default 0 check (like_count >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.wish_likes (
  wish_id uuid not null references public.wishes(id) on delete cascade,
  voter_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (wish_id, voter_id)
);

create index if not exists wishes_created_at_idx on public.wishes (created_at desc);
create index if not exists wishes_like_count_idx on public.wishes (like_count desc);

alter table public.wishes enable row level security;
alter table public.admin_users enable row level security;
alter table public.wish_likes enable row level security;

revoke all on table public.wishes, public.admin_users, public.wish_likes from anon, authenticated;
grant select on table public.wishes to anon, authenticated;
grant insert (text, category, nickname) on table public.wishes to authenticated;
grant update (text, category, nickname) on table public.wishes to authenticated;
grant delete on table public.wishes to authenticated;
grant select on table public.admin_users to authenticated;
grant select on table public.wish_likes to authenticated;
grant insert (wish_id) on table public.wish_likes to authenticated;

drop policy if exists "Admins can check their own membership" on public.admin_users;
create policy "Admins can check their own membership"
  on public.admin_users for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Wishes are public to read" on public.wishes;
create policy "Wishes are public to read"
  on public.wishes for select to anon, authenticated using (true);

drop policy if exists "Signed-in visitors may submit wishes" on public.wishes;
create policy "Signed-in visitors may submit wishes"
  on public.wishes for insert to authenticated
  with check (char_length(btrim(text)) between 4 and 120 and category in ('生活', '旅行', '事业', '关系', '成长', '世界'));

create or replace function public.is_ideal_wall_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_ideal_wall_admin() from public;
grant execute on function public.is_ideal_wall_admin() to authenticated;

drop policy if exists "Admins may edit wishes" on public.wishes;
create policy "Admins may edit wishes"
  on public.wishes for update to authenticated
  using ((select public.is_ideal_wall_admin()))
  with check ((select public.is_ideal_wall_admin()));

drop policy if exists "Admins may delete wishes" on public.wishes;
create policy "Admins may delete wishes"
  on public.wishes for delete to authenticated
  using ((select public.is_ideal_wall_admin()));

drop policy if exists "Visitors can check their own likes" on public.wish_likes;
create policy "Visitors can check their own likes"
  on public.wish_likes for select to authenticated
  using (voter_id = (select auth.uid()));

drop policy if exists "Visitors may like once per wish" on public.wish_likes;
create policy "Visitors may like once per wish"
  on public.wish_likes for insert to authenticated
  with check (voter_id = (select auth.uid()));

create or replace function public.bump_ideal_wall_like_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.wishes set like_count = like_count + 1 where id = new.wish_id;
  return new;
end;
$$;

drop trigger if exists wish_like_increment_count on public.wish_likes;
create trigger wish_like_increment_count
  after insert on public.wish_likes
  for each row execute function public.bump_ideal_wall_like_count();

-- Initial shared examples; run this file only once on a fresh project.
insert into public.wishes (text, category, nickname, like_count, created_at) values
  ('在海边的小城开一家书店，窗台上永远有一只晒太阳的猫。','生活','小岛',50,now()-interval '15 hours'),
  ('和妈妈一起去看一次极光。我们把这个愿望说了好多年。','旅行','晚风',19,now()-interval '14 hours'),
  ('成为一个能把复杂的事情，讲给更多人听的老师。','事业','一颗橘子',16,now()-interval '13 hours'),
  ('三十五岁之前，走完家门口那条山脉的所有步道。','成长','匿名',14,now()-interval '12 hours'),
  ('每个月认真做一次饭，邀请很久没见的老朋友。','关系','树懒同学',12,now()-interval '11 hours'),
  ('有能力给家里人买一张说走就走的机票。','生活','阿禾',11,now()-interval '10 hours'),
  ('去冰岛住一个月，什么安排都没有，只跟着天气散步。','旅行','慢慢来',9,now()-interval '9 hours'),
  ('做一个小小的公益计划，让乡村孩子也能读到好书。','世界','萤火',8,now()-interval '8 hours'),
  ('学会弹完整首《月亮代表我的心》，弹给喜欢的人听。','成长','匿名',7,now()-interval '7 hours'),
  ('和最好的朋友，在不同的城市也能每年见一面。','关系','Momo',6,now()-interval '6 hours'),
  ('做一份喜欢的工作，也留出时间好好过生活。','事业','清晨四点',5,now()-interval '5 hours'),
  ('等花开的时候，带爷爷奶奶去看一整片油菜花田。','生活','橙子汽水',4,now()-interval '4 hours'),
  ('在雨林里听一夜的雨声，醒来时不用看手机。','旅行','南风',3,now()-interval '3 hours'),
  ('种一棵树，等它长成可以乘凉的样子。','世界','匿名',2,now()-interval '2 hours'),
  ('每年写一本小小的旅行手账，记住路上的人和风景。','成长','纸飞机',1,now()-interval '1 hour');

