-- aula perdida

--18/02/2025
--EXPLORANDO BANCO DE DADOS VENDAS

SELECT * FROM Customers

--FORNECEDORES
SELECT * FROM Suppliers

-- PEDIDOS DE VENDA
SELECT * FROM Orders

-- MOSTRE TODOS OS PRODUTOS JA VENDIDOS PARA O BRAZIL
-- COLUNAS : CODIGO DO PRODUTO, NOME DO PRODUTO,
-- ORDERNE POR NOME DO PRODUTO

-- O COMANDO DISTINCT NÃO TRARA LINHAS DUPLICADAS
SELECT DISTINCT PROD.ProductID AS CODIGO, PROD.ProductName AS PRODUTO
FROM Products PROD
INNER JOIN [Order Details] OD ON OD.ProductID = PROD.ProductID
INNER JOIN Orders P ON  P.OrderID = OD.OrderID
WHERE 
     P.ShipCountry = 'BRAZIL'
ORDER BY PRODUTO

-- MOSTRE A QUANTIDADE VENDIDA, POR PRODUTO, DE TODOS OS PRODUTOS ENVIADOS 
-- PARA O BRAZIL

SELECT PROD.ProductID AS CODIGO,
       PROD.ProductName AS PRODUTO,
       SUM (OD.Quantity) AS QTD
FROM Products PROD
INNER JOIN [Order Details] OD ON OD.ProductID = PROD.ProductID
INNER JOIN Orders P ON  P.OrderID = OD.OrderID
WHERE 
     P.ShipCountry = 'BRAZIL'
     GROUP BY PROD.ProductID,
     PROD.ProductName
ORDER BY PRODUTO

--GROUP BY TEM QUE USAR OS PRIMEIROS CAMPOS QUE ESTAO NO SELECT

-- MOSTRE A QUANTIDADE DE PRODUTOS FORNECIDA POR FORNECEDOR
-- COLUNAS: CÓDIGO DO PRODUTO, NOME DO PRODUTO, NOME DO FORNECEDOR, QUANTIDADE VENDIDA
-- EX: 001 | QUEIJO MINAS | LATICINIOS SENAI | 1200

SELECT PROD.ProductID CODIGO,
  PROD.ProductName AS NOME_PRODUTO,
  FORNEC.CompanyName, SUM (OD.Quantity) AS QTD_VENDIDA
FROM Products PROD
INNER JOIN Suppliers FORNEC ON FORNEC.SupplierID = PROD.SupplierID
INNER JOIN [Order Details] OD ON OD.ProductID = PROD.ProductID
GROUP BY PROD.ProductID,
         PROD.ProductName,
         FORNEC.CompanyName
ORDER BY FORNEC.CompanyName

-- CRIE UMA CONSULTA QUE MOSTRE AS VENDAS GERAIS POR PAÍS
-- COLUNAS :  DATA DA VENDA,PEDIDO, VENDEDOR, CLIENTE, CIDADE, REGIAO, PAÍS,
-- VALOR TOTAL DA VENDA

SELECT O.OrderDate AS DATA_VENDA, O.OrderID AS PEDIDO,
CONCAT(F.FirstName, '', F.LastName) AS VENDEDOR,
O.ShipName AS CLIENTE, 
O.ShipCity AS CIDADE,
ISNULL ( O.ShipRegion, 'N/A') AS REGIAO,
O.ShipCountry PAIS,
ROUND(SUM((OD.Quantity * OD.UnitPrice) * (1 - OD.Discount)), 2) AS TOTAL_VENDA
FROM Orders O
INNER JOIN Employees F ON F.EmployeeID = O.EmployeeID
INNER JOIN [Order Details] OD ON OD.OrderID = O.OrderID
GROUP BY O.OrderDate,O.OrderID,CONCAT(F.FirstName, '', F.LastName),
O.ShipName,
O.ShipCity,
ISNULL ( O.ShipRegion, 'N/A'),
O.ShipCountry
ORDER BY TOTAL_VENDA

-- CONCAT AGRUPA COLUNAS 
-- ISNULL TROCA O VALOR DO CAMPO QUE ESTA VAZIO OU COALESCE

