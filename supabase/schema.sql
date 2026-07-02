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
  invite_code   text,
  invited_by    uuid references auth.users(id),
  tenure        text,
  created_at    timestamptz not null default now()
);
-- 아바타 컬럼 (기존 DB 대상 멱등 마이그레이션)
alter table public.profiles add column if not exists skin_color text not null default '#f0c093';
alter table public.profiles add column if not exists cloth_kind text not null default 'farm';
alter table public.profiles add column if not exists hat_name   text not null default '귤모자';
alter table public.profiles add column if not exists prop_kind  text not null default 'none';
-- 친구초대 컬럼
alter table public.profiles add column if not exists invite_code text;
alter table public.profiles add column if not exists invited_by  uuid references auth.users(id);
alter table public.profiles add column if not exists tenure text;
-- 기존 프로필에 초대 코드 backfill (id 기반 6자리, 결정적)
update public.profiles set invite_code = upper(substr(md5(id::text), 1, 6)) where invite_code is null;
create unique index if not exists profiles_invite_code_key on public.profiles(invite_code);
alter table public.profiles enable row level security;
drop policy if exists "profiles self select" on public.profiles;
drop policy if exists "profiles self insert" on public.profiles;
drop policy if exists "profiles self update" on public.profiles;
create policy "profiles self select" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "profiles self insert" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles self update" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- 가입 시 프로필 자동 생성 (name/nationality 는 signUp 메타데이터에서, invite_code 자동 발급)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, nationality, workplace, tenure, invite_code)
  values (new.id, new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'nationality',
          new.raw_user_meta_data->>'workplace', new.raw_user_meta_data->>'tenure',
          upper(substr(md5(new.id::text), 1, 6)))
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users for each row execute function public.handle_new_user();

