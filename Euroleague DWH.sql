--Kreiranje potrebnih tabela
CREATE TABLE DIM_DATE (	
  DATE_ID INT, 
	"DATE" TIMESTAMP, 
	"YEAR" INT, 
	"MONTH" INT, 
	"DAY" INT, 
  SEASON VARCHAR2(10),
	WEEK INT, 
	QUARTER CHAR(2), 
	SEMESTER CHAR(2), 
	MONTH_NAME VARCHAR2(20 BYTE), 
	DAY_IN_WEEK VARCHAR2(11 BYTE), 
	NUMBER_DAY_IN_MONTH INT, 
	WORK_DAY_INDICATOR CHAR(1 BYTE), 
	CONSTRAINT PK_DATE_ID PRIMARY KEY (DATE_ID)
);
 
CREATE TABLE DIM_PLAYER (
DIM_PLAYER_ID INT,
PLAYER_ID INT,
PLAYER_NAME VARCHAR2(50),
TEAM_NAME VARCHAR2(30),
POSITION CHAR(2),
SEASON VARCHAR(10),
END_DATE DATE,
CURRENT_FLAG CHAR(1),
CONSTRAINT PK_DIM_PLAYER_ID PRIMARY KEY (DIM_PLAYER_ID)
);
create sequence dim_player_seq start with 1 increment by 1 nocache;

CREATE TABLE DIM_TEAM (
DIM_TEAM_ID INT,
TEAM_ID INT,
TEAM_NAME VARCHAR2(40),
COUNTRY_NAME VARCHAR2(25),
COACH_NAME VARCHAR2(30),
SEASON VARCHAR2(10),
END_DATE DATE,
CURRENT_FLAG CHAR(1),
CONSTRAINT PK_DIM_TEAM_ID PRIMARY KEY (DIM_TEAM_ID)
);
create sequence dim_team_seq start with 1 increment by 1 nocache;
/*
CREATE TABLE DIM_COACH (
DIM_COACH_ID INT,
COACH_ID INT,
COACH_NAME VARCHAR2(30),
TEAM_NAME VARCHAR2(30),
SEASON VARCHAR2(10),
END_DATE DATE,
CURRENT_FLAG CHAR(1),
CONSTRAINT PK_DIM_COACH_ID PRIMARY KEY (DIM_COACH_ID)
);
*/
CREATE TABLE DIM_MATCH (
DIM_MATCH_ID INT,
MATCH_ID INT,
HOME_TEAM VARCHAR2(25),
AWAY_TEAM VARCHAR2(25),
MATCH_DATE TIMESTAMP,
SEASON VARCHAR2(10),
CONSTRAINT PK_DIM_MATCH_ID PRIMARY KEY (DIM_MATCH_ID)
);
create sequence dim_match_seq start with 1 increment by 1 nocache;

CREATE TABLE FACT_PLAYER_STAT (
FACT_PLAYER_STAT_ID INT,
DATE_ID INT,
PLAYER_ID INT,
TEAM_ID INT,
MATCH_ID INT,
POINTS INT,
REBOUNDS INT,
ASSISTS INT,
HOME_TEAM_SCORE INT,
AWAY_TEAM_SCORE INT,
CONSTRAINT PK_FACT_PLAYER_STAT_ID PRIMARY KEY (FACT_PLAYER_STAT_ID),
CONSTRAINT FK_DATE_ID FOREIGN KEY (DATE_ID) REFERENCES DIM_DATE (DATE_ID),
CONSTRAINT FK_PLAYER_ID FOREIGN KEY (PLAYER_ID) REFERENCES DIM_PLAYER (DIM_PLAYER_ID),
CONSTRAINT FK_TEAM_ID FOREIGN KEY (TEAM_ID) REFERENCES DIM_TEAM (DIM_TEAM_ID),
CONSTRAINT FK_MATCH_ID FOREIGN KEY (MATCH_ID) REFERENCES DIM_MATCH (DIM_MATCH_ID)
);
create sequence fact_player_stat_seq start with 1 increment by 1 nocache;

