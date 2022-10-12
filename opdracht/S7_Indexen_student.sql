-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S7: Indexen
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------
-- LET OP, zoals in de opdracht op Canvas ook gezegd kun je informatie over
-- het query plan vinden op: https://www.postgresql.org/docs/current/using-explain.html


-- S7.1.
--
-- Je maakt alle opdrachten in de 'sales' database die je hebt aangemaakt en gevuld met
-- de aangeleverde data (zie de opdracht op Canvas).
--
-- Voer het voorbeeld uit wat in de les behandeld is:
-- 1. Voer het volgende EXPLAIN statement uit:
    EXPLAIN SELECT * FROM order_lines WHERE stock_item_id = 9;
--    Bekijk of je het resultaat begrijpt. Kopieer het explain plan onderaan de opdracht
-- 2. Voeg een index op stock_item_id toe:
    CREATE INDEX ord_lines_si_id_idx ON order_lines (stock_item_id);
    DROP INDEX ord_lines_si_id_idx;
-- 3. Analyseer opnieuw met EXPLAIN hoe de query nu uitgevoerd wordt
--    Kopieer het explain plan onderaan de opdracht
-- 4. Verklaar de verschillen. Schrijf deze hieronder op.

--Gather  (cost=1000.00..6152.27 rows=1010 width=96)
--        Workers Planned: 2
--  ->  Parallel Seq Scan on order_lines  (cost=0.00..5051.27 rows=421 width=96)
--        Filter: (stock_item_id = 9)
-- Hier gaat de query door alle records heen om de goede te vinden.

--Bitmap Heap Scan on order_lines  (cost=12.12..2305.84 rows=1010 width=96)
--  Recheck Cond: (stock_item_id = 9)
--  ->  Bitmap Index Scan on ord_lines_si_id_idx  (cost=0.00..11.87 rows=1010 width=0)
--        Index Cond: (stock_item_id = 9)
-- Hier kan de query direct alle records vinden.

-- S7.2.
--
-- 1. Maak de volgende twee query’s:
-- 	  A. Toon uit de order tabel de order met order_id = 73590
-- 	  B. Toon uit de order tabel de order met customer_id = 1028
-- 2. Analyseer met EXPLAIN hoe de query’s uitgevoerd worden en kopieer het explain plan onderaan de opdracht
-- 3. Verklaar de verschillen en schrijf deze op
-- 4. Voeg een index toe, waarmee query B versneld kan worden
-- 5. Analyseer met EXPLAIN en kopieer het explain plan onder de opdracht
-- 6. Verklaar de verschillen en schrijf hieronder op

EXPLAIN SELECT * FROM orders WHERE order_id = 73590;
--Index Scan using pk_sales_orders on orders  (cost=0.29..8.31 rows=1 width=155)
--Index Cond: (order_id = 73590)
-- Hier kan de query direct alle records vinden.

EXPLAIN SELECT * FROM orders WHERE customer_id = 1028;
--Seq Scan on orders  (cost=0.00..1819.94 rows=107 width=155)
--Filter: (customer_id = 1028)
-- Hier gaat de query door alle records heen om de goede te vinden.

CREATE INDEX orders_customer_id_idx ON orders (customer_id);
--Bitmap Heap Scan on orders  (cost=5.12..308.96 rows=107 width=155)
--  Recheck Cond: (customer_id = 1028)
--  ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..5.10 rows=107 width=0)
--        Index Cond: (customer_id = 1028)
-- Hier kan de query direct alle records vinden.


