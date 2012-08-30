---------------------------------------------------------------------------------
--Program: QueryDWModelCombinedInternetandResellerSales
--By: Jon Gibbens
--On: 08/28/2012
--
--Purpose: Build Query
--Database: AdventureWorksDW2008R2 - FACTInternetSales
--          AdventureWorksDW2008R2 - FACTResellerSales
--Tables: FACTInternetSales, FACTResellerSales
--Constraints: Only US Customers and US Sales Territories
--
--Output: ZipCode
--        Distinct Buyers
--        Average Amount of Transactions
--        TotalRevenue
--        Most Popular Product Category
--Presentation Notes - should dump to Excel/SSRS to do final formatting
-----------------------------------------------------------------------------------
USE AdventureWorksDW2008R2;
-- Build detail set of data which we will base the rest of our query on
-- We want a line with the quantity,$$,ProductName,Category,CustomerID,ZipCode,etc

WITH CTEQuery AS
     ( SELECT   FIS.OrderQuantity                                                      ,
                FIS.SalesAmount                                             AS Revenue  ,
                DP.ProductKey                                                           ,
                DP.EnglishProductName                                                   ,
                DP.ProductSubcategoryKey                                                ,
                DPSC.EnglishProductSubcategoryName                                      ,
                DPCAT.EnglishProductCategoryName                                        ,
                SUBSTRING(DG.PostalCode,1,5) AS ZipCode                                 ,
                DG.StateProvinceCode                                                    ,
                DCUST.CustomerKey                                                       ,
                CustomerAlternateKey                                                    ,
                DIMSalesTerritory.SalesTerritoryCountry
     FROM       FactInternetSales FIS
                INNER JOIN DimProduct DP
                ON         FIS.ProductKey = DP.ProductKey
                INNER JOIN DimProductSubCategory DPSC
                ON         DP.ProductSubcategoryKey = DPSC.ProductSubcategoryKey
                INNER JOIN DimProductCategory DPCAT
                ON         DPSC.ProductCategoryKey = DPCAT.ProductCategoryKey
                INNER JOIN DimCustomer DCUST
                ON         FIS.CustomerKey = DCUST.CustomerKey
                INNER JOIN DimGeography DG
                ON         DCUST.GeographyKey = DG.GeographyKey
                INNER JOIN DimSalesTerritory
                ON         FIS.SalesTerritoryKey = DimSalesTerritory.SalesTerritoryKey
                --Select only US customers and US Sales Territories
     WHERE      DG.CountryRegionCode  = 'US'
     AND        SalesTerritoryCountry = 'United States'
     
     UNION ALL
     
     SELECT     FRS.OrderQuantity                                                       ,
                FRS.SalesAmount                                             AS Revenue  ,
                DP.ProductKey                                                           ,
                DP.EnglishProductName                                                   ,
                DP.ProductSubcategoryKey                                                ,
                DPSC.EnglishProductSubcategoryName                                      ,
                DPCAT.EnglishProductCategoryName                                        ,
                SUBSTRING(DG.PostalCode,1,5) AS ZipCode                                 ,
                DG.StateProvinceCode                                                    ,
                DRES.ResellerKey                                                        ,
                ResellerAlternateKey                                                    ,
                DIMSalesTerritory.SalesTerritoryCountry
     FROM       FactResellerSales FRS
                INNER JOIN DimProduct DP
                ON         FRS.ProductKey = DP.ProductKey
                INNER JOIN DimProductSubCategory DPSC
                ON         DP.ProductSubcategoryKey = DPSC.ProductSubcategoryKey
                INNER JOIN DimProductCategory DPCAT
                ON         DPSC.ProductCategoryKey = DPCAT.ProductCategoryKey
                INNER JOIN DimReseller DRES
                ON         FRS.ResellerKey = DRES.ResellerKey
                INNER JOIN DimGeography DG
                ON         DRES.GeographyKey = DG.GeographyKey
                INNER JOIN DimSalesTerritory
                ON         FRS.SalesTerritoryKey = DimSalesTerritory.SalesTerritoryKey
                --Select only US resellers and US Sales Territories
     WHERE      DG.CountryRegionCode  = 'US'
     AND        SalesTerritoryCountry = 'United States'
     )
--Output Query -      
SELECT   C1.ZipCode                                             ,
         MAX(C2.NumberofBuyers)             AS 'DistinctBuyers'             ,
         AVG(C1.REVENUE)                    AS 'AverageAmountofTransactions',
         SUM(C1.REVENUE)                    AS 'TotalRevenue'               ,
         MAX(C3.EnglishProductCategoryName) AS 'MostPopularProductCategory'
FROM     CTEQuery                           AS C1
--Join to go pull the distinct number of buyers (using the CustomerAlternateKey)
JOIN
(SELECT  ZipCode,
         COUNT (DISTINCT CustomerAlternateKey) AS 'NumberofBuyers'
FROM     CTEQuery
GROUP BY ZipCode
)
AS C2 ON C1.ZipCode = C2.ZipCode
--Join to go pull the most popular product category by zip code
--This is based on the category that has the product with the most quantity ordered
--Use Row_Number/Partition technique to get a list of quantities by Zip
--and then limit it to top 1 per zip code
JOIN
( SELECT ZipCode                  ,
        EnglishProductCategoryName,
        TotalOrders
FROM    (SELECT  ZipCode                          ,
                 EnglishProductCategoryName       ,
                 SUM(OrderQuantity)                                                               AS TotalOrders,
                 ROW_NUMBER() OVER(PARTITION BY ZipCode ORDER BY ZipCode,SUM(OrderQuantity) DESC) AS Row
        FROM     CTEQuery C4
        GROUP BY ZipCode,
                 EnglishProductCategoryName
        )
        S
WHERE   S.Row=1
)
AS C3 ON C1.ZipCode=C3.ZipCode
GROUP BY C1.ZipCode 
ORDER BY C1.ZipCode;