--Provera podataka
SELECT TEAM_ID, COUNT(*)
FROM EVROLIGADWH.I$_DIM_TEAM
WHERE IND_UPDATE = 'I'
GROUP BY TEAM_ID
HAVING COUNT(*) > 1;

SELECT TEAM_ID, CURRENT_FLAG, END_DATE
FROM EVROLIGADWH.DIM_TEAM
WHERE CURRENT_FLAG = 1
AND END_DATE = TO_DATE('01-01-2400', 'mm-dd-yyyy');

alter table dim_player add start_date date;
alter table dim_player add end_date date;
alter table dim_player add current_flag char(1);

--Pregled pre unosa podataka
select dd.DATE_ID, dp.dim_player_id,dt.dim_team_id,dm.dim_match_id,ps.points,ps.rebounds,ps.assists,
m.home_team_score,m.away_team_score
from dim_date dd
join evroliga21.matches m on trunc(m.match_date) = trunc(dd."DATE")
left outer join dim_match dm on m.match_id = dm.match_id
left outer join evroliga21.players_stat ps on m.match_id = ps.match_id
left outer join dim_player dp on ps.player_id = dp.player_id
left outer join evroliga21.players p on dp.player_id = p.player_id
left outer join (SELECT dim_team_id,team_id FROM dim_team WHERE season = '2021/2022' AND
(team_id, dim_team_id) IN (SELECT team_id,MAX(dim_team_id)KEEP         
(DENSE_RANK LAST ORDER BY current_flag DESC, start_date DESC) AS dim_team_id FROM dim_team WHERE       
season = '2021/2022' GROUP BY team_id)) dt on p.team_id = dt.team_id
where dm.season = '2021/2022' and dp.season = '2021/2022' 
and dd.season = '2021/2022'
order by dd.DATE_ID,dm.dim_match_id,dp.dim_player_id,dt.dim_team_id,points desc;

--Unos statistike igraca 2021/2022
insert into fact_player_stat select fact_player_stat_seq.nextval, dd.DATE_ID, dp.dim_player_id,dt.dim_team_id,dm.dim_match_id,ps.points,ps.rebounds,ps.assists,
m.home_team_score,m.away_team_score
from dim_date dd
join evroliga21.matches m on trunc(m.match_date) = trunc(dd."DATE")
left outer join dim_match dm on m.match_id = dm.match_id
left outer join evroliga21.players_stat ps on m.match_id = ps.match_id
left outer join dim_player dp on ps.player_id = dp.player_id
left outer join evroliga21.players p on dp.player_id = p.player_id
left outer join (SELECT dim_team_id,team_id FROM dim_team WHERE season = '2021/2022' AND
(team_id, dim_team_id) IN (SELECT team_id,MAX(dim_team_id)KEEP         
(DENSE_RANK LAST ORDER BY current_flag DESC, start_date DESC) AS dim_team_id FROM dim_team WHERE       
season = '2021/2022' GROUP BY team_id)) dt on p.team_id = dt.team_id
where dm.season = '2021/2022' and dp.season = '2021/2022' 
and dd.season = '2021/2022'
order by dd.DATE_ID,dm.dim_match_id,dp.dim_player_id,dt.dim_team_id,points desc;

--Unos statistike igraca 2022/2023
insert into fact_player_stat select fact_player_stat_seq.nextval, dd.DATE_ID, dp.dim_player_id,dt.dim_team_id,dm.dim_match_id,ps.points,ps.rebounds,ps.assists,
m.home_team_score,m.away_team_score
from dim_date dd
join evroliga22.matches m on trunc(m.match_date) = trunc(dd."DATE")
left outer join dim_match dm on m.match_id = dm.match_id
left outer join evroliga22.players_stat ps on m.match_id = ps.match_id
left outer join dim_player dp on ps.player_id = dp.player_id
left outer join evroliga22.players p on dp.player_id = p.player_id
left outer join (SELECT dim_team_id,team_id FROM dim_team WHERE season = '2022/2023' AND
(team_id, dim_team_id) IN (SELECT team_id,MAX(dim_team_id)KEEP         
(DENSE_RANK LAST ORDER BY current_flag DESC, start_date DESC) AS dim_team_id FROM dim_team WHERE       
season = '2022/2023' GROUP BY team_id)) dt on p.team_id = dt.team_id
where dm.season = '2022/2023' and dp.season = '2022/2023' 
and dd.season = '2022/2023'
order by dd.DATE_ID,dm.dim_match_id,dp.dim_player_id,dt.dim_team_id,points desc;

