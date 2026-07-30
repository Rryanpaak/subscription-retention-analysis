# SaaS Subscription Retention & Churn Analysis

## Project Overview

This project analyzes subscriber retention and churn patterns for a SaaS business using PostgreSQL and Power BI.

The analysis covers 500 unique subscriber accounts from January 2023 to December 2024. It examines monthly subscriber growth, active and churned subscriber trends, M0-M6 cohort retention, and churn concentration across industries, countries, plan tiers, and support-ticket priorities.

The goal is to understand how effectively subscribers are retained after their first subscription and identify where churn risk is concentrated.

## Business Question

> How does subscriber retention change over time, and where is churn concentrated across subscriber cohorts and segments?

### Sub Questions

- How many new subscribers were acquired each month?
- What percentage of subscribers remained after 1, 3, and 6 months?
- Which monthly cohorts had the strongest retention rates?
- At which stage of the subscription lifecycle was cohort churn highest?
- How did churn vary by support-ticket priority?
- Which industries, countries, and plan tiers showed higher churn rates?

## Dataset

The project uses the **Ravenstack Churn & Retention Analysis** dataset from Kaggle.

| Source table | Grain | Key fields | Purpose |
|---|---|---|---|
| `account` | One row per subscriber account | `account_id` | Subscriber attributes, including industry, country, and plan tier |
| `subscriptions` | One row per subscription record | `subscription_id`, `account_id` | Subscription start dates, plan details, and cohort assignment |
| `churn_event` | One row per recorded churn event | `account_id`, churn-event identifier | Churn dates, reasons, reactivation status, and feedback |
| `support_ticket` | One row per support ticket | `ticket_id`, `account_id` | Support priority, response, resolution, and satisfaction details |
| `feature_usage` | One row per feature-usage event | `usage_id`, `subscription_id` | Available in the source dataset but not used in the current dashboard |

| Dataset detail | Value |
|---|---|
| Analysis period | January 2023-December 2024 |
| Unique subscriber accounts | 500 |
| Primary account key | `account_id` |
| Feature-usage join key | `subscription_id` |

## Tools

- **PostgreSQL:** data preparation, view creation, and analysis
- **Power BI:** data modeling and dashboard development

## Data Preparation

The preparation process included:

1. Establishing source-table row counts as validation baselines.
2. Reviewing column names, data types, and nullability.
3. Checking primary identifiers for duplicate records.
4. Checking important account, subscription, churn, and support fields for missing values.
5. Validating subscription and support-ticket date sequences.
6. Testing relationships between accounts, subscriptions, churn events, support tickets, and feature usage.
7. Creating clean analytical views with standardized fields and month-level dates.
8. Reducing subscription activity to one lifecycle record per account to prevent duplicate subscriber counts.

No records were found where a subscription ended before it started or where a support ticket was submitted after it was closed.

Many subscription end dates were missing. Therefore, the retention analysis uses each account's earliest recorded churn month when available. Accounts without a recorded churn event are treated as retained through the observed period.

## Metric Definitions

| Metric | Definition |
|---|---|
| Total Subscribers | Distinct count of subscriber accounts |
| New Subscribers | Distinct accounts grouped by their earliest subscription-start month |
| Active Subscribers | Accounts that had started a subscription and had not reached their first recorded churn month by the reporting month |
| Churned Subscribers | Accounts whose first recorded churn month was on or before the reporting month |
| Overall Churn Rate | Distinct churned accounts divided by total distinct subscriber accounts |
| Cohort Month | An account's earliest subscription-start month |
| Cohort Size | Distinct subscriber accounts assigned to the same cohort month |
| Cohort Index | Number of months since the cohort month, from M0 through M6 |
| Retained Subscribers | At M0, all cohort accounts; after M0, accounts with no recorded churn month or a churn month later than the cohort checkpoint |
| Retention Rate | Retained subscribers divided by cohort size, expressed as a percentage |
| 1-, 3-, and 6-Month Retention | Cohort retention measured at M1, M3, and M6 for cohorts with an observable checkpoint |

## SQL Analysis

### 1. Account-Level Subscription Lifecycle

Each account's earliest subscription month was combined with its earliest recorded churn month. This account-level structure prevents multiple subscription or churn records from inflating subscriber counts.

### 2. Monthly Subscriber Trends

A continuous monthly calendar was generated from the earliest subscription month through December 2024. For each month, accounts were classified as:

- **Active:** subscribed by the reporting month and not yet churned
- **Churned:** first churn month on or before the reporting month
- **Total:** subscribed by the reporting month

### 3. Cohort Retention

Subscribers were grouped by their earliest subscription month. Retention was calculated from M0 through M6 using monthly checkpoints.

- M0 represents the original cohort size.
- M1-M6 represent the number and percentage of accounts retained at each later checkpoint.
- A subscriber is retained when no churn event is recorded or the churn month occurs after the checkpoint.
- Checkpoints after December 2024 are treated as unavailable rather than as zero retention.

Separate 1-, 3-, and 6-month retention calculations include only cohorts with enough observation time to reach the corresponding checkpoint.

### 4. Churn by Subscriber Segment

Segment-level churn rates were calculated using distinct account counts:

```text
Churn Rate = Distinct Churned Accounts / Distinct Subscriber Accounts
```

The analysis compares churn across:

- Industry
- Country
- Plan tier
- Support-ticket priority

## Dashboard Pages

### Page 1 - Subscription Overview

Summarizes subscriber acquisition and lifecycle status through:

- Total, active, and churned subscriber KPIs
- Overall churn rate
- Monthly new-subscriber trend
- Active and churned subscriber trend
- Monthly cohort size

### Page 2 - Cohort Retention

Shows how subscriber retention changes during the first six months through:

- 1-, 3-, and 6-month retention KPIs
- M0-M6 cohort-retention heatmap
- Retention curve by cohort
- Cohort-size comparison

### Page 3 - Customer Segments

Identifies where churn is concentrated through:

- Churn rate by industry
- Churn rate by country
- Churn rate by plan tier
- Churn rate by support-ticket priority
- Reported churn reasons and customer feedback

## Key Findings

- By December 2024, **352 of 500 subscriber accounts had churned**, while 148 remained active. This represents an overall churn rate of **70.4%**.
- The **April 2024 cohort** recorded **59.09% churn by M1**, increasing to **72.73% by M3** and **86.36% by M6**.
- The highest churn rates within the analyzed segment categories were found among **UK accounts (77.59%)**, **DevTools accounts (73.45%)**, and **Pro-plan accounts (72.47%)**.
- Accounts associated with **high-priority support tickets** had the highest support-priority churn rate at **72.67%**. However, churn rates were relatively close across all support-priority groups.

## Recommendations

| Evidence | Suggested action |
|---|---|
| The April 2024 cohort lost 59.09% of subscribers by M1. | Review its acquisition sources, onboarding completion, and early product engagement to identify where first-month loss occurred. |
| UK, DevTools, and Pro-plan accounts had the highest churn rates in their respective comparisons. | Prioritize these groups for customer interviews and targeted retention tests while checking whether segment size or other account characteristics explain the differences. |
| Accounts with high-priority support tickets had a 72.67% churn rate. | Review issue types, response times, and resolutions before testing proactive escalation and post-resolution follow-up processes. |

## Limitations

- The analysis is limited to the January 2023-December 2024 observation window.
- Recent cohorts do not have complete M6 observations and are not treated as having zero retention in future months.
- Because many subscription end dates are missing, lifecycle status relies on the earliest recorded churn event.
- Segment and support-ticket results show associations with churn; they do not prove that a segment characteristic or support interaction caused churn.
