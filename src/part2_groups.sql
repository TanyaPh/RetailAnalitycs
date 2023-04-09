CREATE OR REPLACE VIEW Groups_View AS
    SELECT * FROM checks
;

SELECT DISTINCT pi.customer_id, pg.group_id
FROM personinformation AS pi
JOIN cards c on pi.customer_id = c.customer_id
JOIN transactions t on c.customer_card_id = t.customer_card_id
JOIN checks c2 on t.transaction_id = c2.transaction_id
JOIN productgrid pg on c2.sku_id = pg.sku_id
JOIN skugroup s on pg.group_id = s.group_id
ORDER BY pi.customer_id