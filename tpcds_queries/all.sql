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
-- start query 1 in stream 0 using template query43.tpl
select
  s_store_name,
  s_store_id,
  sum(case when (d_day_name = 'Sunday') then ss_sales_price else null end) sun_sales,
  sum(case when (d_day_name = 'Monday') then ss_sales_price else null end) mon_sales,
  sum(case when (d_day_name = 'Tuesday') then ss_sales_price else null end) tue_sales,
  sum(case when (d_day_name = 'Wednesday') then ss_sales_price else null end) wed_sales,
  sum(case when (d_day_name = 'Thursday') then ss_sales_price else null end) thu_sales,
  sum(case when (d_day_name = 'Friday') then ss_sales_price else null end) fri_sales,
  sum(case when (d_day_name = 'Saturday') then ss_sales_price else null end) sat_sales
from
  store_sales
  join store on (store_sales.ss_store_sk = store.s_store_sk)
  join date_dim on (store_sales.ss_sold_date_sk = date_dim.d_date_sk)
where
  s_gmt_offset = -5
  and d_year between 1998 and 2000
  -- and ss_date between '1998-01-01' and '2000-06-30'
  and ss_sold_date_sk between 2450816 and 2451726  -- partition key filter
group by
  s_store_name,
  s_store_id
order by
  s_store_name,
  s_store_id,
  sun_sales,
  mon_sales,
  tue_sales,
  wed_sales,
  thu_sales,
  fri_sales,
  sat_sales 
limit 100;
-- end query 1 in stream 0 using template query43.tpl
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
-- start query 1 in stream 0 using template query68.tpl
select
  c_last_name,
  c_first_name,
  ca_city,
  bought_city,
  ss_ticket_number,
  extended_price,
  extended_tax,
  list_price
from
  (select
    ss_ticket_number,
    ss_customer_sk,
    ca_city bought_city,
    sum(ss_ext_sales_price) extended_price,
    sum(ss_ext_list_price) list_price,
    sum(ss_ext_tax) extended_tax
  from
    store_sales
    join store on (store_sales.ss_store_sk = store.s_store_sk)
    join household_demographics on (store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk)
    join date_dim on (store_sales.ss_sold_date_sk = date_dim.d_date_sk)
    join customer_address on (store_sales.ss_addr_sk = customer_address.ca_address_sk)
  where
    store.s_city in('Midway', 'Fairview')
    --and date_dim.d_dom between 1 and 2
    --and date_dim.d_year in(1999, 1999 + 1, 1999 + 2)
    -- and ss_date between '1999-01-01' and '2001-12-31'
    -- and dayofmonth(ss_date) in (1,2)
    -- and ss_sold_date_sk in (2451180, 2451181, 2451211, 2451212, 2451239, 2451240, 2451270, 2451271, 2451300, 2451301, 2451331, 
    --                         2451332, 2451361, 2451362, 2451392, 2451393, 2451423, 2451424, 2451453, 2451454, 2451484, 2451485, 
    --                         2451514, 2451515, 2451545, 2451546, 2451576, 2451577, 2451605, 2451606, 2451636, 2451637, 2451666, 
    --                         2451667, 2451697, 2451698, 2451727, 2451728, 2451758, 2451759, 2451789, 2451790, 2451819, 2451820, 
    --                         2451850, 2451851, 2451880, 2451881, 2451911, 2451912, 2451942, 2451943, 2451970, 2451971, 2452001, 
    --                         2452002, 2452031, 2452032, 2452062, 2452063, 2452092, 2452093, 2452123, 2452124, 2452154, 2452155, 
    --                         2452184, 2452185, 2452215, 2452216, 2452245, 2452246)    
        and (household_demographics.hd_dep_count = 5
      or household_demographics.hd_vehicle_count = 3)
    -- and d_date between '1999-01-01' and '2000-06-30'
    -- and ss_sold_date_sk between 2451180 and 2451726 -- partition key filter (18 months)
  group by
    ss_ticket_number,
    ss_customer_sk,
    ss_addr_sk,
    ca_city
  ) dn
  join customer on (dn.ss_customer_sk = customer.c_customer_sk)
  join customer_address current_addr on (customer.c_current_addr_sk = current_addr.ca_address_sk)
where
  current_addr.ca_city <> bought_city
order by
  c_last_name,
  ss_ticket_number 
limit 100;
-- end query 1 in stream 0 using template query68.tpl
-- start query 1 in stream 0 using template query63.tpl
select
  *
