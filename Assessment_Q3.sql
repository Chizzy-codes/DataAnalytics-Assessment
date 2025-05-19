-- Step 1: Create a temporary table (CTE) to classify plans as either 'Savings' or 'Investments'
WITH plan_fixed AS (
  SELECT 
    owner_id,    -- ID of the user who owns the plan
    id,          -- Unique ID of the plan
    
    -- Determine plan type:
    -- First Format is_a_fund column using case when 1 then 2 else 0
    -- If the sum of is_regular_savings and is_a_fund is 2 → label as 'Investments'
    -- Otherwise, label as 'Savings'
    CASE 
      WHEN (CASE 
              WHEN is_a_fund = 1 THEN 2  -- Investment gets weight 2
              ELSE 0                    -- Non-investment gets weight 0
            END + is_regular_savings) = 2 THEN 'Investments'
      ELSE 'Savings' 
    END AS type

  FROM plans_plan 
  -- Only include plans marked as either regular savings or investment
  WHERE is_regular_savings = 1 OR is_a_fund = 1
),

-- Step 2: Create another CTE to calculate the most recent transaction date and inactivity duration for each user-plan pair
savings_fixed AS (
  SELECT
    owner_id,      -- User ID from the savings table
    plan_id,       -- Associated plan ID
    
    -- The most recent (latest) transaction date for that user-plan pair
    DATE(MAX(transaction_date)) AS last_transaction_date,
    
    -- Calculate days of inactivity:
    -- Difference between latest transaction in the whole table and last transaction for the user-plan
    DATEDIFF(
      (SELECT DATE(MAX(transaction_date)) FROM savings_savingsaccount), -- Latest transaction date overall
      DATE(MAX(transaction_date))                                      -- Last transaction for this plan
    ) AS inactivity_days

  FROM savings_savingsaccount
  GROUP BY owner_id, plan_id  -- One row per user-plan combination
)

-- Step 3: Join both datasets and return only plans with inactivity >= 366 days (i.e., inactive for over a year)
SELECT 
  p.id AS plan_id,                      -- Unique plan ID
  p.owner_id AS owner_id,              -- User ID
  p.type,                              -- 'Savings' or 'Investments'
  s.last_transaction_date,             -- Date of last transaction
  s.inactivity_days                    -- Number of days since last transaction
FROM plan_fixed p
JOIN savings_fixed s 
  ON p.owner_id = s.owner_id AND p.id = s.plan_id  -- Match plans with their transaction info
WHERE s.inactivity_days >= 366;                     -- Filter: only show plans inactive for a year or more