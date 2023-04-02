CREATE OR REPLACE FUNCTION fk_formPersonalOfferByGrowthOfAverageCheck(method int,
                                                                      separated_dates varchar,
                                                                      transactions_count int,
                                                                      growth_of_check decimal,
                                                                      max_churn_index numeric,
                                                                      max_transactions_with_discount numeric,
                                                                      share_of_margin numeric)
RETURNS table(Customer_ID bigint,
              Required_Check_Measure decimal,
              Group_Name varchar,
              Offer_Discount_Depth decimal)
AS $$
    BEGIN
        IF method = 1 THEN
            RETURN QUERY (
                SELECT av.Customer_ID, (av.AverageCheck * growth_of_check), 'IN PROGRESS'::varchar, 0.0
                FROM fk_getAverageCheckByTransactionsBetweenDates(split_part(separated_dates, ' ', 1)::date, split_part(separated_dates, ' ', 2)::date) AS av
            );
        ELSEIF method = 2 THEN
            RETURN QUERY (
                SELECT av.Customer_ID, (av.AverageCheck * growth_of_check), 'IN PROGRESS'::varchar, 0.0
                FROM fk_getAverageCheckByNLastTransactions(transactions_count) AS av
            );
        END IF;
    END;
$$ LANGUAGE plpgsql;

SELECT * FROM fk_formPersonalOfferByGrowthOfAverageCheck(1, '2022-01-01 2023-01-01', 0, 1.0, 0.0, 0.0, 0.0)

SELECT * FROM fk_formPersonalOfferByGrowthOfAverageCheck(2, '', 10, 1.0, 0.0, 0.0, 0.0)



CREATE OR REPLACE FUNCTION fk_getAverageCheckByNLastTransactions(N bigint)
RETURNS table(Customer_ID bigint, AverageCheck decimal)
AS $$
    SELECT p.customer_id, avg(p.transaction_summ)
    FROM (
        SELECT pi.customer_id, pi.customer_name, pi.customer_surname, t.transaction_summ,
               row_number() OVER (PARTITION BY pi.Customer_ID ORDER BY t.transaction_datetime DESC) as rn
        FROM personinformation pi
        JOIN cards c on pi.customer_id = c.customer_id
        JOIN transactions t on c.customer_card_id = t.customer_card_id
        ORDER BY pi.customer_id
    ) p
    WHERE rn <= N
    GROUP BY p.customer_id, p.customer_name, p.customer_surname
    ORDER BY p.customer_id
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION fk_getAverageCheckByTransactionsBetweenDates(begin_date date, end_date date)
RETURNS table(Customer_ID bigint, AverageCheck decimal)
AS $$
    SELECT pi.customer_id, avg(t.transaction_summ)
    FROM personinformation pi
    JOIN cards c on pi.customer_id = c.customer_id
    JOIN transactions t on c.customer_card_id = t.customer_card_id
    WHERE t.transaction_datetime BETWEEN begin_date AND end_date
    GROUP BY pi.customer_id, pi.customer_name, pi.customer_surname
    ORDER BY pi.customer_id
$$ LANGUAGE SQL;
