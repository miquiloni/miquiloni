DROP USER 'miquiloni'@'localhost';

CREATE USER 'miquiloni'@'localhost' IDENTIFIED BY 'MYSQL_PASSWD';

DROP DATABASE miquiloni;

CREATE DATABASE IF NOT EXISTS miquiloni CHARACTER SET 'UTF8' COLLATE 'utf8_general_ci';

use miquiloni;

GRANT ALL PRIVILEGES ON miquiloni.* TO 'miquiloni'@'localhost' IDENTIFIED BY 'MYSQL_PASSWD' WITH GRANT OPTION;

FLUSH PRIVILEGES;



DROP TABLE IF EXISTS users;

CREATE TABLE IF NOT EXISTS users (
	idUser int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	username varchar(40) UNIQUE NOT NULL,
	password varchar(64) NOT NULL,
	name varchar(40) NULL,
	lastName varchar(40) NULL,
	mothersLastName varchar(40) NULL,
	idEmployee varchar(40) NULL,
	email varchar(60) NULL,
	secondaryEmail varchar(60) NULL,
	phone varchar(40) NULL,
	secondaryPhone varchar(40) NULL,
	costCenterId int(11) NULL,
	groupId int(11) NULL,
	secondaryGroupId int(11) NULL,
	theme varchar(30) DEFAULT 'classic_cloud',
	language varchar(10) DEFAULT 'en_US',
	active int(1) DEFAULT '1'
) ENGINE=InnoDB CHARACTER SET=utf8;

INSERT INTO users (idUser, username, password, name, lastName) VALUES ('1', 'admin', 'ADMIN_PASSWD', 'Hugo', 'Maza');
INSERT INTO users (idUser, username, password) VALUES ('2', 'Guest', '');



DROP TABLE IF EXISTS permissions;

CREATE TABLE IF NOT EXISTS permissions (
	idPermission int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	idUser int(11) UNIQUE NOT NULL,
	init int(1) DEFAULT '1',
	overview int(1) DEFAULT '1',
	settings int(1) DEFAULT '1',
	docs int(1) DEFAULT '1',
	lxcservers int(1) DEFAULT '0',
	lxcservers_edit int(1) DEFAULT '0',
	provisioning int(1) DEFAULT '0',
	accounts int(1) DEFAULT '0',
	accounts_edit int(1) DEFAULT '0',
	containers int(1) DEFAULT '0',
	containers_edit int(1) DEFAULT '0',
	sectors int(1) DEFAULT '0',
	migration int(1) DEFAULT '0',
	keypairs int(1) DEFAULT '0',
	distros int(1) DEFAULT '0'
) ENGINE=InnoDB;

INSERT INTO permissions (idUser, lxcservers, lxcservers_edit, provisioning, accounts, accounts_edit, containers, containers_edit, sectors, migration, keypairs, distros) 
VALUES ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1');
INSERT INTO permissions (idUser, init, overview, settings) VALUES ('2', '0', '0', '0');



DROP TABLE IF EXISTS sector;

CREATE TABLE IF NOT EXISTS sector (
	idSector int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	sectorName varchar(60),
	description varchar(255),
	UTCtimeZone varchar(6),
	UTCDSTtimeZone varchar(6)
) ENGINE=InnoDB;

INSERT INTO sector (sectorName, description, UTCtimeZone, UTCDSTtimeZone) VALUES ('PROD', 'Production Sector', '-06:00', '-05:00');
INSERT INTO sector (sectorName, description, UTCtimeZone, UTCDSTtimeZone) VALUES ('QA', 'Quality Assurance Sector', '-06:00', '-05:00');
INSERT INTO sector (sectorName, description, UTCtimeZone, UTCDSTtimeZone) VALUES ('DEV', 'Development Sector', '-06:00', '-05:00');



DROP TABLE IF EXISTS lxcservers;

CREATE TABLE IF NOT EXISTS lxcservers (
	idServer int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	hostName varchar(40) UNIQUE NOT NULL,
	IPv4 varchar(15) NOT NULL,
	IPv6 varchar(40),
	memory decimal(20, 2),
	cpus int(3),
	cpuMake varchar(10),
	cpuModel varchar(20),
	cpuSpeed decimal(7, 2),
	privateKey varchar(255),
	createContainersMode varchar(14) DEFAULT 'All',
	storageProvisioningMode varchar(5) DEFAULT 'LVM',
	shortDescription varchar(60),
	idSector int(11),
	creationDate timestamp
) ENGINE=InnoDB;



DROP TABLE IF EXISTS cpus;

CREATE TABLE IF NOT EXISTS cpus (
    idRecord int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    idServer int(11) NOT NULL,
    cpuId int(3) NOT NULL,
    cpuQuarter int(1) NOT NULL,
    idContainer int(11) DEFAULT NULL
) ENGINE=InnoDB;



DROP TABLE IF EXISTS containers;

CREATE TABLE IF NOT EXISTS containers (
	idContainer int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	idServer int(11) NOT NULL,
	containerName varchar(40) NOT NULL,
	hostName varchar(40),
	template_ varchar(40) DEFAULT 'download',
	distribution varchar(20) DEFAULT 'centos',
	release_ varchar(20) DEFAULT '7',
	architecture varchar(6) DEFAULT 'amd64',
	variant varchar(20) DEFAULT 'default',
	noValidate int(1) DEFAULT '0',	-- --no-validate option
	storageProvisionedMode varchar(5) DEFAULT 'LVM',
	vgName varchar(45),
	lvName varchar(45),
	lvSize varchar(9),
	fstype varchar(6) DEFAULT 'xfs',
	bridge varchar(8) DEFAULT 'lxcbr0',
	bootProto varchar(6) DEFAULT 'dhcp',
	ipAddr varchar(15),
	netmask varchar(15),
	gateway varchar(15),
	broadcast varchar(15),
	network varchar(15),
	dns1 varchar(15),
	dns2 varchar(15),
	memory varchar(20),
	swap varchar(20),
	cpu varchar(182),
	percentCpu int(3) DEFAULT '100',
	keyPair varchar(20),
	startAuto int(1),
	startDelay int(3),
	shortDescription varchar(60),
	creationDate timestamp,
	creatorId int(11) default '1',
	ownerId int(11) default '1',
	locked int(1) default '0'
) ENGINE=InnoDB;



DROP TABLE IF EXISTS distros;

CREATE TABLE IF NOT EXISTS distros (
	idDistroEntry int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	distroData varchar(255),
	showData varchar(255),
	active int(1) DEFAULT '1'
) ENGINE=InnoDB;

INSERT INTO distros (distroData, showData) VALUES ('centos-6-amd64', 'CentOS 6 amd64');
INSERT INTO distros (distroData, showData) VALUES ('centos-7-amd64', 'CentOS 7 amd64');
INSERT INTO distros (distroData, showData) VALUES ('ubuntu-trusty-amd64', 'Ubuntu Trusty 14.04 LTS amd64');
INSERT INTO distros (distroData, showData) VALUES ('ubuntu-xenial-amd64', 'Ubuntu Xenial 16.04 LTS amd64');



DROP TABLE IF EXISTS dataRemoteQuery;

CREATE TABLE IF NOT EXISTS dataRemoteQuery (
	idData int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	Customer_Number varchar(255),
	Password2Query varchar(255),
	lastUpdate timestamp
) ENGINE=InnoDB;



DROP TABLE IF EXISTS keyPairOwner;

CREATE TABLE IF NOT EXISTS keyPairOwner (
	idKeyPair int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	keyPairName varchar(24) NOT NULL,
	idUser int(11) NOT NULL
) ENGINE=InnoDB;
