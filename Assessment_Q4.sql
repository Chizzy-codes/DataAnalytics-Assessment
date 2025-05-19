/* ============================================================
   Purpose: Estimate Customer Lifetime Value (CLV) for each user
            by combining savings and withdrawal activity.
   Steps:
     1. Clean/format user data and compute tenure.
     2. Aggregate savings transactions per user‑plan.
     3. Aggregate withdrawal transactions per user‑plan.
     4. Join the three data sets and calculate:
          • total number of transactions per user
          • an estimated CLV based on average profit/txn ×
            monthly frequency × 12 months.
   ============================================================ */

-- ------------------------------------------------------------
-- Step 1: Prepare a cleaned user table with name & tenure
-- ------------------------------------------------------------
WITH user_fixed AS (
  SELECT
    id,  -- Primary‑key user ID

    /* Construct “Title Case” full name; fallback to 'None' if both
       first_name and last_name are NULL                          */
    COALESCE(
      CONCAT(
        UPPER(LEFT(first_name, 1)),      -- First initial uppercase
        LOWER(SUBSTRING(first_name, 2)), -- rest of first name
        ' ',
        UPPER(LEFT(last_name, 1)),       -- Last initial uppercase
        LOWER(SUBSTRING(last_name, 2))   -- rest of last name
      ),
      'None'
    ) AS name,

    DATE(date_joined) AS date_joined,    -- Strip time component

    /* Tenure (full months) from join date to a fixed “as‑of” date */
    TIMESTAMPDIFF(
      MONTH,
      date_joined,
      '2025‑04‑18'
    ) AS tenure_months
  FROM users_customuser
),

-- ------------------------------------------------------------
-- Step 2: Aggregate savings transactions by user + plan
-- ------------------------------------------------------------
savings_fixed AS (
  SELECT
    owner_id,                               -- User ID
    COUNT(transaction_date) AS total_deposits,   -- # of deposits

    /* Example profit proxy:
       0.1 % (0.001) of amount, then divide by 100 to convert
       to base currency units (adjust as needed).                 */
    AVG(0.001 * confirmed_amount) / 100  AS avg_profit_per_transaction_sav
  FROM savings_savingsaccount
  GROUP BY owner_id, plan_id               -- One row per user‑plan
),

-- ------------------------------------------------------------
-- Step 3: Aggregate withdrawal transactions by user + plan
-- ------------------------------------------------------------
with_fixed AS (
  SELECT
    owner_id,                               -- User ID
    COUNT(transaction_date) AS total_with,  -- # of withdrawals

    /* Profit proxy for withdrawals (same 0.1 % logic).           */
    ((AVG(0.001 * amount_withdrawn)) / 100) AS avg_profit_per_transaction_with
  FROM withdrawals_withdrawal
  GROUP BY owner_id, plan_id               -- One row per user‑plan
)

-- ------------------------------------------------------------
-- Step 4: Combine everything and compute CLV
-- ------------------------------------------------------------
SELECT
  u.id,
  u.name,
  u.date_joined,
  u.tenure_months,

  /* Total # transactions = deposits + withdrawals                */
  SUM(
    COALESCE(s.total_deposits, 0) +
    COALESCE(w.total_with,     0)
  ) AS total_transactions,

  /* ------------------------------------------------------------
     Estimated CLV formula:
       (total_transactions)            → freq so far
       × 12                            → annualize
       × average(profit per txn)       → blended margin
     ------------------------------------------------------------ */
  ROUND((
    SUM(
      COALESCE(s.total_deposits, 0) +
      COALESCE(w.total_with,     0)
    )
    * 12
    * ROUND(
        AVG(
          ( COALESCE(s.avg_profit_per_transaction_sav,  0)
          + COALESCE(w.avg_profit_per_transaction_with, 0)
          ) / 2                       -- Blend savings & withdrawals
        ),
        2                             
      )
  ), 2) AS estimated_clv             -- keep 2‑decimal precision

FROM user_fixed u
LEFT JOIN savings_fixed s ON u.id = s.owner_id   -- may be NULL
LEFT JOIN with_fixed w ON u.id = w.owner_id   -- may be NULL
GROUP BY u.id, u.name, u.date_joined, u.tenure_months  -- non‑aggregated cols
ORDER BY estimated_clv DESC