-- MOSTRE O TOTAL VENDIDO PARA CADA CIDADE
-- COLUNAS: NOME DA CIDADE, NOME DO PAÍS, TOTAL VENDIDO
--EX: SAO PAULO | BRASIL | 150000

SELECT O.ShipCity AS CIDADE,
O.ShipCountry AS PAÍS,
ROUND(SUM((OD.Quantity * OD.UnitPrice) * (1 - OD.Discount)),2) AS TOTAL_VENDA
FROM Orders O
INNER JOIN [Order Details] OD ON OD.OrderID = O.OrderID
GROUP BY 
O.ShipCity,O.ShipCountry
ORDER BY 
TOTAL_VENDA DESC

--CRIE UMA CONSULTA QUE MOSTRE O PRODUTO MAIS VENDIDO POR PAIS
--EXEMPLO: ARGENTINA | VINHO | 12000000
--         BRAZIL    | QUEIJO | 100000

--REANQUEAMENTO DE REGISTROS E SUB CONSULTA
SELECT *
FROM
(
    SELECT O.ShipCountry AS PAÍS , 
           P.ProductName AS PRODUTO, 
           ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) AS TOTAL_VENDAS,
           ROW_NUMBER()over (PARTITION BY O.ShipCountry ORDER BY
           ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) DESC) AS RANKING
    FROM Products P 
    INNER JOIN [Order Details] OD ON P.ProductID = OD.ProductID
    INNER JOIN Orders O           ON OD.OrderID = O.OrderID

    GROUP BY O.ShipCountry,P.ProductName
) AS SUB
WHERE 
SUB.RANKING = 1 /*AND 
SUB.PAÍS NOT IN (SELECT Country FROM Customers WHERE  Country LIKE 'A%')*/
ORDER BY PAÍS


--CTEs - COMMOM TABLE EXPRESSION
WITH RANKING AS
(
     SELECT O.ShipCountry AS PAÍS , 
               P.ProductName AS PRODUTO, 
               ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) AS TOTAL_VENDAS,
               ROW_NUMBER()over (PARTITION BY O.ShipCountry ORDER BY
               ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) DESC) AS RANKING
        FROM Products P 
        INNER JOIN [Order Details] OD ON P.ProductID = OD.ProductID
        INNER JOIN Orders O           ON OD.OrderID = O.OrderID

        GROUP BY O.ShipCountry,P.ProductName
),
TESTE AS 
(
    SELECT *
    FROM Products P
    WHERE P.Discontinued = 0
)
SELECT A.PAÍS, A.PRODUTO, A.TOTAL_VENDAS
FROM RANKING A
WHERE 
    A.RANKING = 1
ORDER BY A.PAÍS 


-- crie uma consulta qu mostre o total em estoque dos produtos
-- exemplo: VINHA | 50 | 10 | 500 |

SELECT P.ProductName AS PRODUTO, P.UnitsInStock AS QTD, P.UnitPrice AS VLR_UNITARIO,
       P.UnitsInStock * P.UnitPrice AS TOTAL_ESTOQUE
FROM Products P 
ORDER BY PRODUTO

--CRIE UMA CONSULTA QUE MOSTRE O VENDEDOR TOP 1 POR PAIS

WITH RANKING AS
(
SELECT O.ShipCountry AS PAÍS,
       CONCAT(F.FirstName, '' , F.LastName) AS VENDEDOR,
       ROUND(SUM((OD.Quantity * OD.UnitPrice) * (1 - OD.Discount)),2) AS TOTAL_VENDA,
       -- CRIANDO RANKING ATRAVÉS DA FUNÇÃO ROW_NUMBER():
       ROW_NUMBER()OVER (PARTITION BY O.ShipCountry ORDER BY
       ROUND(SUM((OD.Quantity * OD.UnitPrice) * (1 - OD.Discount)),2) DESC) AS RANKING
FROM Orders O
INNER JOIN Employees F ON F.EmployeeID = O.EmployeeID
INNER JOIN [Order Details] OD ON  O.OrderID = OD.OrderID
GROUP BY O.ShipCountry, CONCAT(F.FirstName, '' , F.LastName)
)
SELECT A.PAÍS, A.VENDEDOR, A.TOTAL_VENDA 
FROM RANKING A
WHERE
   A.RANKING = 1
ORDER BY A.PAÍS


