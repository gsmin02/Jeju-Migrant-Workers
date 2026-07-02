-- ============================================================
-- 제이(Jeju Migrant Workers) — Supabase 스키마 + RLS + 시드
-- ------------------------------------------------------------
-- 실행: Supabase 대시보드 → SQL Editor 에 전체 붙여넣기 → Run.
-- (publishable 키로는 테이블 생성이 불가하므로 이 스크립트를 한 번 실행해야 합니다.)
-- 여러 번 실행해도 안전하도록 idempotent 하게 작성.
-- work_logs 테이블은 이미 존재하므로 재생성하지 않고 정책만 보강.
-- ============================================================

-- ---------- 1. profiles (auth 사용자 1:1 프로필) ----------
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  name          text,
  nationality   text,
  workplace     text,
  points        int  not null default 0,
  attend_streak int  not null default 0,
  last_attend   date,
  skin_color    text not null default '#f0c093',
  cloth_kind    text not null default 'farm',
  hat_name      text not null default '귤모자',
  prop_kind     text not null default 'none',
  created_at    timestamptz not null default now()
);
-- 아바타 컬럼 (기존 DB 대상 멱등 마이그레이션)
alter table public.profiles add column if not exists skin_color text not null default '#f0c093';
alter table public.profiles add column if not exists cloth_kind text not null default 'farm';
alter table public.profiles add column if not exists hat_name   text not null default '귤모자';
alter table public.profiles add column if not exists prop_kind  text not null default 'none';
alter table public.profiles enable row level security;
drop policy if exists "profiles self select" on public.profiles;
drop policy if exists "profiles self insert" on public.profiles;
drop policy if exists "profiles self update" on public.profiles;
create policy "profiles self select" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "profiles self insert" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles self update" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- 가입 시 프로필 자동 생성 (name/nationality 는 signUp 메타데이터에서)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, nationality)
  values (new.id, new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'nationality')
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users for each row execute function public.handle_new_user();

-- ---------- 2. workplaces (공개 참조 데이터) ----------
create table if not exists public.workplaces (
  id          bigint generated always as identity primary key,
  name        text not null,
  job         text,
  industry    text,
  region      text,
  pay         text,
  reports     int  not null default 0,
  workers     int  not null default 0,
  last_report text,
  rating      numeric(2,1),
  sort        int  not null default 0
);
alter table public.workplaces enable row level security;
drop policy if exists "workplaces read" on public.workplaces;
create policy "workplaces read" on public.workplaces for select to authenticated using (true);

-- ---------- 3. community_posts ----------
create table if not exists public.community_posts (
  id         uuid primary key default gen_random_uuid(),
  author     uuid references auth.users(id) on delete set null,
  category   text,
  title      text not null,
  body       text,
  ai_answer  text,          -- ✨ AI 도우미 답변 (없으면 null)
  likes      int  not null default 0,
  pinned     boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.community_posts enable row level security;
drop policy if exists "posts read" on public.community_posts;
drop policy if exists "posts insert own" on public.community_posts;
drop policy if exists "posts update own" on public.community_posts;
create policy "posts read" on public.community_posts for select to authenticated using (true);
create policy "posts insert own" on public.community_posts for insert to authenticated with check (auth.uid() = author);
create policy "posts update own" on public.community_posts for update to authenticated using (auth.uid() = author) with check (auth.uid() = author);

-- ---------- 4. community_comments ----------
create table if not exists public.community_comments (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid references public.community_posts(id) on delete cascade,
  author       uuid references auth.users(id) on delete set null,
  author_label text,         -- "익명 · 네팔" 같은 표시용 라벨
  body         text not null,
  is_ai        boolean not null default false,
  created_at   timestamptz not null default now()
);
alter table public.community_comments enable row level security;
drop policy if exists "comments read" on public.community_comments;
drop policy if exists "comments insert own" on public.community_comments;
create policy "comments read" on public.community_comments for select to authenticated using (true);
create policy "comments insert own" on public.community_comments for insert to authenticated with check (auth.uid() = author);

-- ---------- 4-1. post_translations (커뮤니티 글 번역 캐시) ----------
-- AI로 한 번 번역한 글(제목/본문/AI답변)을 언어별로 저장해 재호출을 막는다.
-- 캐시는 모든 로그인 사용자가 공유(읽기·쓰기).
create table if not exists public.post_translations (
  post_id    uuid not null references public.community_posts(id) on delete cascade,
  lang       text not null,
  title      text,
  body       text,
  ai_answer  text,
  created_at timestamptz not null default now(),
  primary key (post_id, lang)
);
alter table public.post_translations enable row level security;
drop policy if exists "post_tr read" on public.post_translations;
drop policy if exists "post_tr insert" on public.post_translations;
drop policy if exists "post_tr update" on public.post_translations;
create policy "post_tr read" on public.post_translations for select to authenticated using (true);
create policy "post_tr insert" on public.post_translations for insert to authenticated with check (true);
create policy "post_tr update" on public.post_translations for update to authenticated using (true) with check (true);

-- ---------- 5. work_logs (이미 존재) — 정책 보강만 ----------
-- 테이블/컬럼은 기존 것을 사용. 혹시 정책이 없다면 아래로 보강.
alter table if exists public.work_logs enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='work_logs' and policyname='work_logs owner all') then
    create policy "work_logs owner all" on public.work_logs
      for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
  end if;
