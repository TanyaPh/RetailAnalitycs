CREATE OR REPLACE FUNCTION fun_increase_freq_visits(first_date timestamp, last_date timestamp, add_transactions integer,
                                                    max_churn_rate decimal, max_discount_share decimal, margin_share decimal)
RETURNS table(Customer_ID bigint, Start_Date timestamp, End_Date timestamp,
                Required_Transactions_Count numeric,  Group_Name varchar,
                Group_Affinity_Index numeric
--              , Gr_Margin numeric,Minimum_Disc numeric,
--                 Offer_Discount_Depth decimal
             )
AS $$
    DECLARE
        period numeric;
    BEGIN
        period := EXTRACT(EPOCH FROM (last_date-first_date))::numeric / 60 / 60 / 24;
    RETURN QUERY
    WITH suitable_groups AS (
        SELECT *,
--            max(gr.Group_Affinity_Index) OVER  (PARTITION BY gr.Customer_ID) AS Max_Affinity_Index,
--            margin_share/100 * abs,(Group_Margin) AS Gr_Margin,
            30.0/100 * abs(Group_Margin) AS Gr_Margin,
           ceil(Group_Minimum_Discount / 0.05) * 0.05 * abs(Group_Margin) AS Minimum_Disc,
--            Group_Minimum_Discount,
--             AVG(group_margin) OVER (PARTITION BY gr.customer_id, gr.group_id) AS Avg_group_margin
           (CASE WHEN (30.0 /100 * abs(Group_Margin)) > ceil(Group_Minimum_Discount / 0.05) * 0.05 * abs(Group_Margin)
               THEN ceil(Group_Minimum_Discount *100 / 5) * 5 END)
               AS Offer_Discount_Depth
        FROM groups gr
        WHERE gr.Group_Churn_Rate <= 3 AND Group_Discount_Share < 70 / 100::float
--           AND CASE WHEN round(Group_Minimum_Discount * 100 / 5) * 5 < Group_Minimum_Discount THEN
        ORDER BY gr.Group_Affinity_Index DESC
    )
    SELECT DISTINCT
           c.Customer_ID,
           first_date Start_Date,
           last_date AS End_Date,
           round(period / Customer_Frequency::numeric) + add_transactions AS Required_Transactions_Count,
           dd.groupname,
           dd.offer_discount_depth
           --            sku.Group_Name,
--            s_gr.Group_Affinity_Index::numeric AS Group_Affinity_Index,
--            s_gr.Gr_Margin,
--            s_gr.Minimum_Disc,
--            Group_Minimum_Discount
--            s_gr.Offer_Discount_Depth
    FROM customers c
        JOIN suitable_groups s_gr ON c.customer_id = s_gr.customer_id
        JOIN skugroup sku ON s_gr.group_id = sku.group_id
        join fk_determinegroupanddiscount(max_churn_rate, max_discount_share, margin_share) dd ON dd.customer_id = c.Customer_ID
--     WHERE
--          ceil(s_gr.group_minimum_discount * 100 / 5.0) * 5.0 <
--         (SELECT sum(s2.sku_retail_price - s2.sku_purchase_price) / sum(s2.sku_retail_price)
--          FROM productgrid s
--          JOIN stores s2 ON s_gr.group_id = s.group_id AND s.sku_id = s2.sku_id) / 100 * 30
    ORDER BY c.Customer_ID;
    END
$$ LANGUAGE plpgsql;

SELECT * FROM fun_increase_freq_visits('2022-08-18 00:00:00', '2022-08-18 00:00:00',
    1,3, 70, 30);

SELECT * FROM fun_increase_freq_visits('2022-08-18 00:00:00', '2022-08-18 00:00:00',
    1,10, 50, 50);
