drop database if exists laboratory;
create database laboratory;
use laboratory;

-- таблица городов в которых работает кампания
DROP TABLE IF EXISTS cities;
CREATE TABLE cities (
	name varchar(255) UNIQUE comment 'Название города',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to TIMESTAMP DEFAULT NULL,
	laboratory TINYINT DEFAULT 0 comment 'Есть ли в городе лаборатория'
);

-- Таблица приборов(анализаторов) установленных в лабораториях
DROP TABLE IF EXISTS analyzers;
CREATE TABLE analyzers (
	short_name varchar(50) unique comment 'краткое название анализатора',
	name varchar(255) UNIQUE comment 'полное название анализатора',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to TIMESTAMP DEFAULT NULL,
	citi varchar(255) comment 'В каком городе установлен анализатор',
	foreign key (citi) references cities(name)
);

-- таблица субподрядных лабораторий
drop table if exists outsourcers;
CREATE TABLE outsourcers (
	short_name varchar(50) UNIQUE,
	name varchar(255) UNIQUE comment 'Название',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to TIMESTAMP DEFAULT null
);

-- список тестов (минимальных единиц исследования)
DROP TABLE IF EXISTS tests;
CREATE TABLE tests (
	test_key varchar(50) unique not null comment 'Ключ теста',
	test_code varchar(50) unique not null comment 'код теста (может совпадать с кодом набора тестов и услуги)',
	name varchar(255) UNIQUE comment 'Название теста',
	decimal_place TINYINT unsigned comment 'количество знаков после запятой в результате теста',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to TIMESTAMP DEFAULT null
);

-- таблица нормальных значений (в медицине 'референсы' или 'референтные интервалы') по тестам
DROP TABLE IF EXISTS `references`;
CREATE TABLE `references` (
	id serial PRIMARY KEY,
	test_keycode varchar(50) comment 'Ключ теста (краткое наименование на латинице)',
	age_from bigint comment 'для пациентов возрастом от ...',
	age_to bigint comment 'для пациентов возрастом до ...',
	sex set('mail', 'femail', 'joint') default 'joint' comment 'пол пациента, joint - для обоих полов',
	value_from DECIMAL(10,4) comment 'нижняя граница нормальных значений',
	value_to DECIMAL(10,4) comment 'верхняя граница нормальных значений',
	text_referens text comment 'а это текстовые нормальные значения, например для некоторых инфекций, нормальный результат "не обнаружено"',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to DATE default null,
	foreign key (test_keycode) references tests(test_key),
	key index_test_keycode(test_keycode)
);

-- какие тесты на каких анализаторах выполняются
drop table if exists tests_on_analyzer;
create table tests_on_analyzer (
	test_key varchar(50) not null comment 'Ключ теста',
	analyzer varchar(50) not null comment 'краткое название прибора',
	foreign key (analyzer) references analyzers(short_name),
	foreign key (test_key) references tests(test_key),
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to DATE default null,
	constraint unique_analyte unique (test_key, analyzer)
);

-- test_set - наборы тестов, это полноценные исследования, по которым врач может оценить состояние пациента
DROP TABLE IF EXISTS test_set;
CREATE TABLE test_set (
	keycode varchar(50) UNIQUE comment 'Ключ набора (краткое наименование на латинице)',
	code varchar(50) default null comment 'код набора',
	name varchar(255) UNIQUE comment 'Название',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to DATE default null
);

-- таблица соответствия какие тесты входят в наборы тестов
drop table if exists tests_in_sets;
create table tests_in_sets (
	test_set_keycode varchar(50) not null comment 'Ключ набора',
	test_key varchar(50) not null comment 'Ключ теста',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to DATE default null,
	foreign key (test_set_keycode) references test_set(keycode),
	foreign key (test_key) references tests(test_key),
	primary key (test_set_keycode, test_key)
);

-- таблица описывающая какие из наборов тестов выполняются в субподрядных лабораториях
drop table if exists outsourcing;
create table outsourcing (
	test_set_keycode varchar(50) not null comment 'Ключ набора',
	outsourcer_name varchar(50) not null comment 'название субподрядной лаборатории',
	citi varchar(255) comment 'В каком городе (разные города могут направлять исследования в разные субподрядные лаборатории)',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to DATE default null,
	foreign key (test_set_keycode) references test_set(keycode),
	foreign key (outsourcer_name) references outsourcers(short_name),
	foreign key (citi) references cities(name),
	constraint unique_set unique (test_set_keycode, outsourcer_name, citi)
);

-- типы результатов, уж очень не хотелось делать SET, по этому добавил эту табличку, впринципе на учебном проекте можно было обойтись и без нее
DROP TABLE IF EXISTS result_types;
CREATE TABLE result_types (
	`type` varchar(255) unique not null
);

-- виды пробирок, контейнеров, и различных коллекторов, которые используются для взятия биоматериала
DROP TABLE IF EXISTS container;
CREATE TABLE container (
	keycode varchar(50) UNIQUE comment 'короткий ключ',
	name varchar(255) UNIQUE comment 'Название контейнера (пробирки)',
	material varchar(255) not null comment 'вид биоматериала в контейнере',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to TIMESTAMP DEFAULT null
);

-- продаваемая услуга, это то, что оплачивает клиент, эта и следующая таблица не слились в одну с test_set только потому, что в разных городах
-- к одной услуге могут быть привязаны разные наборы тестов, это продемонстрировано на примере Твери.
DROP TABLE IF EXISTS sold_service;
CREATE TABLE sold_service (
	code varchar(50) unique not null comment 'Код услуги',
	short_name varchar(50) not null comment 'Краткое наименование услуги на латинице',
	full_name varchar(255) not null comment 'Полное наименование услуги',
	due_date tinyint unsigned not null comment 'срок выполнения',
	container varchar(50) not null comment 'Используемые контейнеры',
	result_type varchar(50) not null comment 'тип результата',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to date DEFAULT null,
	foreign key (container) references container(keycode),
	foreign key (result_type) references result_types(`type`)
);

