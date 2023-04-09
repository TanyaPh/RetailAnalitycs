CREATE OR REPLACE VIEW PurchaseHistory AS
    SELECT * FROM checks
;

SELECT pi.customer_id, t.transaction_id, t.transaction_datetime, c2.sku_id, p.group_id
     , s.sku_purchase_price, c2.sku_summ, c2.sku_summ_paid
FROM personinformation AS pi
JOIN cards c on pi.customer_id = c.customer_id
JOIN transactions t on c.customer_card_id = t.customer_card_id
JOIN checks c2 on t.transaction_id = c2.transaction_id
JOIN productgrid p on c2.sku_id = p.sku_id
JOIN stores s on s.transaction_store_id = t.transaction_store_id
ORDER BY pi.customer_id, p.group_id
