/*
Project: Subscriber Cohort & Retention Analysis
File: 03_data_visualization.sql
purpose: Create views for data visualization
*/

-- page 1. Subscription Overview

with first_subscription as (
	select
		account_id,
		min(start_month) as first_subscription_month
	from vw_clean_subscription
	group by account_id
),
churned_subscription as (
	select
		account_id,
		min(churn_month) as first_churn_month
	from vw_clean_churn_event
	group by account_id
),
cycles as (
select
	s.account_id,
	s.first_subscription_month,
	c.first_churn_month
from first_subscription as s
left join churned_subscription as c
	on s.account_id = c.account_id
),
months as (
	select
		generate_series(
			min(first_subscription_month),
			greatest(
				max(first_subscription_month),
				coalesce (
					max(first_churn_month),
					max(first_subscription_month)
					)
					),
			interval '1 month')::date as months
	from cycles
)
select
	m.months,
	count(*) filter(where c.first_subscription_month <= m.months
	and (c.first_churn_month is null or c.first_churn_month > m.months)
	) as active_subscriber,
	count(*) filter (where c.first_subscription_month <= m.months
	and c.first_churn_month <= m.months
	) as churned_subscriber,
	count(*) filter (where c.first_subscription_month <= m.months
	) as total_subscriber
from months as m
cross join cycles as c
group by m.months
order by m.months;



-- page 2. Cohort Retention
with cohort_index_ as (
	select
		generate_series(0,6) as cohort_index
),
month_index_size as(
select
	r.cohort_month,
	i.cohort_index,
	r.cohort_size
from retention_6m as r
cross join cohort_index_ as i
order by cohort_month, cohort_index
),
retention_base as(
select
	a.account_id,
	a.first_subscription_month as cohort_month,
	a.churn_month,
	i.cohort_index,
	(a.first_subscription_month + i.cohort_index * interval '1month')::date as check_month
from active_churn as a
cross join cohort_index_ as i
),
retention_flag as(
select
	*,
	case
		when check_month > date '2024-12-01' then null
		when cohort_index = 0 then 1
		when churn_month is null or churn_month > check_month then 1
		else 0
	end as retention_flag
from retention_base
),
retention_summary as (
	select
		cohort_month,
		cohort_index,
		count(distinct account_id) as cohort_size,
		sum(retention_flag) as retained_subscribers
	from retention_flag
	group by cohort_month,cohort_index
),
select
	cohort_month,
	cohort_index,
	cohort_size,
	retained_subscribers,
	round(100.0 * retained_subscribers / nullif(cohort_size,0),2) as retention_rate
from retention_summary
order by cohort_month, cohort_index
