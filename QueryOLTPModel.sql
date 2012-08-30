---------------------------------------------------------------------------------
--Program: QueryOLTPModel
--By: Jon Gibbens
--On: 08/28/2012
--
--Purpose: Build Query
--Database: AdventureWorks
--Tables: Sales.SalesOrderDetail,Production.Product,Production.ProductSubcategory
--        Sales.SalesOrderHeader,Sales.SalesTerritory,Person.Address
--        Person.StateProvince,Sales.Customer
--Constraints: Only US Customers and US Sales Territories
--
--Note: This query returns both Internet and Reseller Sales.  Use output to crosscheck
--      against the QueryDWModelCombinedInternetandResellerSales.sql Output
--
--Output: ZipCode
--        Distinct Buyers
--        Average Amount of Transactions
--        TotalRevenue
--        Most Popular Product Category
--Presentation Notes - should dump to Excel/SSRS to do final formatting
-----------------------------------------------------------------------------------
USE AdventureWorks;
-- Build detail set of data which we will base the rest of our query on
-- We want a line with the quantity,$$,ProductName,Category,CustomerID,ZipCode,etc
WITH AWCTEQuery AS
     ( SELECT    Sales.SalesOrderDetail.OrderQty AS 'OrderQuantity'           ,
                Sales.SalesOrderDetail.LineTotal AS 'Revenue'                 ,
                Sales.SalesOrderDetail.ProductID                              ,
                Production.Product.ProductSubcategoryID                       ,
                Production.ProductSubcategory.Name AS 'ProductSubcategoryName',
                Production.ProductCategory.ProductCategoryID                  ,
                Production.ProductCategory.Name          AS 'ProductCategoryName'      ,
                Sales.SalesTerritory.CountryRegionCode   AS SalesTerritoryCountry      ,
                SUBSTRING(Person.Address.PostalCode,1,5) AS ZipCode                    ,
                Sales.Customer.AccountNumber                                           ,
                OnlineOrderFlag
     FROM       Sales.SalesOrderDetail
                INNER JOIN Production.Product
                ON         Sales.SalesOrderDetail.ProductID = Production.Product.ProductID
                INNER JOIN Production.ProductSubcategory
                ON         Production.Product.ProductSubcategoryID = Production.ProductSubcategory.ProductSubcategoryID
                INNER JOIN Production.ProductCategory
                ON         Production.ProductSubcategory.ProductCategoryID = Production.ProductCategory.ProductCategoryID
                INNER JOIN Sales.SalesOrderHeader
                ON         Sales.SalesOrderDetail.SalesOrderID = Sales.SalesOrderHeader.SalesOrderID
                INNER JOIN Sales.SalesTerritory
                ON         Sales.SalesOrderHeader.TerritoryID = Sales.SalesTerritory.TerritoryID
                INNER JOIN Person.Address
                ON         Sales.SalesOrderHeader.BillToAddressID = Person.Address.AddressID
                INNER JOIN Person.StateProvince
                ON         Person.Address.StateProvinceID = Person.StateProvince.StateProvinceID
                INNER JOIN Sales.Customer
                ON         Sales.SalesOrderHeader.CustomerID = Sales.Customer.CustomerID
                --Only US Sales Territories
     WHERE      Sales.SalesTerritory.CountryRegionCode = 'US'
     AND        Person.StateProvince.CountryRegionCode = 'US'
     )
SELECT   C1.ZipCode                                             ,
         MAX(C2.NumberofBuyers)      AS 'DistinctBuyers'             ,
         AVG(C1.Revenue)             AS 'AverageAmountofTransactions',
         SUM(C1.Revenue)             AS 'TotalRevenue'               ,
         MAX(C3.ProductCategoryName) AS 'MostPopularProductCategory'
FROM     AWCTEQuery                  AS C1
         --Join to go pull the distinct number of buyers (using AccountNumber)
         JOIN
                  (SELECT  ZipCode,
                           COUNT (DISTINCT AccountNumber) AS 'NumberofBuyers'
                  FROM     AWCTEQuery
                  GROUP BY ZipCode
                  )
                  AS C2
         ON       C1.ZipCode = C2.ZipCode
--Join to go pull the most popular product category by zip code
--This is based on the category that has the product with the most quantity ordered
--Use Row_Number/Partition technique to get a list of quantities by Zip
--and then limit it to top 1 per zip code
         JOIN
                  ( SELECT ZipCode           ,
                          ProductCategoryName,
                          TotalOrders
                  FROM    (SELECT  ZipCode                          ,
                                   ProductCategoryName              ,
                                   SUM(OrderQuantity)                                                               AS TotalOrders,
                                   ROW_NUMBER() OVER(PARTITION BY ZipCode ORDER BY ZipCode,SUM(OrderQuantity) DESC) AS Row
                          FROM     AWCTEQuery C4
                          GROUP BY ZipCode,
                                   ProductCategoryName
                          )
                          S
                  WHERE   S.Row=1
                  )
                  AS C3
         ON       C1.ZipCode=C3.ZipCode
GROUP BY C1.ZipCode
ORDER BY C1.ZipCode;