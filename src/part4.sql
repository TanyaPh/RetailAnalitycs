CREATE OR REPLACE FUNCTION fk_formPersonalOfferByGrowthOfAverageCheck(method smallint,
                                                                      separated_dates varchar,
                                                                      transactions_count bigint,
                                                                      growth_of_check decimal,
                                                                      max_churn_index numeric,
                                                                      share_of_margin numeric)
RETURNS table(Customer_ID bigint,
              Required_Check_Measure decimal,
              Group_Name varchar,
              Offer_Discount_Depth decimal)
AS $$

$$ LANGUAGE SQL;
