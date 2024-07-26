CREATE TABLE DIM_DATE (	
  DATUM_ID INT, 
	DATUM DATE, 
	GODINA INT, 
	MESEC INT, 
	DAN INT, 
  SEZONA VARCHAR2(10),
	NEDELJA INT, 
	KVARTAL INT, 
	POLUGODISTE INT, 
	NAZIV_MESECA VARCHAR2(20 BYTE), 
	DAN_U_NEDELJI VARCHAR2(11 BYTE), 
	BROJ_DANA_U_MESECU INT, 
	INDIKATOR_RADNOG_DANA CHAR(1 BYTE), 
	CONSTRAINT PK_DATUM_ID PRIMARY KEY (DATUM_ID)
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
CONSTRAINT FK_DATE_ID FOREIGN KEY (DATE_ID) REFERENCES DIM_DATE (DATUM_ID),
CONSTRAINT FK_PLAYER_ID FOREIGN KEY (PLAYER_ID) REFERENCES DIM_PLAYER (DIM_PLAYER_ID),
CONSTRAINT FK_TEAM_ID FOREIGN KEY (TEAM_ID) REFERENCES DIM_TEAM (DIM_TEAM_ID),
CONSTRAINT FK_MATCH_ID FOREIGN KEY (MATCH_ID) REFERENCES DIM_MATCH (DIM_MATCH_ID)
);

