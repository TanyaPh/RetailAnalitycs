CREATE OR REPLACE VIEW Groups AS

WITH Groups_per_customer AS (
    SELECT DISTINCT Customer_ID, Group_ID
    FROM Cards c
        JOIN transactions t ON c.customer_card_id = t.customer_card_id
        JOIN checks ch ON t.Transaction_ID = ch.Transaction_ID
        JOIN productgrid p on p.sku_id = ch.sku_id
    ORDER BY Customer_ID, Group_ID
)
   , Affinity_Index AS (
    SELECT gr.Customer_ID, gr.Group_ID, Group_Purchase/count(Transaction_ID)::double precision AS Group_Affinity_Index
    FROM Groups_per_customer gr
        JOIN purchasehistory pu ON gr.customer_id = pu.customer_id
        JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
    WHERE transaction_datetime >= First_Group_Purchase_Date AND transaction_datetime <= Last_Group_Purchase_Date
    GROUP BY gr.Customer_ID, gr.Group_ID, Group_Purchase
    ORDER BY Customer_ID
)
   , Churn_Rate AS (
    SELECT af.Customer_ID, af.Group_ID,
           EXTRACT(EPOCH FROM (SELECT * FROM dateofanalysisformation)-max(Transaction_DateTime)) / 60 / 60 / 24
           / Group_Frequency AS Group_Churn_Rate
    FROM Affinity_Index af
        JOIN purchasehistory pu ON af.customer_id = pu.customer_id AND af.group_id = pu.group_id
        JOIN periods p2 on af.customer_id = p2.customer_id AND af.group_id = p2.group_id
    GROUP BY af.Customer_ID, af.Group_ID, Group_Affinity_Index, Group_Frequency
    ORDER BY Customer_ID, Group_ID
)
   , Stability_Index AS (
    SELECT Customer_ID, Group_ID, avg(relative_deviation) AS Group_Stability_Index
    FROM (
         SELECT gr.Customer_ID, gr.Group_ID,
                abs(EXTRACT(EPOCH FROM (Transaction_DateTime - lag (Transaction_DateTime) OVER
                    (PARTITION BY gr.Customer_ID, gr.Group_ID ORDER BY Transaction_DateTime))) / 60 / 60 / 24
                    - Group_Frequency) / Group_Frequency AS relative_deviation
        FROM Groups_per_customer gr
            JOIN purchasehistory pu ON gr.customer_id = pu.customer_id AND gr.group_id = pu.group_id
            JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
        ORDER BY Customer_ID, Group_ID) AS deviations
    GROUP BY Customer_ID, Group_ID
    ORDER BY Customer_ID, Group_ID
)
--    , Margin_by_period AS (
--     SELECT gr.Customer_ID, gr.Group_ID, Transaction_ID, Transaction_DateTime
--     FROM Groups_per_customer  gr
--         JOIN purchasehistory pu ON gr.customer_id = pu.customer_id AND gr.group_id = pu.group_id
--         JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
--     WHERE transaction_datetime >= (SELECT * FROM dateofanalysisformation) + (2000) AND --change 2000
--           transaction_datetime <= (SELECT * FROM dateofanalysisformation)
--     GROUP BY gr.Customer_ID, gr.Group_ID, Transaction_ID, Transaction_DateTime
--     ORDER BY Customer_ID, Group_ID
-- )
--    , Margin_by_transaction_amount AS (
--     SELECT gr.Customer_ID, gr.Group_ID, Transaction_ID, Transaction_DateTime
--     FROM Groups_per_customer  gr
--         JOIN purchasehistory pu ON gr.customer_id = pu.customer_id AND gr.group_id = pu.group_id
--         JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
--     ORDER BY Customer_ID, Transaction_DateTime DESC
--     LIMIT 20    --change 20
-- )
   , Margin AS (
    SELECT gr.Customer_ID, gr.Group_ID, sum(Group_Summ_Paid - Group_Cost) AS Group_Margin
    FROM Groups_per_customer gr --choose method
        JOIN purchasehistory pu ON gr.customer_id = pu.customer_id AND gr.group_id = pu.group_id
        JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
    GROUP BY gr.Customer_ID, gr.Group_ID
    ORDER BY Customer_ID, Group_ID
)
   , Discount_Share AS (
    SELECT gr.Customer_ID, gr.Group_ID,
           count(ch.Transaction_ID)/Group_Purchase::double precision AS Group_Discount_Share
    FROM Groups_per_customer gr
        JOIN purchasehistory pu ON gr.customer_id = pu.customer_id AND gr.group_id = pu.group_id
        JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
        JOIN checks ch ON pu.Transaction_ID = ch.Transaction_ID
    WHERE SKU_Discount > 0
    GROUP BY gr.Customer_ID, gr.Group_ID, Group_Purchase
    ORDER BY Customer_ID, Group_ID
)
   , Minimum_Discount AS (
    SELECT gr.Customer_ID, gr.Group_ID, min(Group_Min_Discount) AS Group_Minimum_Discount
    FROM Groups_per_customer gr
--         JOIN purchasehistory pu ON gr.customer_id = pu.customer_id AND gr.group_id = pu.group_id
        JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
    WHERE Group_Min_Discount <> 0
    GROUP BY gr.Customer_ID, gr.Group_ID
    ORDER BY Customer_ID, Group_ID
)
   , Average_Discount AS (
    SELECT gr.Customer_ID, gr.Group_ID, sum(Group_Summ_Paid)/sum(Group_Summ) AS Group_Average_Discount
    FROM Groups_per_customer gr
        JOIN purchasehistory pu ON gr.customer_id = pu.customer_id AND gr.group_id = pu.group_id
--         JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
--     WHERE Group_Min_Discount <> 0
    GROUP BY gr.Customer_ID, gr.Group_ID
    ORDER BY Customer_ID, Group_ID
)

