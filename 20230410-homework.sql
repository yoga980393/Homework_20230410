-- 找出和最貴的產品同類別的所有產品

with Expensive as (
	select top 1
		CategoryID
	from Products
	order by UnitPrice DESC
)
select
	*
from Products p
join Expensive e on p.CategoryID = e.CategoryID 

-- 找出和最貴的產品同類別最便宜的產品

with Expensive as (
	select top 1
		CategoryID
	from Products
	order by UnitPrice DESC
)
select top 1
	*
from Products p
join Expensive e on p.CategoryID = e.CategoryID 
order by UnitPrice

-- 計算出上面類別最貴和最便宜的兩個產品的價差

with ExpensiveType as (
	select top 1
		CategoryID
	from Products
	order by UnitPrice DESC
),
Expensive as (
	select top 1
		p.CategoryID, p.UnitPrice
	from Products p
	join ExpensiveType et on p.CategoryID = et.CategoryID 
	order by UnitPrice DESC
),
Cheap as (
	select top 1
		p.CategoryID, p.UnitPrice
	from Products p
	join ExpensiveType et on p.CategoryID = et.CategoryID 
	order by UnitPrice
)
select
	e.UnitPrice - c.UnitPrice as gap
from Expensive e, Cheap c;

-- 找出沒有訂過任何商品的客戶所在的城市的所有客戶

with NoOrderCities as (
	select distinct
		c.City
	from Customers c
	left join Orders o on c.CustomerID = o.CustomerID
	where o.CustomerID is null
)
select 
	*
from Customers c
where c.City in (select City from NoOrderCities)

-- 找出第 5 貴跟第 8 便宜的產品的產品類別

with ProductsRanked as (
    select 
		*,
        row_number() over (order by UnitPrice desc) as PriceRankDescending,
        row_number() over (order by UnitPrice asc) as PriceRankAscending
    from Products
)
select 
	c.CategoryName
from ProductsRanked p
join Categories c on p.CategoryID = c.CategoryID
where PriceRankDescending = 5 or PriceRankAscending = 8;

-- 找出誰買過第 5 貴跟第 8 便宜的產品

with ProductsRanked as (
    select 
		*,
        row_number() over (order by UnitPrice desc) as PriceRankDescending,
        row_number() over (order by UnitPrice asc) as PriceRankAscending
    from Products
)
select distinct
	c.CompanyName
from ProductsRanked p
join [Order Details] od on p.ProductID = od.ProductID
join Orders o on od.OrderID = o.OrderID
join Customers c on o.CustomerID = c.CustomerID
where PriceRankDescending = 5 or PriceRankAscending = 8

-- 找出誰賣過第 5 貴跟第 8 便宜的產品

with ProductsRanked as (
    select 
		*,
        row_number() over (order by UnitPrice desc) as PriceRankDescending,
        row_number() over (order by UnitPrice asc) as PriceRankAscending
    from Products
)
select
	s.CompanyName
from ProductsRanked p
join Suppliers s on p.SupplierID = s.SupplierID
where PriceRankDescending = 5 or PriceRankAscending = 8

-- 找出 13 號星期五的訂單 (惡魔的訂單)

select
	*
from Orders
where DATEPART(day, OrderDate) = 13
and DATEPART(WEEKDAY, OrderDate) = 6

-- 找出誰訂了惡魔的訂單

with DevilOrder as (
	select
		*
	from Orders
	where DATEPART(day, OrderDate) = 13
	and DATEPART(WEEKDAY, OrderDate) = 6
)
select
	*
from Customers c
join DevilOrder d on c.CustomerID = d.CustomerID

-- 找出惡魔的訂單裡有什麼產品

with DevilOrder as (
	select
		*
	from Orders
	where DATEPART(day, OrderDate) = 13
	and DATEPART(WEEKDAY, OrderDate) = 6
)
select 
	*
from DevilOrder d
join [Order Details] od on d.OrderID = od.OrderID

-- 列出從來沒有打折 (Discount) 出售的產品

select p.*
from Products p
where p.ProductID not in (
    select od.ProductID
    from [Order Details] od
    where od.Discount > 0
)

-- 列出購買非本國的產品的客戶

select
	c.CompanyName
from Customers c
join Orders o on c.CustomerID = o.CustomerID
join [Order Details] od on o.OrderID = od.OrderID
join Products p on od.ProductID = p.ProductID
join Suppliers s on p.SupplierID = s.SupplierID
where c.Country <> s.Country
group by c.CompanyName

-- 列出在同個城市中有公司員工可以服務的客戶

