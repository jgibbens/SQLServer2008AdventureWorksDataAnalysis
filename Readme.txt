AdventureWorks Data/Query Exercises  –  Jon Gibbens – jon@jgibbens.com

Databases used:  AdventureWorks and AdventureWorks2008DW

Task: Determine the following measures – Summary by Postal/Zip Code 
o	The number of distinct buyers
o	The average amount of transactions
o	The total revenue
o	The most popular product category (top level in the product hierarchy)
Selection: US territories only 

Analyst’s Initial Assessment/Opinions
      The reason for asking for these numbers from both databases is that the standard AdventureWorks2008 
database is more of an OLTP database (ie..highly normalized, set up for optimal update performance) while the 
AdventureWorks2008DW database is a dimensional/reporting model – with denormalized attributes in 
dimensions,etc. It takes a slightly different style of SQL to pull data from the OLTP vs the dimensional. 

Analyst’s Assumptions
*	These numbers are time-agnostic – they pull from the entire time period of the database
*	Distinct Buyers – we use the Unique Identifiers CustomerAlternateKey and ResellerAlternateKey in the 
AdventureWorks2008DW database and the Sales.Customer.AccountNumber field from the 
AdventureWorks2008 database to identify unique customers.
*	Average Amount of Transactions = Average Revenue (see below for Revenue Definition)
*	Revenue = (Price of the Product Sold * Quantity Sold) * (1-UnitPriceDiscount%).
o	In AdventureWorks2008DW the SalesAmount field uses the above calculation
o	In AdventureWorks the LineTotal field uses the above calculation
*	Since some values of the ZipCode field can have 9 characters – all ZipCodes have been standardized to 5 
characters – this avoids messy extra rows in the output data.
*	Most Popular Product Category = The category with the most quantity of products sold (not necessarily 
the highest $$ amount).  For purposes of uniformity in reporting any ties in the top category (ie..2 
categories both have the same number of products sold – and they are the top ones) are not handled.  If 
they were then there would be more than 1 row in the output for certain zip codes. The first row 
alphabetically gets displayed in these situations
*	The numbers coming out of AdventureWorks will bottom line tie with those coming out of 
AdventureWorks2008DW – provided that the results from FactInternetSales and FactResellerSales are 
combined.
*	There is a slight rounding error in EXCEL ONLY if the bottom line totals are summed after changing 
the format of the fields to be Currency (2 digits after the decimal point).  This problem exists in Excel 
only – the actual raw data ties 100%.  
*	The above assumptions are based on a short list of report requirements – some creative license had to be 
taken with them in order to meet project time constraints.    
Data Deliverables
o	Readme.doc – this document
o	DWResults.xls – Has 3 tabs which hold the results of each of the QueryDWModel*.sql files.  The first tab 
is the one that is the most important, the other 2 are for data verification/validation purposes.
o	OLTPResults.xls – Holds the results of the QueryOLTPModel.sql – ties to the CombinedResults tab of 
the DWResults.xls file.
o	QueryDWModelCombinedInternetandResellerSales.sql – SQL Code against AdventureWorks2008DW 
which combines InternetSales and ResellerSales into final output.
o	QueryDWModelFactResellerSales.sql – SQL Code against AdventureWorks2008DW which pulls for 
Reseller Sales – use output to correlate the final result.
o	QueryDWModelFactInternetSales.sql  - SQL code against AdventureWorks2008DW which pulls for 
Internet Sales – use output to correlate the final results.
o	QueryOLTPModel.sql – SQL Code against AdventureWorks (OLTP version). 
