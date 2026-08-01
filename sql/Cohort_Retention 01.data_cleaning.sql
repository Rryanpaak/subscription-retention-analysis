/*
Project: Subscriber Cohort & Retention Analysis
File: 01_data_cleaning.sql
purpose: Create cleaned views for cohort and retention analysis
*/

-- 1. Source row-count validation
-- 2. Identifier and duplicate checks
-- 3. Null-value assessment
-- 4. Date-sequence validation
-- 5. Numeric and categorical validation
-- 6. Relationship/orphan checks
-- 7. Clean-view creation

-- 1. Source row-count validation
select 'accounts' as table_name, 
	count(*) as row_cnt
from account
union all
select 'churn',
	count(*)
from churn_event
union all
select 'feature',
	count(*)
from feature_usage
union all
select 'subscriptions',
	count(*)
from subscriptions
union all
select 'support',
	count(*)
from support_ticket

-- 2. Identifier and duplicate checks

-- subscription duplicate check
select
	subscription_id,
	account_id, 
	count(*) as duplicates
from subscriptions
group by subscription_id, account_id
having count(*) > 1

-- acount_id table null check
select
	count(*) as total_rows,
	count(*) filter(where account_id is null) as null_account_id,
	count(*) filter(where account_name is null) as null_account_name,
	count(*) filter(where signup_date is null) as null_signup_date,
	count(*) filter(where churn_flag is null) as null_chun_flag
from account;

-- relationship check between churn_event and account table
select
	count(*) as total_rows,
	count(*) filter (where a.account_id is null) as unmatched_account
from churn_event as c
left join account as a on
	c.account_id = a.account_id;

-- Clean-view creation
-- make the clean view for churn_event table 
create or replace view vw_clean_churn_event as
select
	account_id,
	churn_event,
	churn_date,
	date_trunc('month', churn_date)::date as churn_month,
	reason_code as reason,
	refund_amount_usd as refund_usd,
	preceding_upgrade_flag as preceding_upgrade,
	preceding_downgrade_flag as preceding_downgrade,
	is_reactivation as reactivation,
	feedback
from churn_event;

	