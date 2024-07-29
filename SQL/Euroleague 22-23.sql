--kreiranje tabele countries
create table countries (
country_id INT,
country_name VARCHAR2(30),
CONSTRAINT pk_countries primary key (country_id)
);
--ubacivanje podataka u countries
insert into countries select * from evroliga.countries;

--kreiranje tabele teams
create table teams (
team_id int,
team_name varchar2(35),
country_id int,
constraint pk_teams primary key (team_id),
constraint fk_teams foreign key (country_id) references countries(country_id)
);
alter table teams add coach_id int;
alter table teams add constraint fk_teams_c_id foreign key (coach_id) references coaches (coach_id);
update teams set coach_id = 1 where team_id = 1;
update teams set coach_id = 2 where team_id = 7;
--ubacivanje podataka u teams
insert into teams select e.team_id, e.team_name, c.country_id 
from evroliga.teams e join countries c on e.country_name = c.country_name;
update teams set team_name = 'CSKA', country_id = 10 where team_id = 2;
update teams set team_name = 'Zenit', country_id = 10 where team_id = 6;
update teams set team_name = 'Unics', country_id = 10 where team_id = 12;

--kreiranje tabele treneri
create table coaches (
coach_id int,
first_name varchar2(20) not null,
last_name varchar2(20),
team_id int,
constraint pk_coaches primary key (coach_id),
constraint fk_team foreign key (team_id) references teams (team_id)
);
insert into coaches values (1,'Dejan','Radonjic');
insert into coaches values (2,'Jorgos','Barcokas');


create table coaches_history (
coaches_history_id int,
coach_id int,
coach_name varchar2(50),
team_id int,
team_name varchar2(35),
end_date date default sysdate,
constraint pk_coaches_history primary key (coaches_history_id),
constraint fk_coaches_history_c_id foreign key (coach_id) references coaches (coach_id),
constraint fk_coaches_history_t_id foreign key (team_id) references teams (team_id)
);
CREATE SEQUENCE coaches_history_seq START WITH 1 INCREMENT BY 1;

/*
create or replace trigger coaches_update
after update on coaches
for each row
begin
  insert into coaches_history (coaches_history_id,coach_id,coach_name,team_id,team_name,end_date)
  values (coaches_history_seq.nextval,:old.coach_id,:old.first_name||' '||:old.last_name,:old.team_id,
          (select team_name from teams where team_id = :old.team_id),sysdate);
end;
*/

create or replace trigger coach_team_update
after update on teams
for each row
begin
  insert into coaches_history (coaches_history_id,coach_id,coach_name,team_id,team_name,start_date,end_date)
  values (coaches_history_seq.nextval,:old.coach_id,(select first_name||' '||last_name from coaches where coach_id = :old.coach_id),
          :old.team_id,:old.team_name,(select start_date from coaches where coach_id = :old.coach_id),(select start_date from coaches where coach_id = :new.coach_id));
end;

--kreiranje tabele matches
create table matches (
match_id int,
round int not null,
home_team_id int not null,
away_team_id int not null,
home_team_score int not null,
away_team_score int not null,
match_date timestamp,
constraint pk_matches primary key (match_id),
constraint fk_matches_home foreign key (home_team_id) references teams (team_id),
constraint fk_matches_away foreign key (away_team_id) references teams (team_id),
constraint chk_matches_scores check (home_team_score>=0 and away_team_score >=0)
);
--kreiranje indeksa za match_date
create index indx_match_date on matches (match_date);

--kreiranje sekvence za match_id
create sequence match_id_seq start with 1 increment by 1 nocache nocycle;
--kreiranje trigera za pracenje sekvence
create or replace trigger matches_match_id
before insert on matches
for each row
begin
  :new.match_id := match_id_seq.nextval;
end;

--kreiranje tabele standings
create table standings(
position int,
team_name varchar2(35) not null,
mp int,
won int,
lost int,
"PTS+" int,
"PTS-" int,
"+/-" int,
constraint pk_standings primary key (position)
);

--kreiranje sekvence za tabelu plasmana
create sequence standings_position start with 1 increment by 1 maxvalue 18 cycle cache 2;

--kreiranje trigera za poziciju u tabeli plasmana
create or replace trigger trg_stand_pos_seq
before insert or update on standings
for each row
begin
  if :new.position is null then
    :new.position := standings_position.nextval;
  end if;
end;

