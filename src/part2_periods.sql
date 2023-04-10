CREATE OR REPLACE VIEW Periods AS
    WITH base AS (
        SELECT customer_id,
               group_id,
               min(transaction_datetime) AS First_Group_Purchase_Date,
               max(transaction_datetime) AS Last_Group_Purchase_Date,
               count(transaction_id) AS Group_Purchase
        FROM purchasehistory
        GROUP BY customer_id, group_id
    )
    SELECT DISTINCT
        b.customer_id,
        b.group_id,
        First_Group_Purchase_Date,
        Last_Group_Purchase_Date,
        Group_Purchase,
        (date_part('day', Last_Group_Purchase_Date - First_Group_Purchase_Date) + 1)::numeric / Group_Purchase  AS Group_Frequency,
        MIN(sku_discount / sku_summ) OVER (PARTITION BY ph.customer_id, ph.group_id) AS Group_Min_Discount
    FROM base b
             JOIN purchasehistory ph ON ph.customer_id = b.customer_id AND ph.group_id = b.group_id
             JOIN checks c on ph.transaction_id = c.transaction_id;

SELECT * FROM Periods
