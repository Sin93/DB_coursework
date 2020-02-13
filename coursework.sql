drop database if exists mdm;
create database mdm;
use mdm;

DROP TABLE IF EXISTS cities;
CREATE TABLE cities (
	name varchar(255) UNIQUE comment 'Название',
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	deactivated TIMESTAMP DEFAULT NULL,
	laboratory TINYINT DEFAULT 0 COMMENT 'Есть ли в городе лаборатория'
);

DROP TABLE IF EXISTS analyzers;
CREATE TABLE analyzers (
	short_name varchar(50) unique,
	name varchar(255) UNIQUE comment 'Название',
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	deactivated TIMESTAMP DEFAULT NULL,
	citi varchar(255),
	foreign key (citi) references cities(name)
);

drop table if exists outsourcers;
CREATE TABLE outsourcers (
	short_name varchar(50) UNIQUE,
	name varchar(255) UNIQUE comment 'Название',
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	deactivated TIMESTAMP DEFAULT NULL
);

DROP TABLE IF EXISTS tests;
CREATE TABLE tests (
	test_key varchar(50) unique not null comment 'Ключ',
	test_code varchar(50) unique not null comment 'код теста',
	name varchar(255) UNIQUE comment 'Название',
	result_type set('количественный','полуколичественный','качественный') not null,
	decimal_place TINYINT unsigned,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	deactivated TIMESTAMP DEFAULT null
);

DROP TABLE IF EXISTS referenses; -- нормальные значения, в медицине 'референсы' или 'референтные интервалы'
CREATE TABLE referenses (
	id serial PRIMARY KEY,
	test_keycode varchar(50) comment 'Ключ теста',
	date_from DATE NOT NULL,
	date_to DATE default null,
	foreign key (test_keycode) references tests(test_key)
);

drop table if exists tests_on_analyzer;
create table tests_on_analyzer (
	test_key varchar(50) not null,
	analyzer varchar(50) not null,
	foreign key (analyzer) references analyzers(short_name),
	foreign key (test_key) references tests(test_key),
	date_from DATE NOT NULL,
	date_to DATE default null,
	constraint unique_analyte unique (test_key, analyzer)
);

DROP TABLE IF EXISTS test_set;
CREATE TABLE test_set (
	keycode varchar(50) UNIQUE comment 'Ключ',
	code varchar(50) default null,
	name varchar(255) UNIQUE comment 'Название',
	date_from DATE NOT NULL,
	date_to DATE default null
);

drop table if exists tests_in_sets;
create table tests_in_sets (
	test_set_keycode varchar(50) not null,
	test_key varchar(50) not null,
	foreign key (test_set_keycode) references test_set(keycode),
	foreign key (test_key) references tests(test_key)
);

drop table if exists outsourcing;
create table outsourcing (
	test_set_keycode varchar(50) not null,
	outsourcer_name varchar(50) not null,
	citi varchar(255),
	date_from DATE NOT NULL,
	date_to DATE default null,
	foreign key (test_set_keycode) references test_set(keycode),
	foreign key (outsourcer_name) references outsourcers(short_name),
	foreign key (citi) references cities(name),
	constraint unique_set unique (test_set_keycode, outsourcer_name, citi)
);

DROP TABLE IF EXISTS result_types;
CREATE TABLE result_types (
	`type` varchar(255) unique not null
);

DROP TABLE IF EXISTS sold_service;
CREATE TABLE sold_service (
	code varchar(50) unique not null comment 'Код',
	short_name varchar(50) unique not null,
	full_name varchar(255) not null,
	test_set_keycode varchar(50),
	citi varchar(255),
	result_type varchar(50) not null,
	FOREIGN KEY (test_set_keycode) REFERENCES test_set(keycode),
	foreign key (citi) references cities(name),
	foreign key (result_type) references result_types(`type`),
	constraint unique_service unique (test_set_keycode, citi)
);

DROP TABLE IF EXISTS clients;
CREATE TABLE clients (
	id SERIAL PRIMARY KEY,
	code varchar(10) UNIQUE comment 'Номер ЛПУ',
	name varchar(255) UNIQUE comment 'Название',
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	deactivated TIMESTAMP DEFAULT NULL,
	citi varchar(255),
	FOREIGN KEY (citi) REFERENCES cities(name)
);


