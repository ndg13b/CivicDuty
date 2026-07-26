-- Migration 004: the ballot model
-- Run AFTER migrations/003-seed-new-cities.sql.
--
-- Three changes, all needed before entering November 2026 ballot data:
--
--   1. Resources become shareable. A single debate video usually covers every
--      candidate in a race, so a resource can no longer belong to exactly one
--      parent — it is now linked to any number of races and candidates.
--   2. Races can be ballot measures, not just contests between candidates.
--   3. Districts can represent statewide and county scopes, so a ballot can be
--      assembled from every level a voter actually sees.

-- ---------------------------------------------------------------------------
-- 1. Shareable resources
-- ---------------------------------------------------------------------------

-- Describe the resource itself more fully; these show on cards in the UI.
alter table resources add column source text;        -- "League of Women Voters"
alter table resources add column published_on date;  -- when it was published/recorded
alter table resources add column note text;          -- "1h 24m", short descriptor

-- Where a resource appears. One row per attachment, so one video can cover a
-- race and each of its candidates.
create table resource_links (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null references resources(id) on delete cascade,
  race_id uuid references races(id) on delete cascade,
  candidate_id uuid references candidates(id) on delete cascade,
  sort_order int not null default 0,
  check (
    (race_id is not null and candidate_id is null) or
    (race_id is null and candidate_id is not null)
  )
);

create unique index resource_links_race_uniq
  on resource_links (resource_id, race_id) where race_id is not null;
create unique index resource_links_candidate_uniq
  on resource_links (resource_id, candidate_id) where candidate_id is not null;

-- Carry any existing attachments over into the link table.
insert into resource_links (resource_id, race_id, candidate_id, sort_order)
select id, race_id, candidate_id, sort_order from resources;

-- The old single-parent columns are now redundant. Dropping them also drops
-- the check constraint that referenced them.
alter table resources drop column race_id;
alter table resources drop column candidate_id;

-- ---------------------------------------------------------------------------
-- 2. Ballot measures
-- ---------------------------------------------------------------------------

alter table races add column kind text not null default 'office'
  check (kind in ('office', 'measure'));
alter table races add column official_text text;   -- the ballot language, verbatim
alter table races add column vote_for int not null default 1;  -- "Vote for up to N"

-- A measure has no candidates; its Yes/No options are implicit in the UI, and
-- supporting/opposing material is attached as resources.

-- Incumbency is useful context on a ballot and can't be derived reliably
-- (an officeholder may run for a different seat).
alter table candidates add column incumbent boolean not null default false;

-- ---------------------------------------------------------------------------
-- 3. Statewide / county / judicial scopes
--
-- A "district" is really any electoral scope. Statewide scopes are matched to
-- cities by state rather than through jurisdiction_districts, so adding a new
-- city automatically picks up statewide contests with nothing to remember.
-- ---------------------------------------------------------------------------

alter table districts drop constraint districts_level_check;
alter table districts add constraint districts_level_check check (
  level in ('statewide', 'us_senate', 'us_house', 'state_senate', 'state_house',
            'county', 'judicial')
);

-- ---------------------------------------------------------------------------
-- Security: same model as every other table — the public key reads, never writes.
-- ---------------------------------------------------------------------------

alter table resource_links enable row level security;
create policy "public can read resource_links" on resource_links for select using (true);
grant select on resource_links to anon, authenticated;
