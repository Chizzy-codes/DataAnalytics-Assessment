# 📊 Data Analysis Summary – Savings & Investment Platform

## 📌 Table Statistics

| Table Name                  | Row Count |
|----------------------------|-----------|
| `plans_plan`               | 9,641     |
| `savings_savingsaccount`   | 163,736   |
| `users_customuser`         | 1,867     |
| `withdrawals_withdrawal`   | 1,308     |

---

## 📈 Key Metrics

- **a) Total unique users**: `1,867`  
  ```sql
  SELECT COUNT(DISTINCT(id)) FROM users_customuser;
  ```

- **b) Total plans marked as savings or investment**: `3,715`  
  ```sql
  SELECT COUNT(*) FROM plans_plan WHERE is_regular_savings = 1 OR is_a_fund = 1;
  ```

- **c) Unique users with a savings or investment plan**: `746`  
  ```sql
  SELECT COUNT(DISTINCT(owner_id)) FROM plans_plan WHERE is_regular_savings = 1 OR is_a_fund = 1;
  ```

- **d) Total rows with confirmed amount ≥ 1**: `109,291`  
  ```sql
  SELECT COUNT(*) FROM savings_savingsaccount WHERE confirmed_amount >= 1;
  ```

- **e) Unique users with confirmed amount ≥ 1**: `872`  
  ```sql
  SELECT COUNT(DISTINCT(owner_id)) FROM savings_savingsaccount WHERE confirmed_amount >= 1;
  ```

- **f) Last transaction date (or current export date)**: `2025-04-18`  
  ```sql
  SELECT DATE(MAX(transaction_date)) AS last_transaction_date FROM savings_savingsaccount;
  ```

---

## 🔁 SQL Order of Execution

```text
1. WITH / Subqueries
2. FROM / JOIN
3. WHERE
4. GROUP BY
5. HAVING
6. SELECT
7. DISTINCT
8. ORDER BY
9. LIMIT
10. OFFSET
```

---

## ❓ Question 1 – Users with Funded Savings & Investment Plans

### ✅ Problem
From 1,867 users, identify users who:
- Have a **funded savings plan** (`is_regular_savings = 1` with confirmed deposits ≥ 1 Kobo)
- Have a **funded investment plan** (`is_a_fund = 1` with confirmed deposits ≥ 1 Kobo)

### ⚙️ Approach
- Pre-aggregated deposit data with CTEs
- Filtered plans by type and funding status
- Grouped users by plan type and total deposits
- Sorted by total deposit amount (Naira)

### 🚀 Optimization
- Avoided redundant joins
- Aggregated before joining
- Reduced query execution time from >30s to <1s

### 📊 Result
**179** unique users have both a funded savings and investment plan (cross-sell opportunity).

---

## ❓ Question 2 – Transaction Frequency Segmentation

### ✅ Problem
Segment users by average **monthly transaction frequency**:
- **High Frequency**: ≥10 transactions/month
- **Medium Frequency**: 3–9 transactions/month
- **Low Frequency**: ≤2 transactions/month

### ⚙️ Approach
- Joined transactions with users
- Extracted year-month from `transaction_date`
- Aggregated monthly transactions per user
- Segmented users by activity level
- Verified total = `1867` users

### 📊 Result

| Frequency         | Customers | Avg. Monthly Txns |
|------------------|-----------|-------------------|
| High Frequency    | 185       | 35.8              |
| Medium Frequency  | 181       | 4.5               |
| Low Frequency     | 1,501     | 0.4               |

---

## ❓ Question 3 – Inactive Accounts (≥1 Year)

### ✅ Problem
Identify all plans with no inflow transactions for over 365 days.

### ⚙️ Approach
- Created `type` column: Savings or Investment
- Calculated `last_transaction_date` per plan
- Calculated `inactivity_days` using `DATEDIFF()`
- Filtered for `inactivity_days >= 365`

### 📊 Result
**1,592** unique plans have been inactive for more than one year.

---

## ❓ Question 4 – Estimated Customer Lifetime Value (CLV)

### ✅ Problem
Estimate CLV for all users using:
```text
CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction
```

### ⚙️ Approach
- Calculated `tenure` in months from `date_joined`
- Combined inflow + withdrawal transactions
- Converted amounts from Kobo to Naira
- Estimated CLV and sorted by highest to lowest

### 📊 Result
Final result is a table of `1867` users with:
- `id`
- `full name`
- `date_joined`
- `tenure (months)`
- `estimated CLV (Naira)`