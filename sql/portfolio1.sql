--- PREPARATION ---
CREATE TABLE raw_sales (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INTEGER,
    InvoiceDate TIMESTAMP,
    UnitPrice NUMERIC(10,2),
    CustomerID INTEGER,
    Country VARCHAR(50)
);

-- Rows Number
select count(*) as row_numbers
from raw_sales rs;

-- data sample
select * from raw_sales rs 
limit 10;

-- missing customer id
select count(*) as missing_customer
from raw_sales rs 
where rs.customerid is null;

-- negative quantity
select count(*) as negative_quantity
from raw_sales rs 
where rs.quantity < 0;

-- zero unitprice
select count(*) as zero_price
from raw_sales rs 
where rs.unitprice = 0;

-- cancel invoice
select count(*) as cancelled_invoice
from raw_sales rs 
where rs.invoiceno ilike '%c%';

-- DATA CLEANNING
create view cleaned_sales as
select
    invoiceno,
    invoicedate,
    customerid,
    stockcode,
    description,
    country,
    quantity,
    unitprice,
    revenue
from (
    select
        invoiceno,
        invoicedate,
        customerid,
        stockcode,
        description,
        country,
        quantity,
        unitprice,
        quantity * unitprice as revenue,
        row_number() over (
            partition by
                invoiceno,
                stockcode,
                invoicedate,
                quantity,
                unitprice,
                customerid
            order by invoicedate
        ) as rn
    from raw_sales
    where customerid is not null
      and quantity > 0
      and unitprice > 0
      and invoiceno not like 'C%'
) t
where rn = 1;

select count(*)
from cleaned_sales cs ;

--fact_table
create view fact_sales as
select
    invoiceno,
    invoicedate,
    customerid,
    stockcode,
    quantity,
    unitprice,
    revenue
from cleaned_sales;

select count(*)
from fact_sales;

-- dimension_table1
create view dim_customer as
select distinct
    customerid,
    country
from cleaned_sales;

-- dimension_table2
create view dim_product as
select distinct
	stockcode,
	description
from cleaned_sales;

--- SQL ANALYSIS ---

-- main kpi
select
    count(distinct invoiceno) as total_orders,
    count(distinct customerid) as total_customers,
    sum(revenue) as total_revenue,
    sum(revenue) / count(distinct invoiceno) as aov
from fact_sales;

-- total rev / country
select
    c.country,
    sum(f.revenue) as total_revenue
from fact_sales f
join dim_customer c
    on f.customerid = c.customerid
group by c.country
order by total_revenue desc;

-- top customer
select
    f.customerid,
    sum(f.revenue) as total_spent,
    count(distinct f.invoiceno) as total_orders
from fact_sales f
group by f.customerid
having count(distinct f.invoiceno) >= 5
order by total_spent desc;

-- customer who total_spent is above average total_spent
select
    customerid,
    total_spent
from (
    select
        customerid,
        sum(revenue) as total_spent
    from fact_sales
    group by customerid
) t
where total_spent > (
    select avg(total_spent)
    from (
        select
            sum(revenue) as total_spent
        from fact_sales
        group by customerid
    ) avg_table
)
order by total_spent desc;

-- monthly sales trend
with monthly_sales as (
    select
        date_trunc('month', invoicedate) as month,
        sum(revenue) as monthly_revenue
    from fact_sales
    group by date_trunc('month', invoicedate)
)
select
    month,
    monthly_revenue,
    monthly_revenue
        - lag(monthly_revenue) over (order by month) as revenue_growth
from monthly_sales
order by month;

-- cust purchasing sequence
select
    customerid,
    invoiceno,
    invoicedate,
    revenue,
    row_number() over (
        partition by customerid
        order by invoicedate
    ) as purchase_sequence
from fact_sales;

-- top 5 product / country
with product_country_sales as (
    select
        c.country,
        p.description,
        sum(f.revenue) as total_revenue
    from fact_sales f
    join dim_customer c
        on f.customerid = c.customerid
    join dim_product p
        on f.stockcode = p.stockcode
    group by c.country, p.description
),
ranked_products as (
    select
        country,
        description,
        total_revenue,
        rank() over (
            partition by country
            order by total_revenue desc
        ) as revenue_rank
    from product_country_sales
)
select
    country,
    description,
    total_revenue,
    revenue_rank
from ranked_products
where revenue_rank <= 5
order by country, revenue_rank;

--- PROBLEM ---
-- karena terdapat customerid yang sama dengan country yang berbeda maka saya memutuskan membuat ulang dim_customer table
-- customerid adalah entitas maka tidak tepat jika menggabungkan customerid + country sebagai "master key" karena akan membelah entitas
-- yang aslinya 1 menjadi 2 padahal satu customerid itu mereprentasikan 1 entitas atau 1 orang atau 1 akun yang sama
-- jadi keputusan saya mengambil country dengan revenue tertinggi untuk setiap customerid

create view dim_customer as
select
    customerid,
    country
from (
    select
        customerid,
        country,
        sum(revenue) as total_revenue,
        rank() over (
            partition by customerid
            order by sum(revenue) desc
        ) as country_rank
    from cleaned_sales
    group by customerid, country
) t
where country_rank = 1;

-- stock code di dim_product juga memiliki duplikasi dikarenakan penulisan value di kolom 'description' berbeda padahal 
-- merujuk pada satu barang yang sama oleh karena itu maka saya akan memilih 'description' yang paling banyak
-- menghasilkan revenue karena menurut saya pilihan ini lebih ke arah "bisnis" ketimbang saya memilih dengan modus dari kolom
-- 'description' untuk setiap stockcode

create view dim_product as
select
    stockcode,
    description
from (
    select
        stockcode,
        description,
        sum(revenue) as total_revenue,
        rank() over (
            partition by stockcode
            order by sum(revenue) desc
        ) as desc_rank
    from cleaned_sales
    group by stockcode, description
) t
where desc_rank = 1;