-- S7.3.A
--
-- Het blijkt dat customers regelmatig klagen over trage bezorging van hun bestelling.
-- Het idee is dat verkopers misschien te lang wachten met het invoeren van de bestelling in het systeem.
-- Daar willen we meer inzicht in krijgen.
-- We willen alle orders (order_id, order_date, salesperson_person_id (als verkoper),
--    het verschil tussen expected_delivery_date en order_date (als levertijd),  
--    en de bestelde hoeveelheid van een product zien (quantity uit order_lines).
-- Dit willen we alleen zien voor een bestelde hoeveelheid van een product > 250
--   (we zijn nl. als eerste geïnteresseerd in grote aantallen want daar lijkt het vaker mis te gaan)
-- En verder willen we ons focussen op verkopers wiens bestellingen er gemiddeld langer over doen.
-- De meeste bestellingen kunnen binnen een dag bezorgd worden, sommige binnen 2-3 dagen.
-- Het hele bestelproces is er op gericht dat de gemiddelde bestelling binnen 1.45 dagen kan worden bezorgd.
-- We willen in onze query dan ook alleen de verkopers zien wiens gemiddelde levertijd 
--  (expected_delivery_date - order_date) over al zijn/haar bestellingen groter is dan 1.45 dagen.
-- Maak om dit te bereiken een subquery in je WHERE clause.
-- Sorteer het resultaat van de hele geheel op levertijd (desc) en verkoper.
-- 1. Maak hieronder deze query (als je het goed doet zouden er 377 rijen uit moeten komen, en het kan best even duren...)

EXPLAIN  SELECT o.order_id, o.order_date, salesperson_person_id AS verkoper, expected_delivery_date - order_date AS vertraging, picked_quantity   FROM orders o
JOIN order_lines ol on o.order_id = ol.order_id
WHERE (SELECT AVG(o2.expected_delivery_date - o2.order_date) FROM orders o2 --!!!
    WHERE o2.salesperson_person_id = o.salesperson_person_id)
    > 1.45
    AND ol.picked_quantity > 250
    ORDER BY vertraging DESC, salesperson_person_id;

-- Waarom is deze traag?
--De query berekent het average voor elke sales_person_id in orders.

SELECT count(*) FROM orders;

-- S7.3.B
--
-- 1. Vraag het EXPLAIN plan op van je query (kopieer hier, onder de opdracht)
-- 2. Kijk of je met 1 of meer indexen de query zou kunnen versnellen
-- 3. Maak de index(en) aan en run nogmaals het EXPLAIN plan (kopieer weer onder de opdracht) 
-- 4. Wat voor verschillen zie je? Verklaar hieronder.

--Sort  (cost=1571648.45..1571649.15 rows=280 width=20)
--      "  Sort Key: ((o.expected_delivery_date - o.order_date)) DESC, o.salesperson_person_id"
--  ->  Nested Loop  (cost=0.29..1571637.06 rows=280 width=20)
--        ->  Seq Scan on order_lines ol  (cost=0.00..6738.65 rows=841 width=8)
--              Filter: (picked_quantity > 250)
--        ->  Index Scan using pk_sales_orders on orders o  (cost=0.29..1860.76 rows=1 width=16)
--              Index Cond: (order_id = ol.order_id)
--              Filter: ((SubPlan 1) > 1.45)
--              SubPlan 1
--                ->  Aggregate  (cost=1856.74..1856.75 rows=1 width=32)
--                      ->  Seq Scan on orders o2  (cost=0.00..1819.94 rows=7360 width=8)
--                            Filter: (salesperson_person_id = o.salesperson_person_id)

CREATE INDEX orders_salesperson_person_id_idx ON orders (salesperson_person_id);
DROP INDEX orders_salesperson_person_id_idx;

--Sort  (cost=947117.58..947118.28 rows=280 width=20)
--      "  Sort Key: ((o.expected_delivery_date - o.order_date)) DESC, o.salesperson_person_id"
--  ->  Nested Loop  (cost=0.29..947106.20 rows=280 width=20)
--        ->  Seq Scan on order_lines ol  (cost=0.00..6738.65 rows=841 width=8)
--              Filter: (picked_quantity > 250)
--        ->  Index Scan using pk_sales_orders on orders o  (cost=0.29..1118.15 rows=1 width=16)
--              Index Cond: (order_id = ol.order_id)
--              Filter: ((SubPlan 1) > 1.45)
--              SubPlan 1
--                ->  Aggregate  (cost=1114.13..1114.14 rows=1 width=32)
--                      ->  Bitmap Heap Scan on orders o2  (cost=85.33..1077.33 rows=7360 width=8)
--                            Recheck Cond: (salesperson_person_id = o.salesperson_person_id)
--                            ->  Bitmap Index Scan on orders_salesperson_person_id_idx  (cost=0.00..83.49 rows=7360 width=0)
--                                  Index Cond: (salesperson_person_id = o.salesperson_person_id)

-- Het grootste verschil is dat de cost van "1571648.45..1571649.15" naar "947117.58..947118.28" is gegaan.



-- S7.3.C
--
-- Zou je de query ook heel anders kunnen schrijven om hem te versnellen?

CREATE OR REPLACE VIEW delivery AS
SELECT AVG(expected_delivery_date - orders.order_date) AS avg_delivery_time, salesperson_person_id FROM orders GROUP BY salesperson_person_id;
DROP view delivery;

SELECT * FROM delivery;

EXPLAIN  SELECT o.order_id, o.order_date, salesperson_person_id AS verkoper, expected_delivery_date - order_date AS vertraging, picked_quantity   FROM orders o
        JOIN order_lines ol on o.order_id = ol.order_id
        WHERE salesperson_person_id IN (SELECT salesperson_person_id FROM delivery WHERE avg_delivery_time > 1.45)
          AND ol.picked_quantity > 250
         ORDER BY vertraging DESC, salesperson_person_id;

-- Hierbij doe ik eerst het avg berkenen van de sales_person en daarna alles boven 1.45 pakken
-- en daarna de records selecteren waarvan de sales_person_id in die tabel zit.
-- Ik bereken dus het avg maar 10 keer in plaats van honderden keren.