SELECT gr.Customer_ID, gr.Group_ID,
       Group_Affinity_Index,
       Group_Churn_Rate,
       Group_Stability_Index,
       Group_Margin,
       Group_Discount_Share,
       Group_Minimum_Discount,
       Group_Average_Discount
FROM Groups_per_customer gr
    JOIN Affinity_Index af ON gr.customer_id = af.customer_id AND gr.group_id = af.group_id
    JOIN Churn_Rate ch ON gr.customer_id = ch.customer_id AND gr.group_id = ch.group_id
    JOIN Stability_Index st ON gr.customer_id = st.customer_id AND gr.group_id = st.group_id
    JOIN Margin m ON gr.customer_id = m.customer_id AND gr.group_id = m.group_id
    full JOIN Discount_Share d_sh ON gr.customer_id = d_sh.customer_id AND gr.group_id = d_sh.group_id
    full JOIN Minimum_Discount min_dis ON gr.customer_id = min_dis.customer_id AND gr.group_id = min_dis.group_id
    JOIN Average_Discount avg_dis ON gr.customer_id = avg_dis.customer_id AND gr.group_id = avg_dis.group_id
ORDER BY gr.Customer_ID, gr.Group_ID




























--     , Staby_Index AS (
--     SELECT gr.Customer_ID, gr.Group_ID,
--            abs(EXTRACT(EPOCH FROM (Transaction_DateTime
--                 - lag (Transaction_DateTime) OVER (PARTITION BY gr.Customer_ID, gr.Group_ID ORDER BY Transaction_DateTime))) / 60 / 60 / 24
--                 - Group_Frequency) / Group_Frequency AS relative_deviation
--     FROM Groups_per_customer gr
--         JOIN purchasehistory pu ON gr.customer_id = pu.customer_id AND gr.group_id = pu.group_id
--         JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
--     ORDER BY Customer_ID, Group_ID
-- )
--    , Stability_Index AS (
--     SELECT Customer_ID, Group_ID, avg(relative_deviation) AS Group_Stability_Index
--     FROM Staby_Index
--     GROUP BY Customer_ID, Group_ID
--     ORDER BY Customer_ID, Group_ID
-- )