-- 친구초대 코드 사용(redeem): 초대자 +200P, 나 +100P. RLS 우회 위해 security definer.
-- 반환 jsonb: {ok, reason?, bonus?}
create or replace function public.redeem_invite(code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  inviter uuid;
begin
  if me is null then return jsonb_build_object('ok', false, 'reason', 'auth'); end if;
  if exists (select 1 from public.profiles where id = me and invited_by is not null) then
    return jsonb_build_object('ok', false, 'reason', 'already');
  end if;
  select id into inviter from public.profiles where invite_code = upper(trim(code)) limit 1;
  if inviter is null then return jsonb_build_object('ok', false, 'reason', 'notfound'); end if;
  if inviter = me then return jsonb_build_object('ok', false, 'reason', 'self'); end if;
  update public.profiles set points = points + 200 where id = inviter;
  update public.profiles set points = points + 100, invited_by = inviter where id = me;
  return jsonb_build_object('ok', true, 'bonus', 100);
end; $$;
grant execute on function public.redeem_invite(text) to authenticated;

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

-- ---------- 4-2. post_likes (커뮤니티 좋아요) ----------
create table if not exists public.post_likes (
  post_id    uuid not null references public.community_posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.post_likes enable row level security;
drop policy if exists "likes self all" on public.post_likes;
create policy "likes self all" on public.post_likes for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 좋아요 토글: 내 좋아요를 켜고/끄고 community_posts.likes를 갱신. RLS 우회 위해 security definer.
create or replace function public.toggle_like(p_post uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); is_liked boolean; cnt int;
begin
  if me is null then return jsonb_build_object('ok', false); end if;
  if exists (select 1 from public.post_likes where post_id = p_post and user_id = me) then
    delete from public.post_likes where post_id = p_post and user_id = me;
    update public.community_posts set likes = greatest(0, likes - 1) where id = p_post;
    is_liked := false;
  else
    insert into public.post_likes (post_id, user_id) values (p_post, me);
    update public.community_posts set likes = likes + 1 where id = p_post;
    is_liked := true;
  end if;
  select likes into cnt from public.community_posts where id = p_post;
  return jsonb_build_object('ok', true, 'liked', is_liked, 'likes', cnt);
end; $$;
grant execute on function public.toggle_like(uuid) to authenticated;

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

-- 검증용 테스트 데이터 정리 ('[검증]' 포함 글·댓글 제거). 글 삭제 시 댓글은 FK로 함께 삭제.
delete from public.community_comments where body like '%[검증%' or author_label like '%[검증%';
delete from public.community_posts where title like '%[검증%' or body like '%[검증%';

-- 커뮤니티 시드 글 (author null = 운영/AI 시드). 재실행 시 중복 방지.
delete from public.community_posts where author is null;
insert into public.community_posts (category, title, body, ai_answer, likes, pinned) values
('임금체불','사장이 "다음 달에 준다"만 반복해요','2달째 월급을 안 주는데 계속 미뤄요. 지금 뭘 해야 하나요?','지금 바로 SOS 탭에서 1350 상담을 받으세요. GPS 근무기록을 캡처해두면 진정 접수 시 증거가 됩니다.',6,true),
('계약','근로계약서를 안 써줬어요','일 시작한 지 한 달인데 계약서가 없어요. 이래도 되나요?',null,9,false),
('임금체불','양식장 3개월치 밀렸다가 받은 후기','GPS 기록 제출했더니 사장이 인정했어요. 다들 꼭 매일 찍으세요! 🙏',null,47,false),
('제주생활','성산에서 병원 갈 때 통역 되는 곳?','아파서 병원 가야 하는데 한국어가 서툴러요.',null,6,false),
('비자','E-9에서 E-7-4(숙련기능인력)로 바꾸려면?','성실근로자인데 장기체류 비자로 변경하는 조건이 궁금해요.',null,12,false),
('제주생활','서귀포에서 방 구할 때 보증금 시세?','월세 방을 구하는데 보증금이 보통 얼마 정도인가요?',null,8,false),
('임금체불','퇴직했는데 14일 지나도 월급을 안 줘요','그만둔 지 3주째인데 마지막 달 월급이랑 퇴직금을 안 줍니다. 어떻게 받나요?',null,15,false),
('기타','휴게시간 없이 하루 12시간 일해요','밥 먹을 시간도 없이 계속 일하는데 이거 괜찮은 건가요?',null,11,false),
('계약','일 그만두는데 남은 연차수당 받을 수 있나요?','1년 넘게 일했는데 연차를 거의 못 썼어요. 돈으로 받을 수 있나요?',null,7,false),
('제주생활','한국어 무료로 배울 수 있는 곳 있나요?','일하면서 한국어도 배우고 싶은데 무료 수업이 있을까요?',null,9,false),
('임금체불','최저임금보다 적게 받는 것 같아요','시급 계산이 이상한데 최저임금 미만이면 어떻게 하나요?',null,10,false);

-- 커뮤니티 시드 댓글 (author null = 운영/AI 시드). post_id는 제목으로 매칭.
delete from public.community_comments where author is null;
insert into public.community_comments (post_id, author_label, body, is_ai)
select id, '익명 · 네팔', '저도 같은 일 겪었어요. 1350에 전화하니 통역해서 바로 도와줬어요.', false from public.community_posts where title = '사장이 "다음 달에 준다"만 반복해요'
union all
select id, '익명 · 베트남', 'GPS 출퇴근 기록 꼭 캡처해두세요. 나중에 강력한 증거가 됩니다.', false from public.community_posts where title = '사장이 "다음 달에 준다"만 반복해요'
union all
select id, '✨ AI 도우미', '계약서가 없어도 근로 사실은 인정됩니다(근로기준법 제17조 위반). GPS 출퇴근 기록·급여 이체 내역·동료 진술이 증거가 돼요.', true from public.community_posts where title = '근로계약서를 안 써줬어요'
union all
select id, '익명 · 인도네시아', '저는 사장이 문자로 보낸 근무조건을 저장해뒀는데 그것도 증거가 된대요.', false from public.community_posts where title = '근로계약서를 안 써줬어요'
union all
select id, '익명 · 스리랑카', '증거가 있으면 정말 든든해요. 저도 매일 출근 기록 남기는 중이에요.', false from public.community_posts where title = '사장이 "다음 달에 준다"만 반복해요'
union all
select id, '익명 · 캄보디아', '축하해요! 저도 오늘부터 매일 찍을게요 🙏', false from public.community_posts where title = '양식장 3개월치 밀렸다가 받은 후기'
union all
select id, '✨ AI 도우미', '받은 임금은 꼭 이체 내역으로 확인해두세요. 다음에 또 밀리면 바로 GPS 기록과 함께 신고하시면 됩니다.', true from public.community_posts where title = '양식장 3개월치 밀렸다가 받은 후기'
union all
select id, '익명 · 베트남', '제주외국인노동자지원센터(064-712-1141)에 전화하면 병원 통역을 도와줘요.', false from public.community_posts where title = '성산에서 병원 갈 때 통역 되는 곳?'
union all
select id, '익명 · 네팔', '성산보건지소도 예약하면 통역 연결해준 적 있어요.', false from public.community_posts where title = '성산에서 병원 갈 때 통역 되는 곳?'
union all
select id, '✨ AI 도우미', 'E-9로 4년 이상 성실 근무 + 한국어능력·소득 요건을 충족하면 E-7-4 전환을 신청할 수 있어요. 사업주 추천과 근무 경력 증빙이 중요합니다.', true from public.community_posts where title = 'E-9에서 E-7-4(숙련기능인력)로 바꾸려면?'
union all
select id, '익명 · 인도네시아', '저도 준비 중인데, 매년 소득·근속 증빙 모아두는 게 유리하대요.', false from public.community_posts where title = 'E-9에서 E-7-4(숙련기능인력)로 바꾸려면?'
union all
select id, '익명 · 캄보디아', '서귀포 읍면 지역은 보증금 100~300만원, 월세 25~40만원 선이 많아요.', false from public.community_posts where title = '서귀포에서 방 구할 때 보증금 시세?'
union all
select id, '익명 · 베트남', '사업장 기숙사가 있으면 그것부터 확인해보세요. 보증금 부담이 훨씬 적어요.', false from public.community_posts where title = '서귀포에서 방 구할 때 보증금 시세?'
union all
select id, '✨ AI 도우미', '퇴직 후 14일 이내 미지급은 근로기준법 제36조 위반입니다. 1년 이상 근무했다면 퇴직금도 청구 대상이에요. 1350 상담 후 노동청 진정을 넣으세요.', true from public.community_posts where title = '퇴직했는데 14일 지나도 월급을 안 줘요'
union all
select id, '익명 · 네팔', '저도 퇴직금 있는 줄 몰랐다가 신고해서 받았어요. 포기하지 마세요!', false from public.community_posts where title = '퇴직했는데 14일 지나도 월급을 안 줘요'
union all
select id, '익명 · 스리랑카', 'GPS 기록이랑 급여 이체 내역 꼭 챙기세요. 증거가 힘이 돼요.', false from public.community_posts where title = '퇴직했는데 14일 지나도 월급을 안 줘요'
union all
select id, '✨ AI 도우미', '4시간마다 30분, 8시간이면 1시간 이상 휴게시간이 법으로 보장됩니다(근로기준법 제54조). 12시간 근무면 연장·야간 수당도 받아야 해요.', true from public.community_posts where title = '휴게시간 없이 하루 12시간 일해요'
union all
select id, '익명 · 미얀마', '저희 사업장도 그랬는데 센터에 상담하니 개선됐어요.', false from public.community_posts where title = '휴게시간 없이 하루 12시간 일해요'
union all
select id, '✨ AI 도우미', '1년 이상 근무 시 미사용 연차는 수당으로 청구할 수 있어요(근로기준법 제60조). 퇴직 시 함께 정산을 요구하세요.', true from public.community_posts where title = '일 그만두는데 남은 연차수당 받을 수 있나요?'
union all
select id, '익명 · 베트남', '퇴사 전에 남은 연차 일수를 문자로 확인받아두면 나중에 편해요.', false from public.community_posts where title = '일 그만두는데 남은 연차수당 받을 수 있나요?'
union all
select id, '익명 · 인도네시아', '제주외국인노동자지원센터(064-712-1141)에서 무료 한국어 교실을 운영해요.', false from public.community_posts where title = '한국어 무료로 배울 수 있는 곳 있나요?'
union all
select id, '익명 · 캄보디아', '온라인 EPS-TOPIK 자료도 공부에 도움 됐어요.', false from public.community_posts where title = '한국어 무료로 배울 수 있는 곳 있나요?'
union all
select id, '✨ AI 도우미', '2026년 최저임금은 시급 10,320원이에요. 이보다 적게 받았다면 차액을 청구할 수 있고, 상습적이면 신고 대상입니다. 급여명세서와 근무기록을 모아두세요.', true from public.community_posts where title = '최저임금보다 적게 받는 것 같아요'
union all
select id, '익명 · 네팔', '급여명세서를 안 주면 그것도 법 위반이래요. 요구하세요!', false from public.community_posts where title = '최저임금보다 적게 받는 것 같아요';