from
  (select
    i_manager_id,
    sum(ss_sales_price) sum_sales,
    sum(ss_ext_sales_price) ext_price,
    sum(ss_ext_list_price) as ext_list_price
    -- avg(sum(ss_sales_price)) over(partition by i_manager_id) avg_monthly_sales
  from
    store_sales
    join item on (store_sales.ss_item_sk = item.i_item_sk)
    join store on (store_sales.ss_store_sk = store.s_store_sk)
    join date_dim on (store_sales.ss_sold_date_sk = date_dim.d_date_sk)
  where
    -- ss_sold_date_sk between 2451361 and 2452275  -- partition key filter
    -- ss_date between '1999-07-01' and '2001-12-31'
    d_month_seq in (1212, 1212 + 1, 1212 + 2, 1212 + 3, 1212 + 4, 1212 + 5, 1212 + 6, 1212 + 7, 1212 + 8, 1212 + 9, 1212 + 10, 1212 + 11)
    and (
          (i_category in('Books', 'Children', 'Electronics')
            and i_class in('personal', 'portable', 'refernece', 'self-help')
            and i_brand in('scholaramalgamalg #14', 'scholaramalgamalg #7', 'exportiunivamalg #9', 'scholaramalgamalg #9')
          )
          or 
          (i_category in('Women', 'Music', 'Men')
            and i_class in('accessories', 'classical', 'fragrances', 'pants')
            and i_brand in('amalgimporto #1', 'edu packscholar #1', 'exportiimporto #1', 'importoamalg #1')
          )
        )
  group by
    i_manager_id,
    d_moy
  ) tmp1
-- where
--   case when avg_monthly_sales > 0 then abs(sum_sales - avg_monthly_sales) / avg_monthly_sales else null end > 0.1
order by
  i_manager_id,
  -- avg_monthly_sales,
  sum_sales,
  ext_price,
  ext_list_price
limit 100;
-- end query 1 in stream 0 using template query63.tpl
-- start query 1 in stream 0 using template query68.tpl
select
  c_last_name,
  c_first_name,
  ca_city,
  bought_city,
  ss_ticket_number,
  wholesale_cost,
  list_price,
  sales_price,
  ext_discount_amt,
  extended_price,
  ext_list_price,
  ext_wholesale_cost,
  extended_tax
from
  (select
    ss_ticket_number,
    ss_customer_sk,
    ca_city bought_city,
    sum(ss_wholesale_cost) wholesale_cost,
    sum(ss_list_price) list_price,
    sum(ss_sales_price) sales_price,
    sum(ss_ext_discount_amt) ext_discount_amt,
    sum(ss_ext_sales_price) extended_price,
    sum(ss_ext_list_price) ext_list_price,
    sum(ss_ext_wholesale_cost) ext_wholesale_cost,
    sum(ss_ext_tax) extended_tax
  from
    store_sales
    join store on (store_sales.ss_store_sk = store.s_store_sk)
    join household_demographics on (store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk)
    join date_dim on (store_sales.ss_sold_date_sk = date_dim.d_date_sk)
    join customer_address on (store_sales.ss_addr_sk = customer_address.ca_address_sk)
  where
    store.s_city in('Midway', 'Fairview')
    --and date_dim.d_dom between 1 and 2
    --and date_dim.d_year in(1999, 1999 + 1, 1999 + 2)
    -- and ss_date between '1999-01-01' and '2001-12-31'
    -- and dayofmonth(ss_date) in (1,2)
    -- and ss_sold_date_sk in (2451180, 2451181, 2451211, 2451212, 2451239, 2451240, 2451270, 2451271, 2451300, 2451301, 2451331, 
    --                         2451332, 2451361, 2451362, 2451392, 2451393, 2451423, 2451424, 2451453, 2451454, 2451484, 2451485, 
    --                         2451514, 2451515, 2451545, 2451546, 2451576, 2451577, 2451605, 2451606, 2451636, 2451637, 2451666, 
    --                         2451667, 2451697, 2451698, 2451727, 2451728, 2451758, 2451759, 2451789, 2451790, 2451819, 2451820, 
    --                         2451850, 2451851, 2451880, 2451881, 2451911, 2451912, 2451942, 2451943, 2451970, 2451971, 2452001, 
    --                         2452002, 2452031, 2452032, 2452062, 2452063, 2452092, 2452093, 2452123, 2452124, 2452154, 2452155, 
    --                         2452184, 2452185, 2452215, 2452216, 2452245, 2452246)    
        and (household_demographics.hd_dep_count = 5
      or household_demographics.hd_vehicle_count = 3)
    -- and d_date between '1999-01-01' and '2000-06-30'
    -- and ss_sold_date_sk between 2451180 and 2451726 -- partition key filter (18 months)
  group by
    ss_ticket_number,
    ss_customer_sk,
    ss_addr_sk,
    ca_city
  ) dn
  join customer on (dn.ss_customer_sk = customer.c_customer_sk)
  join customer_address current_addr on (customer.c_current_addr_sk = current_addr.ca_address_sk)
