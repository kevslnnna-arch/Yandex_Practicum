/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Козлова Екатерина
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT COUNT (id) AS players_count, 
SUM (payer) AS paying_players, ROUND (AVG (payer), 3) AS paying_share_players
FROM fantasy.users
ORDER BY players_count;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
WITH race_pay AS (
       SELECT
       r.race AS race,
       SUM(u.payer) AS race_paying,
       COUNT(*) AS race_total
       FROM fantasy.users AS u
LEFT JOIN fantasy.race AS r ON u.race_id = r.race_id
WHERE u.payer IS NOT NULL
GROUP BY r.race)
      SELECT race, race_paying, race_total, ROUND (race_paying :: NUMERIC / race_total, 3) AS share_paying_races
      FROM race_pay
      GROUP BY race, race_paying, race_total;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT COUNT (*) AS total_count, 
SUM (amount) AS sum_amount, 
MIN (amount) AS min_amount,
MAX (amount)AS max_amount,
ROUND (AVG (amount):: NUMERIC, 3) AS avg_amount,
ROUND (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount):: NUMERIC, 3) AS median_amount,
ROUND (STDDEV(amount):: NUMERIC, 3) AS stddev_amount
FROM fantasy.events
WHERE amount > 0;

-- 2.2: Аномальные нулевые покупки:нулевые покупки
SELECT COUNT (transaction_id) AS total_transaction, COUNT (transaction_id) FILTER (WHERE amount = 0) AS zero_purchases,
ROUND (COUNT (transaction_id) FILTER (WHERE amount = 0):: NUMERIC / COUNT (transaction_id), 3) AS share_zero_purchases
FROM fantasy.events;

-- 2.3: Популярные эпические предметы:
SELECT i.game_items, COUNT (e.transaction_id) AS total_count, 
ROUND ((COUNT(e.transaction_id)::NUMERIC / SUM(COUNT(e.transaction_id)) OVER ()) * 100, 2) AS transaction_share, 
COUNT (DISTINCT e.id) AS players_count, ROUND ((COUNT (DISTINCT e.id) :: numeric / (SELECT COUNT (DISTINCT id) FROM fantasy.events WHERE amount > 0)) * 100, 2) AS players_share
FROM fantasy.events AS e
LEFT JOIN fantasy.items AS i ON e.item_code = i.item_code
WHERE e.amount >0
GROUP BY i.game_items
ORDER BY total_count DESC;

-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
WITH race_players AS (
SELECT u.race_id, r.race, COUNT (u.id) AS total_players
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id = r.race_id 
GROUP BY u.race_id, r.race),
players_count AS (
SELECT u.race_id, COUNT (DISTINCT e.id) AS players_payer, COUNT (DISTINCT CASE WHEN u.payer = 1 THEN e.id END) AS paying_players,
COUNT (e.transaction_id) AS total_count, SUM (e.amount) AS amount_sum, 
COUNT (DISTINCT e.id) AS players_count
FROM fantasy.events AS e
JOIN fantasy.users AS u ON e.id = u.id
WHERE e.amount > 0
GROUP BY u.race_id)
SELECT rp.race_id, rp.race, rp.total_players, pc.players_payer, pc.paying_players, ROUND ((pc.players_payer::NUMERIC / rp.total_players), 3) AS paing_share,
ROUND ((pc.paying_players::NUMERIC / pc.players_payer), 3) AS avg_count_players,
ROUND ((pc.total_count::NUMERIC / pc.players_count), 3) AS avg_transaction_players,
ROUND ((pc.amount_sum::NUMERIC / pc.total_count), 3) AS avg_amount_players,
ROUND ((pc.amount_sum::NUMERIC / pc.players_count), 3) AS avg_total_count 
FROM race_players AS rp
LEFT JOIN players_count AS pc ON rp.race_id = pc.race_id
ORDER BY rp.race_id;