select
	c.CompanyName
from Customers c
join Orders o on c.CustomerID = o.CustomerID
join Employees e on o.EmployeeID = e.EmployeeID
where c.City = e.City
group by c.CompanyName

-- 列出那些產品沒有人買過

select p.*
from Products p
where p.ProductID not in (
    select distinct od.ProductID
    from [Order Details] od
)

----------------------------------------------------------------------------------------
-- 列出所有在每個月月底的訂單

select
	*
from Orders
where OrderDate = EOMONTH(OrderDate)

-- 列出每個月月底售出的產品

select
	p.ProductName
from Orders o
join [Order Details] od on o.OrderID = od.OrderID
join Products p on od.ProductID = p.ProductID
where OrderDate = EOMONTH(OrderDate)

-- 找出有敗過最貴的三個產品中的任何一個的前三個大客戶

with Top3ExpensiveProducts as (
    select top 3*
    from Products
    order by UnitPrice desc
)
select top 3
	c.CompanyName, sum(od.UnitPrice * od.Quantity) as TotalAmount
from Customers c
join Orders o on c.CustomerID = o.CustomerID
join [Order Details] od on o.OrderID = od.OrderID
join Top3ExpensiveProducts t3 on od.ProductID = t3.ProductID
group by c.CompanyName
order by TotalAmount desc

-- 找出有敗過銷售金額前三高個產品的前三個大客戶

with Top3SalesProducts as (
    select top 3
		p.ProductID, sum(od.Quantity * od.UnitPrice) as sales
    from Products p
	join [Order Details] od on p.ProductID = od.ProductID
	group by p.ProductID
	order by sales desc
)
select top 3
	c.CompanyName, sum(od.UnitPrice * od.Quantity) as TotalAmount
from Customers c
join Orders o on c.CustomerID = o.CustomerID
join [Order Details] od on o.OrderID = od.OrderID
join Top3SalesProducts t3 on od.ProductID = t3.ProductID
group by c.CompanyName
order by TotalAmount desc

-- 找出有敗過銷售金額前三高個產品所屬類別的前三個大客戶

with Top3SalesProducts as (
    select top 3
		p.ProductID, sum(od.Quantity * od.UnitPrice) as sales
    from Products p
	join [Order Details] od on p.ProductID = od.ProductID
	group by p.ProductID
	order by sales desc
),
Top3SalesProductsType as (
	select 
		p.CategoryID
	from Products p
	join Top3SalesProducts t3 on p.ProductID = t3.ProductID
)
select top 3
	c.CompanyName, sum(od.UnitPrice * od.Quantity) as TotalAmount
from Customers c
join Orders o on c.CustomerID = o.CustomerID
join [Order Details] od on o.OrderID = od.OrderID
join Products p on od.ProductID = p.ProductID
join Top3SalesProductsType t3 on p.CategoryID = t3.CategoryID
group by c.CompanyName
order by TotalAmount desc

-- 列出消費總金額高於所有客戶平均消費總金額的客戶的名字，以及客戶的消費總金額

with CustomerTotalAmount as (
	select
		c.CompanyName, sum(od.UnitPrice * od.Quantity) as TotalAmount
	from Customers c
	join Orders o on c.CustomerID = o.CustomerID
	join [Order Details] od on o.OrderID = od.OrderID
	group by c.CompanyName
)
select
	c.CompanyName
from CustomerTotalAmount c
where c.TotalAmount > (select avg(TotalAmount) from CustomerTotalAmount)

-- 列出最熱銷的產品，以及被購買的總金額

with ProductSales as (
	select 
		p.ProductName, sum(od.UnitPrice * od.Quantity) as Sales
	from [Order Details] od
	join Products p on od.ProductID = p.ProductID
	group by p.ProductID, p.ProductName
)
select
	ProductName, Sales
from ProductSales 
where Sales = (select max(Sales) from ProductSales)

-- 列出最少人買的產品

with ProductNumberOfPurchases as (
	select
		p.ProductName, count(*) as NumberOfPurchases
	from [Order Details] od
	join Products p on od.ProductID = p.ProductID
	group by p.ProductID, p.ProductName
)
select
	ProductName
from ProductNumberOfPurchases
where NumberOfPurchases = (select min(NumberOfPurchases) from ProductNumberOfPurchases)

-- 列出最沒人要買的產品類別 (Categories)

with ProductNumberOfPurchases as (
	select
		p.ProductID, p.ProductName, count(*) as NumberOfPurchases
	from [Order Details] od
	join Products p on od.ProductID = p.ProductID
	group by p.ProductID, p.ProductName
)
select
	c.CategoryName