-- CRIE UMA CONSULTA QUE MSTRE OS 10 PRODUTOS MAIS VENDIDSI PELA EMPREA EM TODO O MUNDO
SELECT TOP 10 P.ProductName AS PRODUTO ,
       SUM(OD.Quantity) AS TOTAL_VENDIDO
FROM [Order Details] OD
INNER JOIN Products P ON P.ProductID = OD.ProductID
GROUP BY P.ProductName
ORDER BY TOTAL_VENDIDO DESC

--CRIE A MSMS CONSULTA ACIMA ACIMA MAS AGORA TRAZENDO OS 10 PRODUTOS QUE MAS FATURARAM
--23/09
SELECT TOP 10 P.ProductName AS PRODUTO,
    ROUND(SUM((OD.Quantity * OD.UnitPrice) * (1- OD.Discount)), 2) AS TOTAL_VENDA
FROM Products P
INNER JOIN [Order Details] OD ON OD.ProductID = P.ProductID
GROUP BY P.ProductName

--faça uma consulta acima porem trazendo somente os produtos com faturamento total

SELECT P.ProductName AS PRODUTO,
    ROUND(SUM((OD.Quantity * OD.UnitPrice) * (1- OD.Discount)), 2) AS TOTAL_VENDA
FROM Products P
INNER JOIN [Order Details] OD ON OD.ProductID = P.ProductID
GROUP BY P.ProductName
HAVING ROUND(SUM((OD.Quantity * OD.UnitPrice) * (1- OD.Discount)), 2) >=20000
ORDER BY TOTAL_VENDA DESC
--HAVING É USADO EXCLUSIVAMENTE PARA FILTRAR FUNÇOES DE AGREGAÇÃO



--CRIE UMA VIEW FISICA NO BANCO DE DADOS 
--CRIE UMA VIEW QUE MOSTRE O RANKING DE PRODUTOS MAIS VENDIDO POR PAIS

--CRIANDO VIEW
--CREATE VIEW V_PRODUTOS_POR_PAIS AS 
SELECT O.ShipCountry AS PAÍS , 
       P.ProductName AS PRODUTO, 
       ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) AS TOTAL_VENDAS,
       ROW_NUMBER()over (PARTITION BY O.ShipCountry ORDER BY
       ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) DESC) AS RANKING
FROM Products P 
INNER JOIN [Order Details] OD ON P.ProductID = OD.ProductID
INNER JOIN Orders O           ON OD.OrderID = O.OrderID
GROUP BY O.ShipCountry,P.ProductName

--SELECIONANDO VIEW
--SELECT *
--FROM V_PRODUTOS_POR_PAIS


-- TESTES 
-------------------ESTADO----------
SELECT ESTADO,
	   CATEGORIA,
	   TOTAL_VENDAS
FROM (
SELECT O.ShipRegion AS ESTADO,
	   C.CategoryName AS CATEGORIA,
	   ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) AS TOTAL_VENDAS,
		ROW_NUMBER()over (PARTITION BY O.ShipRegion ORDER BY
           ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) DESC) AS PODIO

FROM Categories C

INNER JOIN Products P         ON P.CategoryID = C.CategoryID
INNER JOIN [Order Details] OD ON OD.ProductID = P.ProductID
INNER JOIN Orders O           ON O.OrderID = OD.OrderID

GROUP BY O.ShipRegion, C.CategoryName
) AS CATEGORIA_PAIS
WHERE PODIO = 1

-----------------CIDADE---------------

SELECT CIDADE,
	   CATEGORIA,
	   TOTAL_VENDAS
FROM (
SELECT O.ShipCity AS CIDADE,
	   C.CategoryName AS CATEGORIA,
	   ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) AS TOTAL_VENDAS,
		ROW_NUMBER()over (PARTITION BY O.ShipCity ORDER BY
           ROUND(SUM((OD.Quantity*OD.UnitPrice) * (1 - OD.Discount)), 2) DESC) AS PODIO

FROM Categories C

INNER JOIN Products P         ON P.CategoryID = C.CategoryID
INNER JOIN [Order Details] OD ON OD.ProductID = P.ProductID
INNER JOIN Orders O           ON O.OrderID = OD.OrderID

GROUP BY O.ShipCity, C.CategoryName
) AS CATEGORIA_PAIS
WHERE PODIO = 1