--procedura za izracunavanje pobeda, poraza itd...
create or replace procedure calculate_standings is
begin
 --Brisemo prethodne podatke sa delete:
    delete from standings;
    
    INSERT INTO standings (position, team_name, mp, won, lost, "PTS+", "PTS-", "+/-")
    SELECT 
        null, --row_number() OVER (ORDER BY count(*)) AS position,
        t.team_name,
        COUNT(m.match_id) AS mp,
        SUM(CASE WHEN m.home_team_id = t.team_id AND m.home_team_score > m.away_team_score THEN 1
                 WHEN m.away_team_id = t.team_id AND m.away_team_score > m.home_team_score THEN 1 ELSE 0 END) AS won,
        SUM(CASE WHEN m.home_team_id = t.team_id AND m.home_team_score < m.away_team_score THEN 1
                 WHEN m.away_team_id = t.team_id AND m.away_team_score < m.home_team_score THEN 1 ELSE 0 END) AS lost,
        SUM(CASE WHEN m.home_team_id = t.team_id THEN m.home_team_score ELSE m.away_team_score END) AS "PTS+",
        SUM(CASE WHEN m.home_team_id = t.team_id THEN m.away_team_score ELSE m.home_team_score END) AS "PTS-",
        SUM(case when m.home_team_id = t.team_id then m.home_team_score - m.away_team_score 
                 when m.away_team_id = t.team_id then m.away_team_score - m.home_team_score end) AS "+/-"
    FROM teams t 
    LEFT OUTER JOIN 
        matches m 
    ON 
        t.team_id = m.home_team_id OR t.team_id = m.away_team_id
      group by team_name
      order by won desc, lost asc,mp desc,"+/-" desc,"PTS+" desc,"PTS-" asc;

    COMMIT;
END calculate_standings;

begin
  calculate_standings;
end;

--kreiranje trigera za vracanje podataka u standings nakon brisanja utakmice
create or replace TRIGGER standings_after_delete
after delete on MATCHES
for each row
begin
  update standings
  set mp = mp - 1, 
  won = case when :old.home_team_score > :old.away_team_score and team_name = (select team_name from teams where team_id = :old.home_team_id) then won - 1
  when :old.home_team_score < :old.away_team_score and team_name = (select team_name from teams where team_id = :old.away_team_id) then won - 1
  else won
  end,
  lost = case when :old.home_team_score < :old.away_team_score and team_name = (select team_name from teams where team_id = :old.home_team_id) then lost - 1
  when :old.home_team_score > :old.away_team_score and team_name = (select team_name from teams where team_id = :old.away_team_id) then lost - 1
  else lost
  end,
  "PTS+" = case when team_name = (select team_name from teams where team_id = :old.home_team_id) then "PTS+" - :old.home_team_score
  when team_name = (select team_name from teams where team_id = :old.away_team_id) then "PTS+" - :old.away_team_score
  else "PTS+"
  end,
  "PTS-" = case when team_name = (select team_name from teams where team_id = :old.home_team_id) then "PTS-" - :old.away_team_score
  when team_name = (select team_name from teams where team_id = :old.away_team_id) then "PTS-"- :old.home_team_score
  else "PTS-"
  end,
  "+/-" = case when team_name = (select team_name from teams where team_id = :old.home_team_id) then "+/-" - (:old.home_team_score - :old.away_team_score)
  when team_name = (select team_name from teams where team_id = :old.away_team_id) then "+/-" - (:old.away_team_score - :old.home_team_score)
  else "+/-"
  end
  where team_name in (select team_name from teams where team_id = :old.home_team_id or team_id = :old.away_team_id);
end;

--kreiranje tabele players
create table players (
player_id int,
first_name varchar2(20) not null,
last_name varchar2(20),
position varchar2(2),
team_id int,
constraint pk_player_id primary key (player_id),
constraint fk_players foreign key (team_id) references teams (team_id)
);

--kreiranje tabele players_stat
create table players_stat (
player_stat_id int,
player_id int,
match_id int,
points int,
rebounds int,
assists int,
constraint pk_player_stat primary key (player_stat_id),
constraint fk_player_id foreign key (player_id) references players (player_id) on delete cascade,
constraint fk_match_id foreign key (match_id) references matches (match_id) on delete cascade,
constraint chk_stat_nn check (points >=0 and rebounds >=0 and assists >=0)
);