where
  current_addr.ca_city <> bought_city
order by
  c_last_name,
  ss_ticket_number 
limit 100;
-- end query 1 in stream 0 using template query68.tpl
-- start query 1 in stream 0 using template query73.tpl
select
  c_last_name,
  c_first_name,
  c_salutation,
  c_preferred_cust_flag,
  ss_ticket_number,
  cnt
from
  (select
    ss_ticket_number,
    ss_customer_sk,
    count(*) cnt
  from
    store_sales
    join household_demographics on (store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk)
    join store on (store_sales.ss_store_sk = store.s_store_sk)
    -- join date_dim on (store_sales.ss_sold_date_sk = date_dim.d_date_sk)
  where
    store.s_county in ('Saginaw County', 'Sumner County', 'Appanoose County', 'Daviess County')
    -- and date_dim.d_dom between 1 and 2
    -- and date_dim.d_year in(1998, 1998 + 1, 1998 + 2)
    -- and ss_date between '1999-01-01' and '2001-12-02'
    -- and dayofmonth(ss_date) in (1,2)
    -- partition key filter
    -- and ss_sold_date_sk in (2450816, 2450846, 2450847, 2450874, 2450875, 2450905, 2450906, 2450935, 2450936, 2450966, 2450967,
    --                         2450996, 2450997, 2451027, 2451028, 2451058, 2451059, 2451088, 2451089, 2451119, 2451120, 2451149,
    --                         2451150, 2451180, 2451181, 2451211, 2451212, 2451239, 2451240, 2451270, 2451271, 2451300, 2451301,
    --                         2451331, 2451332, 2451361, 2451362, 2451392, 2451393, 2451423, 2451424, 2451453, 2451454, 2451484,
    --                         2451485, 2451514, 2451515, 2451545, 2451546, 2451576, 2451577, 2451605, 2451606, 2451636, 2451637,
    --                         2451666, 2451667, 2451697, 2451698, 2451727, 2451728, 2451758, 2451759, 2451789, 2451790, 2451819,
    --                         2451820, 2451850, 2451851, 2451880, 2451881)
    and (household_demographics.hd_buy_potential = '>10000'
      or household_demographics.hd_buy_potential = 'unknown')
    and household_demographics.hd_vehicle_count > 0
    and case when household_demographics.hd_vehicle_count > 0 then household_demographics.hd_dep_count / household_demographics.hd_vehicle_count else null end > 1
    and ss_sold_date_sk between 2451180 and 2452091 -- partition key filter (30 months)
  group by
    ss_ticket_number,
    ss_customer_sk
  ) dj
  join customer on (dj.ss_customer_sk = customer.c_customer_sk)
where
  cnt between 1 and 5
order by
  cnt desc
limit 1000;
-- end query 1 in stream 0 using template query73.tpl
-- start query 1 in stream 0 using template query98.tpl
select
  i_item_desc,
  i_category,
  i_class,
  i_current_price,
  sum(ss_ext_sales_price) as itemrevenue
  -- sum(ss_ext_sales_price) * 100 / sum(sum(ss_ext_sales_price)) over (partition by i_class) as revenueratio
from
  store_sales 
  join item on (store_sales.ss_item_sk = item.i_item_sk)
  join date_dim on (store_sales.ss_sold_date_sk = date_dim.d_date_sk)
where
  i_category in('Jewelry', 'Sports', 'Books')
  -- and d_date between cast('2001-01-12' as date) and (cast('2001-01-12' as date) + 30)
  -- and d_date between '2001-01-12' and '2001-02-11'
  -- and ss_date between '2001-01-12' and '2001-02-11'
  -- and ss_sold_date_sk between 2451922 and 2451952  -- partition key filter
  and ss_sold_date_sk between 2451911 and 2452183  -- partition key filter (9 calendar months)
  and d_date between '2001-01-01' and '2001-09-30'
group by
  i_item_id,
  i_item_desc,
  i_category,
  i_class,
  i_current_price
order by
  i_category,
  i_class,
  i_item_id,
  i_item_desc
  -- revenueratio
limit 1000;
-- end query 1 in stream 0 using template query98.tpl
