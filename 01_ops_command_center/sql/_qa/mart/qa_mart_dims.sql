-- SKU dimension
select count(*) from mart.dim_sku;

-- Duplicate SKUs
select sku, count(*)
from mart.dim_sku
group by 1
having count(*) > 1;

-- Null SKUs
select count(*) as null_sku_rows
from mart.dim_sku
where sku is null;