-- таблица для связи услуги, набора тестов и города
drop table if exists service_and_test_set;
create table service_and_test_set (
	test_set_keycode varchar(50) not null,
	sold_service_code varchar(50) not null,
	citi varchar(255) not null,
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to DATE default null,
	foreign key (test_set_keycode) references test_set(keycode),
	foreign key (sold_service_code) references sold_service(code),
	foreign key (citi) references cities(name),
	primary key (test_set_keycode, sold_service_code, citi)
);

-- таблица клиентов (медицинских учреждений и пунктов взятия биоматериала)
DROP TABLE IF EXISTS clients;
CREATE TABLE clients (
	code varchar(10) unique primary key comment 'код контрагента',
	name varchar(255) UNIQUE comment 'Название',
	client_balance decimal(10,2) comment 'Баланс средств на счету клиента',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to TIMESTAMP DEFAULT NULL,
	citi varchar(255) comment 'Город в котором работает клиент',
	FOREIGN KEY (citi) REFERENCES cities(name)
);

-- прайс-лист, разным клиентам могут быть доступны разные услуги и по разной цене
drop table if exists price;
create table price (
	client_code varchar(10) not null comment 'Код клиента (контрагента)',
	service_code varchar(50) not null comment 'Код услуги',
	cost decimal(10,2) unsigned not null comment 'Стоимость услуги для данного клиента',
	date_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	date_to DATE default null,
	foreign key (client_code) references clients(code),
	foreign key (service_code) references sold_service(code),
	constraint unique_set unique (client_code, service_code),
	key index_client_code(client_code),
	key index_service_code(service_code)
);

-- таблица заказов клиентов, каждый пациент оформляется отдельной заявкой
drop table if exists orders;
create table orders (
	id SERIAL primary key,
	client_code varchar(10) not null comment 'Код клиента',
	order_cost decimal(10,2) default 0 comment 'стоимость заказа, по умолчанию = 0, триггером инкрементируется триггером increment_order_cost
в зависимости от прайсовой цены услуги',
	status tinyint default 0 comment 'статус не оплачено / оплачено изменяется хранимой процедурой invoice_client',
	created_at datetime DEFAULT CURRENT_TIMESTAMP,
	foreign key (client_code) references clients(code),
	key index_client_code(client_code)
);

-- состав заказа
drop table if exists order_composition;
create table order_composition (
	order_id bigint unsigned not null,
	client_code varchar(10) not null comment 'Код клиента',
	order_service varchar(50) not null comment 'Код услуги',
	foreign key (order_id) references orders(id),
	foreign key (client_code) references clients(code),
	foreign key (order_service) references sold_service(code),
	key index_client_code(client_code)
);


-- Триггеры --


DELIMITER //

-- Триггер для подсчёта полной стоимости заказа в зависимости от назначенных услуг

drop trigger if exists increment_order_cost//
create trigger increment_order_cost after insert on order_composition
for each row
begin
	update orders
	set 
		orders.order_cost = orders.order_cost + (select cost from price p where p.client_code = new.client_code and p.service_code = new.order_service)
	where orders.id = new.order_id;
end//




--  Процедуры --

-- Процедура оплаты всех заказов клиента, в качестве аргумента передаётся код клиента

drop procedure if exists invoice_client//
create procedure invoice_client (in cc varchar(10))
begin
	start transaction;
	
	set @clcode = cc;
	
	update clients
	set 
		client_balance = client_balance - (select sum(order_cost) from orders where client_code = @clcode)
	where code = @clcode
	;
	
	update orders
	set 
		status = 1
	where client_code = @clcode
	;
	
	commit;
end//

DELIMITER ;

-- Вызов процедуры оплаты всех заказов клиента
-- call invoice_client(1111);


-- Представления --

-- Выгрузить полный прайс-лист клиента
drop view if exists client_price;
create view client_price as
select 
	p.client_code as 'Код клиента',
	p.service_code as 'Код услуги',
	ss.full_name as 'Наименование',
	ss.due_date as 'Срок выполнения',
	ss.result_type as 'Тип результата',
	ss.container as 'Контейнер',
	p.cost as 'Цена'
from
	price p
join
	sold_service ss
where
	p.service_code = ss.code
;

-- вызвать представление, главное указать код нужного клиента
-- select * from client_price where `Код клиента` = '1111';

/*
вытащить все референсы всех тестов в наборе тестов, стороннему наблюдателю наверное сложно будет понять,
но я каждый день мечтаю, чтоб в нашей рабочей программе была такая штука =)
*/
drop view if exists test_set_references;
create view test_set_references as
select 
	ts.keycode as 'Ключ набора',
	ts.name as 'Наименование',
	tis.test_key as 'Ключ теста',
	r.sex as 'Пол',
	r.age_from as 'Возраст с',
	r.age_to as 'Возраст по',
	r.value_from as 'Норма нижняя',
	r.value_to as 'Норма верхняя',
	r.text_referens 'Текстовые референсы'
from
	test_set ts 
join
	tests_in_sets tis 
join 
	`references` r
where 
	ts.keycode = tis.test_set_keycode and tis.test_key = r.test_keycode;

-- Выхвать представление с референсами
-- select * from test_set_references where `Ключ набора` = 'HAEMAT short';













