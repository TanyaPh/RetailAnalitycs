CREATE TABLE IF NOT EXISTS PersonInformation(
    Customer_ID bigint primary key NOT NULL,
    Customer_Name varchar NOT NULL CHECK (Customer_Name SIMILAR TO '[A-ZА-ЯЁ][a-zа-яё\- ]*'),
    Customer_Surname varchar NOT NULL CHECK (Customer_Surname SIMILAR TO '[A-ZА-ЯЁ][a-zа-яё\- ]*'),
    Customer_Primary_Email varchar NOT NULL CHECK (Customer_Primary_Email SIMILAR TO '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
    Customer_Primary_Phone varchar NOT NULL CHECK (Customer_Primary_Phone SIMILAR TO '\+7[0-9]{10}')
);

-- DROP TABLE PersonInformation;

-- INSERT INTO PersonInformation VALUES (1, 'Peter', 'Иванов', 'pe-tr@i.ru', '+79180074077');

CREATE TABLE IF NOT EXISTS Cards(
    Customer_Card_ID bigint primary key NOT NULL,
    Customer_ID bigint NOT NULL references PersonInformation(Customer_ID)
);

-- DROP TABLE Cards;

-- INSERT INTO Cards VALUES (1, 1);

CREATE TABLE IF NOT EXISTS Transactions(
    Transaction_ID bigint NOT NULL primary key,
    Customer_Card_ID bigint NOT NULL references Cards(Customer_Card_ID),
    Transaction_Summ numeric NOT NULL,
    Transaction_DateTime timestamp NOT NULL,
    Transaction_Store_ID bigint NOT NULL references Stores(Store_ID)
);

CREATE TABLE IF NOT EXISTS Checks(
    Transaction_ID bigint NOT NULL references Transactions(Transaction_ID),
    SKU_ID bigint NOT NULL references ProductGrid(SKU_ID),
    SKU_Amount numeric NOT NULL,
    SKU_Summ numeric NOT NULL,
    SKU_Summ_Paid numeric NOT NULL,
    SKU_Discount numeric NOT NULL
);

CREATE TABLE IF NOT EXISTS ProductGrid(
    SKU_ID bigint NOT NULL primary key,
    SKU_Name varchar NOT NULL CHECK (SKU_Name SIMILAR TO ''),
    Group_ID bigint NOT NULL references SKUGroup(Group_ID)
);

CREATE TABLE IF NOT EXISTS Stores(

);

CREATE TABLE IF NOT EXISTS SKUGroup(

);

CREATE TABLE IF NOT EXISTS DateOfAnalysisFormation(

);
