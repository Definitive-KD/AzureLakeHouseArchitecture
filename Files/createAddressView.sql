CREATE VIEW address
AS
SELECT  
    *
FROM
    OPENROWSET(
        BULK 'https://migrationstorageks.dfs.core.windows.net/gold/SalesLT/Address/',
        FORMAT = 'DELTA'
    ) AS [result]