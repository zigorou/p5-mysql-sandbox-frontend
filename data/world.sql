SET foreign_key_checks=0;

CREATE TABLE City (
  ID integer(11) NOT NULL auto_increment,
  Name char(35) NOT NULL DEFAULT '',
  CountryCode char(3) NOT NULL DEFAULT '',
  District char(20) NOT NULL DEFAULT '',
  Population integer(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (ID)
) ENGINE=MyISAM AUTO_INCREMENT=4080 DEFAULT CHARACTER SET latin1;

CREATE TABLE Country (
  Code char(3) NOT NULL DEFAULT '',
  Name char(52) NOT NULL DEFAULT '',
  Continent enum('Asia', 'Europe', 'North America', 'Africa', 'Oceania', 'Antarctica', 'South America') NOT NULL DEFAULT 'Asia',
  Region char(26) NOT NULL DEFAULT '',
  SurfaceArea float(10, 2) NOT NULL DEFAULT '0.00',
  IndepYear smallint(6) DEFAULT NULL,
  Population integer(11) NOT NULL DEFAULT '0',
  LifeExpectancy float(3, 1) DEFAULT NULL,
  GNP float(10, 2) DEFAULT NULL,
  GNPOld float(10, 2) DEFAULT NULL,
  LocalName char(45) NOT NULL DEFAULT '',
  GovernmentForm char(45) NOT NULL DEFAULT '',
  HeadOfState char(60) DEFAULT NULL,
  Capital integer(11) DEFAULT NULL,
  Code2 char(2) NOT NULL DEFAULT '',
  PRIMARY KEY (Code)
) ENGINE=MyISAM DEFAULT CHARACTER SET latin1;

CREATE TABLE CountryLanguage (
  CountryCode char(3) NOT NULL DEFAULT '',
  Language char(30) NOT NULL DEFAULT '',
  IsOfficial enum('T', 'F') NOT NULL DEFAULT 'F',
  Percentage float(4, 1) NOT NULL DEFAULT '0.0',
  PRIMARY KEY (CountryCode, Language)
) ENGINE=MyISAM DEFAULT CHARACTER SET latin1;

SET foreign_key_checks=1;


