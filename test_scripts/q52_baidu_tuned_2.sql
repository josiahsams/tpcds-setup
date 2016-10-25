-- start query 1 in stream 0 using template query52.tpl
select
  d_year,
  i_brand_id,
  i_brand,
  sum(ss_ext_sales_price) ext_price,
  sum(ss_ext_wholesale_cost) as ext_wholesale_cost,
  sum(ss_ext_list_price) as ext_list_price,
  sum(ss_ext_discount_amt) ext_discount_amt,
  sum(ss_ext_tax) ext_tax
from
  store_sales
  join item on (store_sales.ss_item_sk = item.i_item_sk)
  join date_dim dt on (store_sales.ss_sold_date_sk = dt.d_date_sk)
where
  i_manager_id between 1 and 2
  -- and d_moy = 12
  -- and d_year = 1998
  -- and ss_date between '1998-01-01' and '2001-12-31'
  -- and ss_sold_date_sk between 2450815 and 2452275 -- partition key filter
group by
  d_year,
  i_brand,
  i_brand_id
order by
  d_year,
  ext_price desc,
  i_brand_id
limit 100;
-- end query 1 in stream 0 using template query52.tpl