end $$;

-- ============================================================
-- 시드 데이터 (참조용). 재실행 시 중복 방지 위해 먼저 비움.
-- ============================================================
truncate table public.workplaces restart identity;
insert into public.workplaces (name, job, industry, region, pay, reports, workers, last_report, rating, sort) values
('첼린저팜','말목장 관리사','축산','제주시','시급 10,320원',0,4,null,4.3,1),
('친환경제주귀한농부영농조합','농업 및 분류업무','축산','서귀포시','시급 10,320원',2,7,'2025',null,2),
('효돈화훼농원','농업 단순 종사원','농업','서귀포시','시급 10,320원',0,5,null,4.5,3),
('한라이엔지(주)','재활용품 분리수거·폐기물 선별','청소/미화','서귀포시','월급 2,156,880원',0,9,null,3.9,4),
('에스에이치수산','양식장 단순노무직','양식','서귀포시','시급 10,320원',3,8,'2025',null,5),
('207부광호','연근해 갑판원','어업','제주시','시급 10,320원',0,3,null,4.0,6),
('안성호','연근해 갑판원','어업','제주시','시급 10,320원',0,4,null,4.1,7),
('해주축산','육가공 제조(생산직)','제조','제주시','월급 2,156,880원',0,11,null,4.2,8),
('대명호','연근해 갑판원','어업','서귀포시','시급 10,320원',1,2,'2024',null,9),
('대정양돈','축산업 단순 노무직','축산','서귀포시','시급 10,320원',0,6,null,4.0,10),
('(주)산내들환경','제조 단순 종사원','제조','제주시','월급 2,700,000원',0,10,null,4.4,11),
('(주)대주환경자원','제조 관련 단순 종사원','제조','제주시','월급 3,500,000원',0,8,null,4.6,12),
('한라골드영농조합','축산 직원','축산','제주시','월급 2,200,000원',0,5,null,4.1,13),
('무드내','제조/생산 직원','제조','제주시','시급 10,320원',0,7,null,4.0,14),
('금하순대','순대 공장 직원','식료품 제조','제주시','시급 10,320원',2,6,'2025',null,15),
('성은호','선원','어업','서귀포시','시급 10,320원',0,3,null,3.8,16),
('제2015대양호','선원','어업','서귀포시','시급 10,320원',0,2,null,4.0,17),
('제주스치로폴(주)','스티로폼 박스 생산','제조','서귀포시','월급 2,156,880원',0,9,null,4.2,18),
('제주올레바당(어업회사법인)','수산물 진공포장 제조','제조','제주시','월급 2,156,880원',0,12,null,4.3,19),
('해성호','선원','어업','서귀포시','시급 10,320원',0,3,null,3.9,20),
('만성호','연근해 갑판원','어업','서귀포시','시급 10,320원',0,2,null,4.0,21),
('포인트호','선원','어업','제주시','시급 10,320원',0,4,null,4.1,22),
('(주)대한에프앤비','제조 단순노무자','식료품 제조','제주시','연봉 2,880만원',0,14,null,4.5,23),
('한도래영어조합','양식장','양식','서귀포시','시급 10,320원',0,7,null,4.2,24),
('제주웰빙수산','생산직','식료품 제조','제주시','월급 2,500,000원',0,8,null,4.3,25),
('(주)한라지엔씨','현장/생산직','제조','제주시','연봉 2,700만원',0,10,null,4.4,26),
('이도에코제주(주)','제조업 단순 종사자','제조','제주시','월급 2,156,900원',0,9,null,4.1,27),
('제주영주수산영어조합','단순노무 직원','제조','서귀포시','시급 12,000원',0,6,null,4.5,28),
('(주)녹원목장(농업회사법인)','가축(말) 사육 종사원','축산','제주시','시급 15,000원',0,5,null,4.7,29),
('제주농장영농조합','식품제조 단순 종사자','제조','제주시','월급 2,156,880원',0,8,null,4.2,30);

-- 커뮤니티 시드 글 (author null = 운영/AI 시드). 재실행 시 중복 방지.
delete from public.community_posts where author is null;
insert into public.community_posts (category, title, body, ai_answer, likes, pinned) values
('임금체불','사장이 "다음 달에 준다"만 반복해요','2달째 월급을 안 주는데 계속 미뤄요. 지금 뭘 해야 하나요?','지금 바로 SOS 탭에서 1350 상담을 받으세요. GPS 근무기록을 캡처해두면 진정 접수 시 증거가 됩니다.',6,true),
('계약','근로계약서를 안 써줬어요','일 시작한 지 한 달인데 계약서가 없어요. 이래도 되나요?',null,9,false),
('임금체불','양식장 3개월치 밀렸다가 받은 후기','GPS 기록 제출했더니 사장이 인정했어요. 다들 꼭 매일 찍으세요! 🙏',null,47,false),
('제주생활','성산에서 병원 갈 때 통역 되는 곳?','아파서 병원 가야 하는데 한국어가 서툴러요.',null,6,false);
