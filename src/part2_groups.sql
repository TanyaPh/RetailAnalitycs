-- CREATE OR REPLACE VIEW Groups AS

WITH Groups_per_customer AS (
    SELECT DISTINCT Customer_ID, Group_ID
    FROM Cards c
        JOIN transactions t ON c.customer_card_id = t.customer_card_id
        JOIN checks ch ON t.Transaction_ID = ch.Transaction_ID
        JOIN productgrid p on p.sku_id = ch.sku_id
    ORDER BY Customer_ID, Group_ID
)
   , Affinity_Index AS (
    SELECT gr.Customer_ID, gr.Group_ID, Group_Purchase/count(Transaction_ID)::decimal AS Group_Affinity_Index
    FROM Groups_per_customer  gr
        JOIN purchasehistory pu ON gr.customer_id = pu.customer_id
        JOIN periods p2 on gr.customer_id = p2.customer_id AND gr.group_id = p2.group_id
    WHERE transaction_datetime >= First_Group_Purchase_Date AND transaction_datetime <= Last_Group_Purchase_Date
    GROUP BY gr.Customer_ID, gr.Group_ID, Group_Purchase
    ORDER BY Customer_ID, Group_ID
)
--    , Churn_Rate AS (
    SELECT af.Customer_ID, af.Group_ID, Group_Affinity_Index,
           EXTRACT(EPOCH FROM (SELECT * FROM dateofanalysisformation)-max(Transaction_DateTime)) / 60 / 60 / 24
           / Group_Frequency AS Group_Churn_Rate
    FROM Affinity_Index af
        JOIN purchasehistory pu ON af.customer_id = pu.customer_id AND af.group_id = pu.group_id
        JOIN periods p2 on af.customer_id = p2.customer_id AND af.group_id = p2.group_id
    GROUP BY af.Customer_ID, af.Group_ID, Group_Affinity_Index, Group_Frequency
    ORDER BY Customer_ID, Group_ID
-- )