--Pregled statistike igraca
select p.player_name as Player_Name,f.points
as Points,f.assists as Assists,f.rebounds 
as Rebounds,t.team_name,m.home_team,m.away_team,f.home_team_score,f.away_team_score,trunc("DATE") as Match_Date,d.season
from fact_player_stat f
join dim_player p on p.dim_player_id = f.player_id
join dim_team t on t.dim_team_id = f.team_id
join dim_match m on m.dim_match_id = f.match_id
join dim_date d on d.date_id = f.date_id
order by Player_Name,Team_Name,Points desc, Assists desc;

--Kreiranje cinjenicne tabele za statistiku timova
create table fact_team_stat (
fact_team_stat_id int,
date_id int,
team_id int,
match_id int,
home_team_score int,
away_team_score int,
constraint pk_fact_team primary key (fact_team_stat_id),
constraint fk_fteam_dateid foreign key (date_id) references dim_date (date_id),
constraint fk_fteam_teamid foreign key (team_id) references dim_team (dim_team_id),
constraint fk_fteam_matchid foreign key (match_id) references dim_match(dim_match_id)
);
create sequence fact_team_stat_seq start with 1 increment by 1 nocache;

--Provera podataka
insert into fact_team_stat (fact_team_stat_id, date_id, team_id, match_id, home_team_score, away_team_score)
select 
    fact_team_stat_seq.nextval,
    date_id,
    team_id,
    match_id,
    home_team_score,
    away_team_score
from (
    select distinct date_id, team_id, match_id, home_team_score, away_team_score
    from fact_player_stat
) fts;

select max(dim_team_id) from dim_team where season = '2021/2022' group by team_name;

select dd.date_id,dt.dim_team_id,dm.dim_match_id,m.home_team_score,m.away_team_score
from evroliga21.matches m left outer join dim_match dm on m.match_id = dm.match_id 
and m.match_date = dm.match_date left outer join (select max(team_id)as team_id,max(dim_team_id)as dim_team_id,team_name,season
from dim_team where season = '2021/2022' group by team_name,season)dt
on dm.home_team = dt.team_name or dm.away_team = dt.team_name
left outer join dim_date dd on trunc(dd."DATE") = trunc(dm.match_date) and 
trunc(dd."DATE") = trunc(m.match_date);

select dd.date_id,dt.dim_team_id,dm.dim_match_id,m.home_team_score,m.away_team_score
from evroliga23.matches m left outer join dim_match dm on m.match_id = dm.match_id 
and m.match_date = dm.match_date left outer join (select max(team_id)as team_id,max(dim_team_id)as dim_team_id,team_name,season
from dim_team where season = '2023/2024' group by team_name,season)dt
on dm.home_team = dt.team_name or dm.away_team = dt.team_name
left outer join dim_date dd on trunc(dd."DATE") = trunc(dm.match_date) and 
trunc(dd."DATE") = trunc(m.match_date)
order by dm.dim_match_id,dt.dim_team_id;

--Brisanje podataka iz tabela (ciscenje tabela)
truncate table fact_player_stat;
truncate table fact_team_stat;
truncate table dim_date;
truncate table dim_team;
truncate table dim_match;
truncate table dim_player;

--Kreiranje pogleda za prosecnu statistiku igraca na osnovu svih sezona
create or replace view players_avg_stat_all_seasons
as
select dp.player_name,dt.team_name,count(distinct dp.season)as seasons_played,
count(fp.player_id)as matches_played,round(avg(fp.points),1) as avg_pts,
round(avg(fp.assists),1)as avg_ast,round(avg(fp.rebounds),1)as avg_reb
from fact_player_stat fp join dim_player dp on fp.player_id = dp.dim_player_id
join dim_team dt on fp.team_id = dt.dim_team_id
group by dp.player_name,dt.team_name
order by seasons_played desc,matches_played desc,avg_pts desc,avg_ast desc,avg_reb desc;