from ProductNumberOfPurchases pn
join Products p on pn.ProductID = p.ProductID
join Categories c on p.CategoryID = c.CategoryID
where pn.NumberOfPurchases = (select min(NumberOfPurchases) from ProductNumberOfPurchases)

-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (含購買其它供應商的產品)

with SupplierSales as (
	select top 1
		s.SupplierID, s.CompanyName, sum(od.UnitPrice * od.Quantity) as Sales
	from Suppliers s
	join Products p on s.SupplierID = p.SupplierID
	join [Order Details] od on p.ProductID = od.ProductID
	group by s.SupplierID, s.CompanyName 
	order by Sales desc
),
PeopleWhoHaveBought as (
	select
		c.CustomerID, c.CompanyName
	from [Order Details] od
	join Products p on od.ProductID = p.ProductID
	join Orders o on od.OrderID = o.OrderID
	join Customers c on o.CustomerID = c.CustomerID
	where p.SupplierID = (select SupplierID from SupplierSales)
	group by c.CustomerID, c.CompanyName
)
select top 1
	c.CompanyName, sum(od.UnitPrice * od.Quantity) as Amount
from Customers c
join Orders o on c.CustomerID = o.CustomerID
join [Order Details] od on o.OrderID = od.OrderID
where c.CustomerID in (select CustomerID from PeopleWhoHaveBought)
group by c.CustomerID, c.CompanyName
order by Amount desc

-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (不含購買其它供應商的產品)

with SupplierSales as (
	select top 1
		s.SupplierID, s.CompanyName, sum(od.UnitPrice * od.Quantity) as Sales
	from Suppliers s
	join Products p on s.SupplierID = p.SupplierID
	join [Order Details] od on p.ProductID = od.ProductID
	group by s.SupplierID, s.CompanyName 
	order by Sales desc
)
select top 1
	c.CustomerID, c.CompanyName, sum(od.UnitPrice * od.Quantity) as Amount
from [Order Details] od
join Products p on od.ProductID = p.ProductID
join Orders o on od.OrderID = o.OrderID
join Customers c on o.CustomerID = c.CustomerID
where p.SupplierID = (select SupplierID from SupplierSales)
group by c.CustomerID, c.CompanyName
order by Amount desc

-- 列出那些產品沒有人買過

with ProductNumberOfPurchases as (
	select
		p.ProductID, p.ProductName, count(*) as NumberOfPurchases
	from [Order Details] od
	join Products p on od.ProductID = p.ProductID
	group by p.ProductID, p.ProductName
)
select
	ProductName
from ProductNumberOfPurchases
where NumberOfPurchases = 0

-- 列出沒有傳真 (Fax) 的客戶和它的消費總金額

select
	c.CustomerID, c.CompanyName, sum(od.UnitPrice * od.Quantity) as Amount
from Customers c
join Orders o on c.CustomerID = o.CustomerID
join [Order Details] od on o.OrderID = od.OrderID
where c.Fax is not null
group by c.CustomerID, c.CompanyName

-- 列出每一個城市消費的產品種類數量

select
	c.City, count(distinct p.ProductID) as NumberOfProductCategories
from Customers c
join Orders o on c.CustomerID = o.CustomerID
join [Order Details] od on o.OrderID = od.OrderID
join Products p on od.ProductID = p.ProductID
group by c.City

-- 列出目前沒有庫存的產品在過去總共被訂購的數量

select
	p.ProductName, sum(od.Quantity) as Quantity
from Products p
join [Order Details] od on p.ProductID = od.ProductID
where p.UnitsInStock = 0
group by p.ProductID, p.ProductName

-- 列出目前沒有庫存的產品在過去曾經被那些客戶訂購過

select
	c.CompanyName
from Products p
join [Order Details] od on p.ProductID = od.ProductID
join Orders o on od.OrderID = o.OrderID
join Customers c on o.CustomerID = c.CustomerID
where p.UnitsInStock = 0
group by c.CustomerID, c.CompanyName;

-- 列出每位員工的下屬的業績總金額

with SubordinatesSales as(
	select
		 e.EmployeeID as ManagerID, sub.EmployeeID, sum(od.UnitPrice * od.Quantity) as Achievement
	from Employees e
	join Orders o on e.EmployeeID = o.EmployeeID
	join [Order Details] od on o.OrderID = od.OrderID
	right join Employees sub on e.EmployeeID = sub.ReportsTo
	group by e.EmployeeID, sub.EmployeeID
)
select
	ManagerID, sum(Achievement) as TotalAchievement
