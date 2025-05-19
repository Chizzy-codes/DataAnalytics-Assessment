-- Step 1: Aggregate plan data per user and per plan
WITH filtered_plans AS (
	SELECT 
	  owner_id,                      -- User ID who owns the plan
	  id,                            -- Unique plan ID
	  is_regular_savings AS savings_count,     -- Sum of is_regular_savings flags (typically 0 or 1) per user for each plan
	  is_a_fund AS investment_count            -- Sum of is_a_fund flags (typically 0 or 1) per user for each plan
	FROM plans_plan 
	WHERE is_regular_savings = 1 OR is_a_fund = 1   -- Only include plans that are either savings or investment types
),

-- Step 2: Aggregate savings data per user and plan
filtered_savings AS (
	SELECT 
	  owner_id,                      -- User ID who owns the savings account
	  plan_id,                       -- The associated plan ID
	  SUM(confirmed_amount) AS total_deposits       -- Total confirmed deposits for each user-plan pair
	FROM savings_savingsaccount 
	WHERE confirmed_amount >= 1                     -- Only include non-zero confirmed deposits
	GROUP BY owner_id, plan_id                      -- Group by user and plan id to align with plan-level aggregation
)

-- Step 3: Join users with their aggregated plan and savings data to get users with at least one funded savings plan AND one funded investment plan, sorted by total deposits
SELECT 
  u.id AS owner_id,               -- Final user ID
  COALESCE(CONCAT(
    UPPER(LEFT(first_name, 1)),               -- Capitalize first letter of first name
    LOWER(SUBSTRING(first_name, 2)),          -- Lowercase the rest of the first name
    ' ',
    UPPER(LEFT(last_name, 1)),                -- Capitalize first letter of last name
    LOWER(SUBSTRING(last_name, 2))            -- Lowercase the rest of the last name
  ), 'None') AS name,                      -- Properly formatted full name
  SUM(p.savings_count) AS savings_count,         -- Total number of funded savings-type plans per user
  SUM(p.investment_count) AS investment_count,   -- Total number of funded investment-type plans per user
  ROUND(((SUM(s.total_deposits))/100), 2) AS total_deposits  -- Total deposits in naira across all plans, rounded to 2 decimals
FROM filtered_plans p
JOIN filtered_savings s 
  ON p.owner_id = s.owner_id AND p.id = s.plan_id     -- Join plans to matching savings by user and plan ID
JOIN users_customuser u 
  ON p.owner_id = u.id                                -- Join with user info
GROUP BY u.id                                          -- Aggregate data per user
HAVING savings_count >= 1 AND investment_count >= 1    -- Only include users with both plan types
ORDER BY total_deposits;                               -- Sort users by total deposits in ascending order