
--1
SELECT O.ShipCity AS CIDADE,
	   ISNULL(O.ShipRegion, 'N/A') AS ESTADO,
       O.ShipCountry AS PAIS,
	   ROUND(SUM((OD.Quantity * OD.UnitPrice) * (1 - OD.Discount)),2) AS TOTAL_VENDA
FROM Orders O
INNER JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY O.ShipCity, O.ShipRegion, O.ShipCountry,
ISNULL(O.ShipRegion, 'N/A')
ORDER BY TOTAL_VENDA DESC

--2
SELECT TOP 10 S.CompanyName AS NOME_EMPRESA ,
		   P.UnitsInStock AS ESTOQUE,
		   P.UnitPrice AS PREÇO_UNIDADE,
           SUM(P.UnitsInStock * P.UnitPrice) AS VALOR_ESTOQUE
FROM Suppliers S
INNER JOIN Products P ON P.SupplierID = S.SupplierID
GROUP BY S.CompanyName,P.UnitsInStock,P.UnitPrice
ORDER BY VALOR_ESTOQUE DESC

--3
SELECT P.ProductName AS PRODUTO,
	   SUM(OD.Quantity * OD.UnitPrice) AS TOTAL_VENDIDO,
	   O.ShipCountry AS PAIS,
	   O.OrderDate AS DATA_VENDA,
	   P.Discontinued AS DISC
FROM Products P
INNER JOIN [Order Details] OD ON OD.ProductID = P.ProductID
INNER JOIN Orders O           ON O.OrderID = OD.OrderID
WHERE P.Discontinued != 0
GROUP BY P.ProductName,
		 O.ShipCountry,
		 O.OrderDate,
		 P.Discontinued
ORDER BY DATA_VENDA DESC


--4
-- A- PRODUTO MAIS VENDIDO POR CATEGORIA DE PRODUTO

SELECT CATEGORIA,
	   PRODUTO,
	   QUANTIDADE_DE_UNIDADES_VENDIDAS,
	   PREÇO_UNIDADE,
	   TOTAL_VENDAS	   
FROM(
SELECT C.CategoryName AS CATEGORIA,
	   P.ProductName  AS PRODUTO,	
	   OD.Quantity    AS QUANTIDADE_DE_UNIDADES_VENDIDAS,
	   P.UnitPrice    AS PREÇO_UNIDADE,
	   ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) AS TOTAL_VENDAS,
	   ROW_NUMBER()over (PARTITION BY C.CategoryName ORDER BY
           ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) DESC) AS PODIO
FROM Categories C
INNER JOIN Products P         ON P.CategoryID = C.CategoryID
INNER JOIN [Order Details] OD ON P.ProductID = OD.ProductID

GROUP BY C.CategoryName, 
         P.ProductName, 
		 OD.Quantity, 
		 P.UnitPrice

) AS PRODUTO_POR_CATEGORIA
WHERE PODIO = 1


--B CATEGORIA MAIS VENDIDA POR PAIS/

SELECT PAIS,
	   CATEGORIA,
	   TOTAL_VENDAS
FROM (
SELECT O.ShipCountry AS PAIS,
	   C.CategoryName AS CATEGORIA,
	   ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) AS TOTAL_VENDAS,
		ROW_NUMBER()over (PARTITION BY O.ShipCountry ORDER BY
           ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) DESC) AS PODIO

FROM Categories C

INNER JOIN Products P         ON P.CategoryID = C.CategoryID
INNER JOIN [Order Details] OD ON OD.ProductID = P.ProductID
INNER JOIN Orders O           ON O.OrderID = OD.OrderID

GROUP BY O.ShipCountry, C.CategoryName
) AS CATEGORIA_PAIS
WHERE PODIO = 1