from SubordinatesSales
where ManagerID is not null
group by ManagerID;

-- 列出每家貨運公司運送最多的那一種產品類別與總數量

with ShipperCategoryAmount as (
  select
    s.shipperid,
    s.companyname,
    c.categoryid,
    c.categoryname,
    sum(od.quantity) as TotalAmount
  from shippers s
  join orders o on s.shipperid = o.shipvia
  join [order details] od on o.orderid = od.orderid
  join products p on od.productid = p.productid
  join categories c on p.categoryid = c.categoryid
  group by s.shipperid, s.companyname, c.categoryid, c.categoryname
),
ShipperMaxAmount as (
  select
    shipperid,
    max(TotalAmount) as MaxAmount
  from ShipperCategoryAmount
  group by shipperid
)
select
  sca.shipperid,
  sca.companyname,
  sca.categoryname,
  sca.totalamount
from ShipperCategoryAmount sca
join ShipperMaxAmount sma on sca.shipperid = sma.shipperid and sca.TotalAmount = sma.MaxAmount

-- 列出每一個客戶買最多的產品類別與金額
with CustomerBoughtType as (
	select
		c.CustomerID, p.CategoryID, c.CompanyName, sum(od.UnitPrice * od.Quantity) as LumpSum, sum(od.Quantity) as SumQuantity
	from Customers c
	join Orders o on c.CustomerID = o.CustomerID
	join [Order Details] od on o.OrderID = od.OrderID
	join Products p on od.ProductID = p.ProductID
	join Categories ca on p.CategoryID = ca.CategoryID
	group by c.CustomerID, p.CategoryID, c.CompanyName
),
CustomerMaxQuantity as (
	select
		CustomerID, MAX(SumQuantity) as MaxQuantity
	from CustomerBoughtType
	group by CustomerID
)
select 
	cbt.CustomerID, cbt.CompanyName, cbt.LumpSum
from CustomerBoughtType cbt
join CustomerMaxQuantity cmq on cbt.CustomerID = cmq.CustomerID and cbt.SumQuantity = cmq.MaxQuantity;

-- 列出每一個客戶買最多的那一個產品與購買數量

with CustomerBoughtQuantity as (
	select
		c.CustomerID, p.ProductID, p.ProductName, sum(od.Quantity) as Quantity
	from Customers c
	join Orders o on c.CustomerID = o.CustomerID
	join [Order Details] od on o.OrderID = od.OrderID
	join Products p on od.ProductID = p.ProductID
	group by c.CustomerID, p.ProductID, p.ProductName
),
CustomerMaxBoughtQuantity as (
	select
		CustomerID, max(Quantity) as MaxQuantity
	from CustomerBoughtQuantity 
	group by CustomerID
)
select
	cbq.CustomerID, cbq.ProductName, cbq.Quantity
from CustomerBoughtQuantity cbq
join CustomerMaxBoughtQuantity cmbq on cbq.CustomerID = cmbq.CustomerID and cbq.Quantity = cmbq.MaxQuantity
order by cbq.CustomerID

-- 按照城市分類，找出每一個城市最近一筆訂單的送貨時間

with CityOrders as (
    select
        c.City,
        o.OrderID,
        o.ShippedDate,
		ROW_NUMBER() over (partition by City order by o.ShippedDate desc) as ShippedDateRank
    from Customers c
    join Orders o on c.CustomerID = o.CustomerID
)
select
    City,
    ShippedDate
from CityOrders
where ShippedDateRank = 1

-- 列出購買金額第五名與第十名的客戶，以及兩個客戶的金額差距

with CustomerTotalAmount as (
	select
		c.CustomerID, 
		c.CompanyName, 
		sum(od.UnitPrice * od.Quantity) as TotalAmount
	from Customers c
	join Orders o on c.CustomerID = o.CustomerID
	join [Order Details] od on o.OrderID = od.OrderID
	group by c.CustomerID, c.CompanyName
),
CustomerAmountRank as (
	select
		CustomerID, CompanyName, TotalAmount,
		ROW_NUMBER() over (order by TotalAmount desc) as AmountRank
	from CustomerTotalAmount
)
select
	c1.CompanyName as FifthPlaceName, c1.TotalAmount as FifthPlaceAmount,
	c2.CompanyName as TenthPlaceName, c2.TotalAmount as TenthPlaceAmount,
	c1.TotalAmount - c2.TotalAmount as AmountDifference
from CustomerAmountRank c1, CustomerAmountRank c2
where c1.AmountRank = 5 and c2.AmountRank = 10;