--kreiranje paketa za unos meceva i igraca
create or replace package match as 
  procedure result_match (p_round int,p_home_team varchar2,p_away_team varchar2,p_h_q1 int,p_a_q1 int,p_h_q2 int, 
  p_a_q2 int,p_h_q3 int,p_a_q3 int,p_h_q4 int,p_a_q4 int,p_h_e1 int default null,p_a_e1 int default null,
  p_h_e2 int default null,p_a_e2 int default null,p_h_e3 int default null,p_a_e3 int default null,p_h_e4 int default null,
  p_a_e4 int default null, p_match_date date);
  procedure stat_player (p_name varchar2,p_last_name varchar2,p_team varchar2,p_round int,p_points int,p_rebounds int,
  p_assists int);
end match;

create or replace package body match as
  --statistika meca
  procedure result_match (p_round int,p_home_team varchar2,p_away_team varchar2,p_h_q1 int,p_a_q1 int,p_h_q2 int, 
  p_a_q2 int,p_h_q3 int,p_a_q3 int,p_h_q4 int,p_a_q4 int,p_h_e1 int default null,p_a_e1 int default null,
  p_h_e2 int default null,p_a_e2 int default null,p_h_e3 int default null,p_a_e3 int default null,p_h_e4 int default null,
  p_a_e4 int default null, p_match_date date) is
  v_home_team_id int;
  v_away_team_id int;
  v_home_team varchar2(30);
  v_away_team varchar2(30);
  v_home_team_score int;
  v_away_team_score int;
begin
  select team_id into v_home_team_id from teams where upper(team_name) like upper('%'||p_home_team||'%');
  select team_id into v_away_team_id from teams where upper(team_name) like upper('%'||p_away_team||'%');

  select team_name into v_home_team from teams where upper(team_name) like upper('%'||p_home_team||'%');
  select team_name into v_away_team from teams where upper(team_name) like upper('%'||p_away_team||'%');

    v_home_team_score := p_h_q1 + p_h_q2 + p_h_q3 + p_h_q4 + coalesce(p_h_e1,0) + coalesce(p_h_e2,0) + coalesce(p_h_e3,0)
    + coalesce(p_h_e4,0);
    v_away_team_score := p_a_q1 + p_a_q2 + p_a_q3 + p_a_q4 + coalesce(p_a_e1,0) + coalesce(p_a_e2,0) + coalesce(p_a_e3,0)
    + coalesce(p_a_e4,0);

  if p_h_q1<0 or p_h_q2<0 or p_h_q3<0 or p_h_q4<0 or p_a_q1<0 or p_a_q2<0 or p_a_q3<0 or p_a_q4<0 or p_h_e1<0 or p_h_e2<0 
    or p_h_e3 <0 or p_h_e4<0 or p_a_e1<0 or p_a_e2<0 or p_a_e3<0 or p_a_e4<0 then
        dbms_output.put_line('Poeni po cetvrtinama ne mogu biti negativni brojevi!');
  end if;

  insert into matches (match_id, round, home_team_id, away_team_id, home_team_score, away_team_score, match_date)
  values (match_id_seq.nextval,p_round,v_home_team_id,v_away_team_id,v_home_team_score,v_away_team_score,p_match_date);
calculate_standings;
  dbms_output.put_line('Uspesno ste uneli podatke o mecu '''||v_home_team||' - '||v_away_team||''', za '''||p_round||'.'' rundu.');
  end result_match;
  
  --statistika igraca
  procedure stat_player (p_name varchar2,p_last_name varchar2,p_team varchar2,p_round int,p_points int,p_rebounds int,
  p_assists int) is
  v_counter int;
  v_pcounter int;
  v_player_id int;
  v_match_id int;
  v_team_name varchar2(30);
  v_team_id int;
  v_home varchar2(30);
  v_away varchar2(30);
  v_count int;
