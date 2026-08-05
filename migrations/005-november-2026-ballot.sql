-- Migration 005: November 3, 2026 general election ballot
-- Run AFTER migrations/004-ballot-model.sql.
--
-- Nominees come from the August 4, 2026 primary. IMPORTANT: these are
-- UNOFFICIAL results as reported the night of the primary; Missouri does not
-- certify for roughly two weeks. Re-check against the Secretary of State's
-- official certified list before relying on this:
--   https://www.sos.mo.gov/elections/candidates
--
-- Sources for each nominee are noted inline. Contests that could NOT be
-- verified are listed at the bottom as TODO rather than guessed at.

-- Elections can carry a short status note shown under the ballot header.
alter table elections add column note text;

update elections set note =
  'Candidates reflect unofficial results from the August 4, 2026 primary. '
  || 'Results are certified by the state in the weeks afterward.'
where election_date = date '2026-11-03';

-- ---------------------------------------------------------------------------
-- Statewide scope: State Auditor is the only statewide office in 2026.
-- Statewide scopes attach to every city in the state automatically.
-- ---------------------------------------------------------------------------

insert into districts (level, name, short_name, state, info_url, sort_order)
values ('statewide', 'State of Missouri', 'Statewide', 'MO',
        'https://www.sos.mo.gov/elections', 5);

insert into elections (district_id, name, election_date, note)
select id, 'General Election', date '2026-11-03',
       'Candidates reflect unofficial results from the August 4, 2026 primary. '
       || 'Results are certified by the state in the weeks afterward.'
from districts where short_name = 'Statewide' and state = 'MO';

-- State Auditor — R: Scott Fitzpatrick (incumbent) def. Gerald Wistrand;
-- D: Quentin Wilson def. Gregory Upchurch; L: Dustin Coffell unopposed.
with r as (
  insert into races (election_id, title, kind, vote_for, description, sort_order)
  select e.id, 'State Auditor', 'office', 1,
         'The state auditor reviews the finances and operations of Missouri state '
         || 'agencies and local governments. Four-year term.', 0
  from elections e
  join districts d on d.id = e.district_id
  where d.short_name = 'Statewide' and d.state = 'MO' and e.election_date = date '2026-11-03'
  returning id
)
insert into candidates (race_id, name, party, incumbent, sort_order)
select r.id, v.name, v.party, v.incumbent, v.sort_order
from r, (values
  ('Scott Fitzpatrick', 'Republican',  true,  0),
  ('Quentin Wilson',    'Democratic',  false, 1),
  ('Dustin Coffell',    'Libertarian', false, 2)
) as v(name, party, incumbent, sort_order);

-- ---------------------------------------------------------------------------
-- U.S. Representative — District 1 (Maryland Heights, Bridgeton, Overland,
-- part of Creve Coeur)
-- D: Wesley Bell (incumbent) def. Cori Bush, 59%-37%. R: Paul Berry III.
-- L: Tom Schmitz.
-- ---------------------------------------------------------------------------
with r as (
  insert into races (election_id, title, kind, vote_for, description, sort_order)
  select e.id, 'U.S. Representative — District 1', 'office', 1,
         'Represents Missouri''s 1st Congressional District in the U.S. House. Two-year term.', 0
  from elections e
  join districts d on d.id = e.district_id
  where d.short_name = 'MO-1' and d.state = 'MO' and e.election_date = date '2026-11-03'
  returning id
)
insert into candidates (race_id, name, party, incumbent, bio, website, sort_order)
select r.id, v.name, v.party, v.incumbent, v.bio, v.website, v.sort_order
from r, (values
  ('Wesley Bell', 'Democratic', true,
   'U.S. Representative for Missouri''s 1st Congressional District since January 2025. Former St. Louis County Prosecuting Attorney and Ferguson City Council member.',
   'https://bell.house.gov/', 0),
  ('Paul Berry III', 'Republican', false, null, null, 1),
  ('Tom Schmitz', 'Libertarian', false, null, null, 2)
) as v(name, party, incumbent, bio, website, sort_order);

