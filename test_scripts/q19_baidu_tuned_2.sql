-- start query 1 in stream 0 using template query19.tpl
select
  i_brand_id,
  i_brand,
  i_manufact_id,
  i_manufact,
  sum(ss_ext_sales_price) ext_price,
  sum(ss_ext_list_price) as ext_list_price
from
  store_sales
  join item on (store_sales.ss_item_sk = item.i_item_sk)
  join customer on (store_sales.ss_customer_sk = customer.c_customer_sk)
  join customer_address on (customer.c_current_addr_sk = customer_address.ca_address_sk)
  join store on (store_sales.ss_store_sk = store.s_store_sk)
  join date_dim on (store_sales.ss_sold_date_sk = date_dim.d_date_sk)
where
  --ss_date between '1999-10-01' and '1999-12-31'
  ss_sold_date_sk between 2451453 and 2451544
  and d_moy between 1 and 12
  and d_year = 1999
  and i_manager_id = 7
  and substr(ca_zip, 1, 5) <> substr(s_zip, 1, 5)
group by
  i_brand,
  i_brand_id,
  i_manufact_id,
  i_manufact
order by
  ext_price desc,
  ext_list_price desc,
  i_brand,
  i_brand_id,
  i_manufact_id,
  i_manufact
limit 100;
-- end query 1 in stream 0 using template query19.tpl
