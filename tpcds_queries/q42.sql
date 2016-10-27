-- start query 1 in stream 0 using template query42.tpl
select
  d_year,
  i_category_id,
  i_category,
  sum(ss_ext_sales_price) as total_price,
  sum(ss_ext_wholesale_cost) as ext_wholesale_cost,
  sum(ss_ext_list_price) as ext_list_price
from
  store_sales
  join item on (store_sales.ss_item_sk = item.i_item_sk)
  join date_dim dt on (dt.d_date_sk = store_sales.ss_sold_date_sk)
where
  item.i_manager_id = 1
  -- and dt.d_moy between 10 and 12
  -- and dt.d_year = 1998
  -- and ss_date between '1998-01-01' and '2001-12-31'
  -- and ss_sold_date_sk between 2450815 and 2452275  -- partition key filter
group by
  d_year,
  i_category_id,
  i_category
order by
  -- sum(ss_ext_sales_price) desc,
  total_price desc,
  ext_wholesale_cost desc,
  ext_list_price desc,
  d_year,
  i_category_id,
  i_category
limit 100;
-- end query 1 in stream 0 using template query42.tpl
