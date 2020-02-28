use laboratory;

-- простенькая выборка, чтоб понимать сколько заказов сделал клиент за месяц и на какую сумму
select 
	client_code as 'Код клиента',
	(select name from clients c where c.code = orders.client_code) as 'Название клиента',
	count(client_code) as 'Количество заказов в текущем месяце', 
	sum(order_cost) as 'Сумма за месяц'
from 
	orders 
where 
	TIMESTAMPDIFF(day, created_at, now()) < 30 group by client_code;



