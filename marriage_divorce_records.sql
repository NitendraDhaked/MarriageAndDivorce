-- MySQL Script 
-- 05/07/17 12:55:01
-- Version: 1.0
-- Author: Nitendra Singh Dhaked
-- Student Id: 16203776

-- Some insert statements will not follw the foreign key constratint will 
-- appear in mysql command line

-- -----------------------------------------------------
-- Schema marriage_divorce_records
-- Schema is not exist than create the schema
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `marriage_divorce_records` DEFAULT CHARACTER SET utf8 ;
USE `marriage_divorce_records` ;

-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`country_marriage_rules`
-- This purpose of this table is to handle polygamy, monogamy, 
-- same sex marriage case should be handled according to country.
-- -----------------------------------------------------
CREATE TABLE country_marriage_rules(
country_id varchar(3) not null,
country_name varchar(40) not null,
male_age_limit int(3) not null,
female_age_limit int(3) not null,
age_limit_others int(3) not null,
polygamy boolean not null,
same_sex_marriage boolean not null,
PRIMARY KEY (country_id)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`city_info`
-- -----------------------------------------------------

CREATE TABLE city_info(
city_id int NOT NULL AUTO_INCREMENT, 
city varchar(30),
state varchar(30),
country_code varchar(3),
primary key (city_id),
foreign key (country_code) references country_marriage_rules(country_id)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`salutations`
-- -----------------------------------------------------
 CREATE TABLE salutations(
 salutation_id int(2) NOT NULL,
 salutation VARCHAR(10),
 primary key(salutation_id)
 )ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`gender`
-- -----------------------------------------------------
CREATE TABLE gender(
gender_code int(2) NOT NULL,
description VARCHAR(20),
primary key(gender_code)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`religion`
-- -----------------------------------------------------
CREATE TABLE religion(
religion_code int(2) NOT NULL,
religion_desc VARCHAR(20),
primary key(religion_code)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`marital_status`
-- -----------------------------------------------------
CREATE TABLE marital_status(
marital_status_code int(2),
marital_status VARCHAR(15),
primary key(marital_status_code)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`person`
-- 7.	All the information like number of marriage count, is_alive status, 
-- marital status, person occupation, religion can easily access from this table.
-- -----------------------------------------------------
CREATE TABLE person(
unique_identity int NOT NULL AUTO_INCREMENT, 
salutation_code int(2),
person_first_name VARCHAR(30) NOT NULL,
gender_code int(2),
date_of_birth DATE NOT NULL,
nationality VARCHAR(50) NOT NULL,
passport_no VARCHAR(15) NOT NULL,
religion_code int(2),
marital_status_code int(2),
is_alive boolean,
current_no_marriage int(2) not null default 0,
PRIMARY KEY (unique_identity),
UNIQUE KEY (passport_no,nationality),
foreign key (salutation_code) references salutations(salutation_id),
foreign key (gender_code) references gender(gender_code),
foreign key (religion_code) references religion(religion_code),
foreign key (marital_status_code) references marital_status(marital_status_code)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`address`
-- -----------------------------------------------------
CREATE TABLE address(
address_id int NOT NULL AUTO_INCREMENT, 
person_id int,
house_number varchar(15),
street Varchar(50),
city_info_id int NOT NULL,
zipcode varchar(15),
PRIMARY KEY (address_id),
foreign key (city_info_id) references city_info(city_id),
foreign key (person_id) references person(unique_identity)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`marriage`
-- -----------------------------------------------------
CREATE TABLE marriage(
umcn int NOT NULL AUTO_INCREMENT,
partner1_uid int, 
partner2_uid int,
place_of_marriage varchar(40) NOT NULL,
date_of_wedding date NOT NULL,
marriage_country_code varchar(3) NOT NULL,
PRIMARY KEY (umcn),
foreign key (partner1_uid) references person(unique_identity),
foreign key (partner2_uid) references person(unique_identity),
foreign key (marriage_country_code) references country_marriage_rules(country_id)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`divorce`
-- This table has all the marriage records with unique identity to avoid 
-- false marriages with the help of this table we can find the person marriage
-- date and place of marriage and how many times partners got married. 
-- -----------------------------------------------------
CREATE TABLE divorce(
decree_Number int NOT NULL AUTO_INCREMENT,
partner1_uid int, 
partner2_uid int,
marriage_end_date DATE NOT NULL,
umcn int,
place_of_divorce varchar(40) NOT NULL,
divorce_country_code varchar(3) NOT NULL,
PRIMARY KEY (decree_Number),
foreign key (partner1_uid) references person(unique_identity),
foreign key (partner2_uid) references person(unique_identity),
foreign key (umcn) references marriage(umcn),
foreign key (divorce_country_code) references country_marriage_rules(country_id),
unique key(umcn)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`person_death_record`
-- This table is generalized from person table because every person 
-- doesn’t have death of end, so it is better to store date of death
-- separately and update the person is_live and marital_status.
-- -----------------------------------------------------
CREATE TABLE person_death_record(
death_record_id int NOT NULL AUTO_INCREMENT,
unique_identity int,
date_of_death date not null,
cause_of_death varchar(30),
PRIMARY KEY (death_record_id),
unique key(unique_identity),
foreign key (unique_identity) references person(unique_identity)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Table `marriage_divorce_records`.`person_last_name`
-- -----------------------------------------------------
create table person_last_name(
unique_identity int NOT NULL,
last_name varchar(40),
primary key(unique_identity),
foreign key (unique_identity) references person(unique_identity)
)ENGINE=INNODB;


-- -----------------------------------------------------
-- Trigger for person table 
-- Person Before Insert validate all records before inserting into table
-- -----------------------------------------------------
delimiter //
CREATE TRIGGER person_BEFORE_INSERT BEFORE INSERT ON person
FOR EACH ROW
BEGIN

IF (NEW.date_of_birth>CURDATE())
THEN
SIGNAL SQLSTATE '45001'
SET MESSAGE_TEXT = "Invalid date of birth";
END IF;
END//
delimiter //
-- -----------------------------------------------------
-- Trigger for marriage table 
-- Marriage Before Insert validate all records before inserting into table
-- Person age is greater than or equal to required age for marriage according to country
-- Partner’s id is not equal
-- Check person is alive or not
-- Partners can’t marry twice before divorce.
-- Check same sex is allowed or not in country where marriage took place
-- Check polygamy is allowed or not in country
-- -----------------------------------------------------
delimiter //
CREATE TRIGGER marriage_BEFORE_INSERT BEFORE INSERT ON marriage
FOR EACH ROW
BEGIN

DECLARE p1_isAlive BOOLEAN;
DECLARE p2_isAlive BOOLEAN;
DECLARE dob_p1 DATE;
DECLARE dob_p2 DATE;
DECLARE polyStatus BOOLEAN;
DECLARE sameSexMrg BOOLEAN;
DECLARE curAgeP1 INT(3);
DECLARE curAgeP2 INT(3);
DECLARE maleAge INT(3);
DECLARE femaleAge INT(3);
DECLARE otherAge INT(3);
DECLARE p1Gender INT(2);
DECLARE p2Gender INT(2);
DECLARE mSCodeP1 INT(2);
DECLARE mSCodeP2 INT(2);
DECLARE marriageCnt INT(2);
DECLARE divoceCnt INT(2);

SELECT 
    is_alive, date_of_birth, gender_code, marital_status_code
INTO p1_isAlive , dob_p1 , p1Gender , mSCodeP1 FROM
    person
WHERE
    unique_identity = NEW.partner1_uid;

SELECT 
    is_alive, date_of_birth, gender_code, marital_status_code
INTO p2_isAlive , dob_p2 , p2Gender , mSCodeP2 FROM
    person
WHERE
    unique_identity = NEW.partner2_uid;

SELECT 
    polygamy,
    same_sex_marriage,
    male_age_limit,
    female_age_limit,
    age_limit_others
INTO polyStatus , sameSexMrg , maleAge , femaleAge , otherAge FROM
    country_marriage_rules
WHERE
    country_id = NEW.marriage_country_code;

SELECT ROUND(DATEDIFF(CURDATE(), dob_p1) / 365) INTO curAgeP1;
SELECT ROUND(DATEDIFF(CURDATE(), dob_p2) / 365) INTO curAgeP2;

SELECT 
    COUNT(*)
INTO marriageCnt FROM
    marriage
WHERE
    (partner1_uid = new.partner1_uid
        OR partner1_uid = new.partner2_uid)
        AND (partner2_uid = new.partner1_uid
        OR partner2_uid = new.partner2_uid);

SELECT 
    COUNT(*)
INTO divoceCnt FROM
    divorce
WHERE
    (partner1_uid = new.partner1_uid
        OR partner1_uid = new.partner2_uid)
        AND (partner2_uid = new.partner1_uid
        OR partner2_uid = new.partner2_uid);

IF (marriageCnt > divoceCnt)
THEN
SIGNAL SQLSTATE '46001'
SET MESSAGE_TEXT = "Already married to the same person";
END IF;

IF (!p1_isAlive OR !p2_isAlive)
THEN
SIGNAL SQLSTATE '46002'
SET MESSAGE_TEXT = "Partner is not alive";
END IF;

IF (new.partner1_uid = new.partner2_uid)
THEN
SIGNAL SQLSTATE '46003'
SET MESSAGE_TEXT = "Partners Id should not be equal";
END IF;

IF ((mSCodeP1 = 1 OR mSCodeP2 = 1) and !polyStatus )
THEN
SIGNAL SQLSTATE '46004'
SET MESSAGE_TEXT = "Polygamy is not allowed in selected country";
END IF;


IF (!sameSexMrg AND (p1Gender=p2Gender))
THEN
SIGNAL SQLSTATE '46005'
SET MESSAGE_TEXT = "Same sex marriage is not allowed";
END IF;

IF (((p1Gender=0 AND curAgeP1<maleAge) OR (p1Gender=0 AND curAgeP2<maleAge)) 
	OR ((p1Gender=1 AND curAgeP1<femaleAge) OR (p1Gender=1 AND curAgeP2<femaleAge))
    OR ((p1Gender=2 AND curAgeP1<otherAge) OR (p1Gender=2 AND curAgeP2<otherAge)))
THEN
SIGNAL SQLSTATE '46006'
SET MESSAGE_TEXT = "Partner Age is less than the legal marriage age";
END IF;
END;//
delimiter ;

-- -----------------------------------------------------
-- Trigger for marriage table 
-- Marriage After Insert update marital_status_code and current_no_marriage
-- -----------------------------------------------------
delimiter //
CREATE TRIGGER marriage_AFTER_INSERT AFTER INSERT ON marriage
FOR EACH ROW
BEGIN

UPDATE person
SET marital_status_code=1, current_no_marriage=current_no_marriage + 1
WHERE unique_identity=NEW.partner1_uid
OR unique_identity=NEW.partner2_uid;

END;//
delimiter ;

-- -----------------------------------------------------
-- Trigger for divorce table 
-- Divorce Before Insert
-- Check both partners are alive and their id is not equal
-- Only valid married partners are allowed for divorce
-- Check both person belongs to legal marriage number
-- Divorce date must be valid, it can’t be future date or not before marriage date.
-- -----------------------------------------------------
delimiter //
CREATE TRIGGER divorce_BEFORE_INSERT BEFORE INSERT ON divorce
FOR EACH ROW
BEGIN
DECLARE p1_isAlive boolean;
DECLARE p2_isAlive boolean;
DECLARE recentPartner boolean;
DECLARE mrgDate date;

SELECT 
    is_alive
INTO p1_isAlive FROM
    person
WHERE
    unique_identity = NEW.partner1_uid;

SELECT 
    is_alive
INTO p2_isAlive FROM
    person
WHERE
    unique_identity = NEW.partner1_uid;

IF (!p1_isAlive OR !p2_isAlive)
THEN
SIGNAL SQLSTATE '47001'
SET MESSAGE_TEXT = "One of the Partners is Not Alive";
END IF;

IF (new.partner1_uid = new.partner2_uid)
THEN
SIGNAL SQLSTATE '47002'
SET MESSAGE_TEXT = "Partners Id can not be equal";
END IF;

SELECT 
    MAX(umcn), date_of_wedding
INTO recentPartner , mrgdate FROM
    marriage
WHERE
    (partner1_uid = NEW.partner1_uid
        AND partner2_uid = NEW.partner2_uid)
        OR (partner1_uid = NEW.partner2_uid
        AND partner2_uid = NEW.partner1_uid);

IF (recentPartner <> NEW.umcn)
THEN
SIGNAL SQLSTATE '47003'
SET MESSAGE_TEXT = "Invalid Marriage record number of selected partner";
END IF;

IF (mrgdate > NEW.marriage_end_date or CURDATE()<NEW.marriage_end_date)
THEN
SIGNAL SQLSTATE '47004'
SET MESSAGE_TEXT = "Divorce date is not valid";
END IF;

END;//
delimiter ;

-- -----------------------------------------------------
-- Trigger for divorce table 
-- Divorce After Insert update marital_status_code and current_no_marriage
-- -----------------------------------------------------
delimiter //
CREATE TRIGGER divorce_AFTER_INSERT AFTER INSERT ON divorce
FOR EACH ROW
BEGIN

UPDATE person
SET marital_status_code=3, current_no_marriage=current_no_marriage-1
WHERE unique_identity=NEW.partner1_uid
OR unique_identity=NEW.partner2_uid;

END;//
delimiter ;


-- -----------------------------------------------------
-- Trigger for person_death_record table 
-- person_death_record Before Insert
--	Invalid date of death is not allowed
-- Date before birth and future date is not allowed.
-- Person could not die again
-- Person record must be present in person table.
-- -----------------------------------------------------
delimiter //
CREATE TRIGGER person_death_record_BEFORE_INSERT BEFORE INSERT ON person_death_record
FOR EACH ROW
BEGIN

DECLARE p1_isAlive boolean;
DECLARE dob_p1 DATE;

SELECT 
    is_alive, date_of_birth
INTO p1_isAlive , dob_p1 FROM
    person
WHERE
    unique_identity = NEW.unique_identity;

IF ( CURDATE()<NEW.date_of_death)
THEN
SIGNAL SQLSTATE '48001'
SET MESSAGE_TEXT = "Death date is not valid";
END IF;

IF (!p1_isAlive )
THEN
SIGNAL SQLSTATE '48002'
SET MESSAGE_TEXT = "The person is already dead";
END IF;

IF(NEW.date_of_death<dob_p1)
THEN SIGNAL SQLSTATE '48003'
SET MESSAGE_TEXT = "Person Cannot Die before Birth";
END IF;

END;//
delimiter ;

-- -----------------------------------------------------
-- Trigger for person_death_record table 
-- person_death_record After Insert
-- Find all the records which is currently associated with person who is married and alive.
-- Update the partners marital status married to widowed if they are not married to another person.
-- Update person status is_alive false.
-- -----------------------------------------------------
delimiter //
CREATE TRIGGER person_death_record_AFTER_INSERT AFTER INSERT ON person_death_record
FOR EACH ROW
BEGIN
UPDATE person 
SET 
    current_no_marriage = current_no_marriage - 1
WHERE
    unique_identity IN (SELECT 
            unique_identity
        FROM
            (SELECT 
                unique_identity
            FROM
                person
            WHERE
                unique_identity IN (SELECT 
                        partner1_uid
                    FROM
                        marriage
                    WHERE
                        partner2_uid = new.unique_identity UNION ALL SELECT 
                        partner2_uid
                    FROM
                        marriage
                    WHERE
                        partner1_uid = new.unique_identity)
                    AND is_alive = TRUE
                    AND marital_status_code = 1
                    AND unique_identity NOT IN (SELECT 
                        partner1_uid
                    FROM
                        divorce
                    WHERE
                        partner2_uid = new.unique_identity UNION ALL SELECT 
                        partner2_uid
                    FROM
                        divorce
                    WHERE
                        partner1_uid = new.unique_identity)) AS t);
 
UPDATE person 
SET 
    marital_status_code = 2
WHERE
    unique_identity IN (SELECT 
            unique_identity
        FROM
            (SELECT 
                unique_identity
            FROM
                person
            WHERE
                unique_identity IN (SELECT 
                        partner1_uid
                    FROM
                        marriage
                    WHERE
                        partner2_uid = new.unique_identity UNION ALL SELECT 
                        partner2_uid
                    FROM
                        marriage
                    WHERE
                        partner1_uid = new.unique_identity)
                    AND is_alive = TRUE
                    AND marital_status_code = 1
                    AND unique_identity NOT IN (SELECT 
                        partner1_uid
                    FROM
                        divorce
                    WHERE
                        partner2_uid = new.unique_identity UNION ALL SELECT 
                        partner2_uid
                    FROM
                        divorce
                    WHERE
                        partner1_uid = new.unique_identity)
                    AND current_no_marriage = 0) AS t);

 
UPDATE person 
SET 
    is_alive = FALSE
WHERE
    unique_identity = NEW.unique_identity;

END;//
delimiter ;


-- -----------------------------------------------------
-- Insert records in all base tables
-- base tables are the fixed tables which is like drop down on the web page
-- These tables is creted to avoid garble data in database
-- -----------------------------------------------------
INSERT INTO marital_status VALUES (0,"single");
INSERT INTO marital_status VALUES (1,"married");
INSERT INTO marital_status VALUES (2,"widowed");
INSERT INTO marital_status VALUES (3,"divorced");

insert into religion values (0,'Athiesm');
insert into religion values (1,'Christianity');
insert into religion values (2,'Islam');
insert into religion values (3,'Hinduism');
insert into religion values (4,'Buddhism');
insert into religion values (5,'Sikhism');
insert into religion values (6,'Other');
 
insert into salutations values (0,'');
insert into salutations values (1,'Ms');
insert into salutations values (2,'Mr');
insert into salutations values (3,'Mrs');
insert into salutations values (4,'Dr');
insert into salutations values (5,'Prof');
insert into salutations values (6,'Er');

INSERT INTO country_marriage_rules VALUES ("ind","india",21,18,18,true,false);
INSERT INTO country_marriage_rules VALUES ("irl","ireland",21,18,18,false,true);
INSERT INTO country_marriage_rules VALUES ("usa","united states",21,18,18,true,true);
INSERT INTO country_marriage_rules VALUES ("jpn","japan",21,18,18,false,true);
INSERT INTO country_marriage_rules VALUES ("de","germany",21,18,18,true,false);
INSERT INTO country_marriage_rules VALUES ("chn","china",21,18,18,false,false);
INSERT INTO country_marriage_rules VALUES ("pak","pakistan",18,15,15,true,false);

INSERT INTO gender VALUES (0,"male");
INSERT INTO gender VALUES (1,"female");
INSERT INTO gender VALUES (2,"others");

INSERT INTO city_info VALUES (0,"dublin","leinster","irl");
INSERT INTO city_info VALUES (0,"pune","maharashtra","ind");
INSERT INTO city_info VALUES (0,"beijing","beijing","chn");
INSERT INTO city_info VALUES (0,"tokyo","kanto","jpn");
INSERT INTO city_info VALUES (0,"berlin","bavaria","de");

-- -----------------------------------------------------
-- Table which takes person all necessary details 
-- Most of the fields are like dropdown kind fields, so there value is integer code.
-- -----------------------------------------------------
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,0,"Vinay",0,"1994-03-26","Indian","J216642",3,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,2,"Angelina",0,"1984-02-28","Russian","R215426",1,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,2,"Abel",0,"2000-03-25","German","G216356",1,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,2,"Alastair",0,"2000-03-15","German","J216386",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,0,"Xang",1,"1994-03-28","Chinese","C2168656",5,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,0,"Bojongsu",1,"2000-03-21","Chinese","C2165489",0,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,5,"Abubakr",0,"1994-04-20","Afghani","A216456",5,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,6,"Kagchi",0,"1993-07-16","Japanese","S234457",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,6,"Vaseem",0,"1993-07-13","Pakistani","P234763",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,6,"Prateek",0,"1993-07-16","Indian","J234457",3,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,
date_of_birth,nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,2,"Andrew",2,"2000-07-16","Ireland","H234425",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,2,"Seamus",2,"2000-07-31","Ireland","H134435",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,2,"Abraham",0,"1993-07-16","American","K234477",2,1,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,6,"Hilponus",0,"1990-04-21","Japanese","S234687",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,6,"Satish",0,"1987-08-25","Indian","J234877",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,5,"Xangli",0,"1987-02-06","Chinese","C234834",5,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,4,"Albert",0,"1985-09-30","German","G234859",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,6,"Abdu",0,"1995-05-17","African","K239959",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,3,"Alexandar",0,"2004-07-16","Russian","R232359",2,0,true);
INSERT INTO person (unique_identity,salutation_code,person_first_name,gender_code,date_of_birth,
nationality,passport_no,religion_code,marital_status_code,is_alive) VALUES(0,2,"Akira",0,"2005-02-26","Japanese","S232009",5,0,true);

-- -----------------------------------------------------
-- Vlaidate marriage records
-- Only few marriage record is valid for insertion
-- -----------------------------------------------------
INSERT INTO marriage VALUES(0,1,2,"Temple","2016-05-16","ind");
INSERT INTO marriage VALUES(0,1,1,"Temple","2016-05-16","ind");
INSERT INTO marriage VALUES(0,1,21,"Temple","2016-05-16","ind");
INSERT INTO marriage VALUES(0,1,5,"Temple","2016-05-16","ind");
INSERT INTO marriage VALUES(0,1,6,"Temple","2016-05-16","ind");
INSERT INTO marriage VALUES(0,1,7,"Temple","2016-05-16","irl");
INSERT INTO marriage VALUES(0,1,5,"Temple","2016-05-16","irl");
INSERT INTO marriage VALUES(0,2,15,"Temple","2016-05-16","irl");
INSERT INTO marriage VALUES(0,7,15,"Temple","2016-05-16","irl");


-- -----------------------------------------------------
-- Vlaidate divorce records
-- -----------------------------------------------------
insert into divorce values(0,1,5,"2018-05-17",3,"church","ind");
insert into divorce values(0,1,5,"2018-05-17",1,"church","ind");
insert into divorce values(0,1,5,"2015-05-17",1,"church","ind");
insert into divorce values(0,1,1,"2016-08-17",1,"church","ind");
insert into divorce values(0,7,15,"2015-05-17",5,"church","ind");

-- -----------------------------------------------------
-- Vlaidate death records
-- -----------------------------------------------------
insert into person_death_record values(0,22,"2017-05-07","accident");
insert into person_death_record values(0,18,"1994-05-08","accident");
insert into person_death_record values(0,18,"2017-05-07","accident");
insert into person_death_record values(0,18,"2017-05-07","accident");