begin
  select team_name into v_team_name from teams where upper(team_name) like upper('%'||p_team||'%');
  select team_id into v_team_id from teams where team_name = v_team_name;  
    begin
      select player_id into v_player_id from players where (first_name = initcap(p_name) and
      last_name = initcap(p_last_name)) and team_id = v_team_id;
    exception
      when no_data_found then
        v_player_id := null;
   end;

  if (v_player_id is not null) then
    select match_id into v_match_id from matches where round = p_round and 
    (home_team_id = v_team_id or away_team_id = v_team_id);
    select team_name into v_home from teams join matches on teams.team_id=matches.home_team_id where match_id = v_match_id;
    select team_name into v_away from teams join matches on teams.team_id=matches.away_team_id where match_id = v_match_id;
    select count(*) into v_count from players_stat where match_id = v_match_id and player_id = v_player_id;
    
    if(v_count = 0) then
      select max(player_stat_id)+1 into v_counter from players_stat;
  
      insert into players_stat (player_stat_id, player_id, match_id, points, rebounds, assists) 
      values (v_counter,v_player_id,v_match_id,p_points,p_rebounds,p_assists);
      dbms_output.put_line('Uspesno ste uneli statistiku za igraca '''||initcap(p_name)||' '||initcap(p_last_name)||
      ''' za mec '''||v_home||' - '||v_away||'''.');
    else
      dbms_output.put_line('Statistika za igraca '''||initcap(p_name)||' '||initcap(p_last_name) ||''' za utakmicu '''||
      v_home||' - '||v_away||''' vec postoji!');
    end if;
    
  else
    select max(player_id)+1 into v_pcounter from players;
    if v_pcounter is null then
        v_pcounter := 1;
    end if;
  
  insert into players (player_id, first_name, last_name, position, team_id,start_date,end_date) 
  values (v_pcounter,initcap(p_name),initcap(p_last_name),null,v_team_id,TO_DATE('01/07/'||(extract(year from sysdate)-1),'dd/mm/yyyy'),to_date('01/01/99','dd/mm/yy'));
  dbms_output.put_line('Uspesno ste uneli igraca '''||initcap(p_name)||' '||initcap(p_last_name)||''' u tabelu igraca.');
  
  select player_id into v_player_id from players where first_name = initcap(p_name) and last_name = initcap(p_last_name) 
  and team_id = v_team_id;
  select match_id into v_match_id from matches where round = p_round and 
  (home_team_id = v_team_id or away_team_id = v_team_id);
  select team_name into v_home from teams join matches on teams.team_id=matches.home_team_id where match_id = v_match_id;
  select team_name into v_away from teams join matches on teams.team_id=matches.away_team_id where match_id = v_match_id;
  select max(player_stat_id)+1 into v_counter from players_stat;
    if v_counter is null then
        v_counter := 1;
    end if;
  
  insert into players_stat (player_stat_id, player_id, match_id, points, rebounds, assists) 
  values (v_counter,v_player_id,v_match_id,p_points,p_rebounds,p_assists);
  dbms_output.put_line('Uspesno ste uneli statistiku za igraca '''||initcap(p_name)||' '||initcap(p_last_name)||
  ''', za mec '''||v_home||' - '||v_away||'''.');
  end if;

exception
  when others then
    dbms_output.put_line('Doslo je do greske prilikom unosa podataka.');
  end stat_player;
  
end match;

alter table players add start_date date;
alter table players add end_date date;
update players
set start_date = to_date('01/07/22','dd/mm/yy'), end_date = to_date('01/01/2399','dd/mm/yyyy');

--Kreiranje pogleda za prosecnu statistiku igraca
create or replace view players_avg_stat
as
select p.first_name, p.last_name, t.team_name, count(ps.player_stat_id) as mp, round(avg(ps.points),1) 
as pts, round(avg(ps.assists),1) as ast, round(avg(ps.rebounds),1) as reb
from players p join teams t on p.team_id = t.team_id
join players_stat ps on p.player_id = ps.player_id
group by t.team_name, p.first_name, p.last_name
order by mp desc,pts desc,ast desc,reb desc;

--Kreiranje pogleda za statistiku timova
create or replace view teams_stat_matches
as
select t.team_name, count(m.match_id) as matches_played, 
sum(case when t.team_id = m.home_team_id then 1 else 0 end) as home_matches,
sum(case when t.team_id = m.away_team_id then 1 else 0 end) as away_matches, 
sum(case when t.team_id = m.home_team_id and m.home_team_score > m.away_team_score or 
t.team_id = m.away_team_id and m.home_team_score < m.away_team_score then 1 else 0 end) as number_wins,
sum(case when t.team_id = m.home_team_id and m.home_team_score > m.away_team_score then 1 else 0 end) as home_wins,
sum(case when t.team_id = m.away_team_id and m.home_team_score < m.away_team_score then 1 else 0 end) as away_wins
from teams t join matches m on t.team_id = m.home_team_id or t.team_id = m.away_team_id
group by t.team_name
order by matches_played desc, number_wins desc, home_wins desc;