-- ---------------------------------------------------------------------------
-- U.S. Representative — District 2 (Town and Country, part of Creve Coeur)
-- R: Ann Wagner (incumbent) def. Matthew Grant. D: Fred Wellman.
-- ---------------------------------------------------------------------------
with r as (
  insert into races (election_id, title, kind, vote_for, description, sort_order)
  select e.id, 'U.S. Representative — District 2', 'office', 1,
         'Represents Missouri''s 2nd Congressional District in the U.S. House. Two-year term.', 0
  from elections e
  join districts d on d.id = e.district_id
  where d.short_name = 'MO-2' and d.state = 'MO' and e.election_date = date '2026-11-03'
  returning id
)
insert into candidates (race_id, name, party, incumbent, bio, website, sort_order)
select r.id, v.name, v.party, v.incumbent, v.bio, v.website, v.sort_order
from r, (values
  ('Ann Wagner', 'Republican', true,
   'U.S. Representative for Missouri''s 2nd Congressional District since 2013.',
   'https://wagner.house.gov/', 0),
  ('Fred Wellman', 'Democratic', false, null, null, 1)
) as v(name, party, incumbent, bio, website, sort_order);

-- ---------------------------------------------------------------------------
-- State Representative — District 70 (Bridgeton, part of Maryland Heights)
-- Stephanie Boykin (D, incumbent) — no other candidate filed.
-- ---------------------------------------------------------------------------
with r as (
  insert into races (election_id, title, kind, vote_for, description, sort_order)
  select e.id, 'State Representative — District 70', 'office', 1,
         'No other candidate filed for this seat. Two-year term.', 0
  from elections e
  join districts d on d.id = e.district_id
  where d.short_name = 'House 70' and d.state = 'MO' and e.election_date = date '2026-11-03'
  returning id
)
insert into candidates (race_id, name, party, incumbent, bio, website, sort_order)
select r.id, 'Stephanie Boykin', 'Democratic', true,
       'State Representative for District 70 since January 2025. Retired U.S. Air Force lieutenant colonel and certified teacher.',
       'https://house.mo.gov/MemberDetails.aspx?district=070', 0
from r;

-- ---------------------------------------------------------------------------
-- State Representative — District 71 (parts of Creve Coeur, Maryland Heights,
-- Overland). OPEN SEAT: LaDonna Appelbaum is term-limited.
-- Nicole Greer (D) — no other candidate filed.
--
-- ⚠ VERIFY: a Nicole Greer also serves on the Creve Coeur City Council
-- (Ward 2). If they are the same person, the site correctly shows one merged
-- page. If they are two different people, this data needs distinguishing —
-- check before publishing.
-- ---------------------------------------------------------------------------
with r as (
  insert into races (election_id, title, kind, vote_for, description, sort_order)
  select e.id, 'State Representative — District 71', 'office', 1,
         'Open seat — the current representative is term-limited. No other candidate filed. Two-year term.', 0
  from elections e
  join districts d on d.id = e.district_id
  where d.short_name = 'House 71' and d.state = 'MO' and e.election_date = date '2026-11-03'
  returning id
)
insert into candidates (race_id, name, party, incumbent, sort_order)
select r.id, 'Nicole Greer', 'Democratic', false, 0
from r;

-- ---------------------------------------------------------------------------
-- TODO — could not be verified from available sources; add once confirmed
-- against the official St. Louis County Board of Elections / Secretary of
-- State results:
--
--   * Missouri Senate District 24 (Maryland Heights, Creve Coeur) — Tracy
--     McCreery (D) was running; the Republican nominee, if any, is unconfirmed.
--   * Missouri Senate District 14 (Bridgeton, Overland, part of Maryland
--     Heights) — Senate 14 is an even/odd-cycle question; confirm whether it
--     is even on the 2026 ballot before adding.
--   * Missouri House District 87 (Westport area of Maryland Heights) —
--     Connie Steinmetz (D) incumbent; full field unconfirmed.
--   * Missouri House District 89 (part of Town and Country) — George Hruza (R)
--     incumbent sought re-election; full field unconfirmed.
--   * St. Louis County offices (County Executive and others may be on the
--     2026 ballot) — no county scope has been added yet.
--   * November ballot measures — the four constitutional amendments were on
--     the AUGUST ballot (1 and 2 passed; 4 and 5 failed). Confirm whether any
--     measures were referred to November.
--
-- Until a contest is added, its scope simply shows no contest on the ballot,
-- which is preferable to publishing an unverified one.
-- ---------------------------------------------------------------------------
