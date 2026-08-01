/*
Project: Subscriber Cohort & Retention Analysis
File: 02_data_analysis_base.sql
purpose: Create base view for data analysis
*/

--list.
-- 1. Monthly new subscribers
-- 2. Retention rate by cohort month
-- 3. Churn rates
-- 4. Which subscriber segments show higher churn risk?

-- How many new customers were acquired each month? = Monthly new subscribers
create or replace view vw_first_subscription as 
select
	account_id,
	start_date,
	min(start_month) as first_subscription_month
from vw_clean_subscription
group by account_id, start_date;

-- What percentages of customer remained after their first subscribe?
-- Percentage of customer remained after their subscribe
-- final version of retention rate view
create or replace view retention_6m as 
with base as (
select
	s.account_id,
	min(s.start_month) as cohort_month,
	min(c.churn_month) as end_subscribe
from vw_clean_subscription as s
left join vw_clean_churn_event as c
	on s.account_id = c.account_id
group by s.account_id
),
retention_base as (
select
	account_id,
	cohort_month,
	end_subscribe as end_month,
	(cohort_month + interval '1 month') as retain_1month,
	case
		when end_subscribe is null or end_subscribe > cohort_month + interval '1 month' 
		then 1
		else 0
	end as retained_status_1m,
	(cohort_month + interval '3month') as retain_3month,
	case
		when end_subscribe is null or end_subscribe > cohort_month + interval '3month'
		then 1
		else 0
	end as retained_status_3m,
	(cohort_month + interval '6month') as retained_6month,
	case
		when end_subscribe is null or end_subscribe > cohort_month + interval '6month'
		then 1
		else 0
	end as retained_status_6m
from base
where cohort_month + interval '6month' <= '2024-12-31'
)
select
	cohort_month,
	count(*) as cohort_size,
	sum(retained_status_1m) as retained_customer_1m,
	sum(retained_status_3m) as retained_customer_3m,
	sum(retained_status_6m) as retained_customer_6m,
	round(100.0 * sum(retained_status_1m) / nullif(count(*),0),2) as retained_1m_rate,
	round(100.0 * sum(retained_status_3m) / nullif(count(*),0),2) as retained_3m_rate,
	round(100.0 * sum(retained_status_6m) / nullif(count(*),0),2) as retained_6m_rate
from retention_base
group by cohort_month
	
-- Verify query
select
	max(retained_1m_rate) as max_1m_rate,
	max(retained_3m_rate) as max_3m_rate,
	max(retained_6m_rate) as max_6m_rate,
	sum(case
			when retained_1m_rate < retained_3m_rate
			then 1
			else 0
		end)as error_1to3_rate,
	sum(case
			when retained_6m_rate > retained_3m_rate
			then 1
			else 0
		end)as error_3to6_rate
from retention_6m

-- Which cohort month do subscribers churn the most?   
select
	cohort_month,
	cohort_size,
	(100.0 - retained_1m_rate) as churn_rates_1m,
	(100.0 - retained_3m_rate) as churn_rates_3m,
	(100.0 - retained_6m_rate) as churn_rates_6m
from retention_6m
order by churn_rates_1m desc, churn_rates_3m desc, churn_rates_6m desc;

-- How does customer churn rate vary by support ticket priority?
with base as (
select
	priority,
	count(distinct t.account_id) as customer,
	count(distinct c.account_id) as churn_customers
from vw_clean_support_ticket as t
left join vw_clean_churn_event as c
	on t.account_id = c.account_id
group by priority
)
select
	priority,
	customer,
	churn_customers,
	round(100.0 * churn_customers / customer,2) as churn_rate
from base

-- Which subscriber segments show higher churn risk?
-- high churn_rate grouped by industry
-- Industry
with base as (
select
	a.industry as industry,
	count(distinct a.account_id) as total_customers,
	count(distinct c.account_id) as churn_customers
from vw_clean_account as a
left join vw_clean_churn_event as c
	on a.account_id = c.account_id
group by industry
)
select
	industry,
	total_customers,
	churn_customers,
	round(100.0 * churn_customers / total_customers,2) as churn_rate
from base

-- Plan tier
-- high churn_rate grouped by plan tier
with base as (
select
	a.plan_tier as plan_tier,
	count(distinct a.account_id) as total_customers,
	count(distinct c.account_id) as churn_customers
from vw_clean_account as a
left join vw_clean_churn_event as c
	on a.account_id = c.account_id
group by plan_tier
)
select
	plan_tier,
	total_customers,
	churn_customers,
	round(100.0 * churn_customers / total_customers,2) as churn_rate
from base
	
-- Country
with base as (
select
	a.country as country,
	count(distinct a.account_id) as total_customers,
	count(distinct c.account_id) as churn_customers
from vw_clean_account as a
left join vw_clean_churn_event as c
	on a.account_id = c.account_id
group by country
)
select
	country,
	total_customers,
	churn_customers,
	round(100.0 * churn_customers / total_customers,2) as churn_rate
from base
order by churn_rate desc;