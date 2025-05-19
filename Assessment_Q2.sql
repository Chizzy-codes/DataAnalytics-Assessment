-- Final result is derived from a Common Table Expression (CTE) called 'answer'
WITH answer AS (

  -- Step 1: Compute average monthly transaction count per user
  WITH trans_per_user_per_month AS (

    -- Step 1a: Sum number of transactions per user per month
    WITH trans_month AS (

      -- Step 1a(i): Join users with their transactions and extract year, month
      WITH trans_join AS (
        SELECT
          users_customuser.id,  -- Unique user ID
          
          -- Extract month from transaction date, default to 0 if NULL
          COALESCE(MONTH(savings_savingsaccount.transaction_date), 0) AS month_number,
          
          -- Extract year from transaction date, default to 0 if NULL
          COALESCE(YEAR(savings_savingsaccount.transaction_date), 0) AS year_number,
          
          -- Assign 1 if a valid transaction date exists, else 0
          CASE 
            WHEN (COALESCE(savings_savingsaccount.transaction_date, 0) = 0) THEN 0
            ELSE 1
          END AS trans_count
          
        FROM users_customuser
        -- LEFT JOIN ensures we include users even if they have no transactions
        LEFT JOIN savings_savingsaccount
          ON savings_savingsaccount.owner_id = users_customuser.id
      )

      -- Group transactions per user by month and year, and count them
      SELECT 
        id,  -- User ID
        year_number,  -- Year of transaction
        month_number, -- Month of transaction
        SUM(trans_count) AS trans_sum  -- Total transactions that month
      FROM trans_join 
      GROUP BY id, year_number, month_number
    )

    -- Step 1b: For each user and each month, calculate average transaction count
    SELECT 
      id,  -- User ID
      month_number, -- Month number
      AVG(trans_sum) AS trans_avg_one  -- Average transaction count for the month
    FROM trans_month
    GROUP BY id, month_number
  )

  -- Step 2: Compute overall average transaction count per user and categorize them
  SELECT
    id,  -- User ID
    
    -- Final average monthly transactions for the user
    AVG(trans_avg_one) AS trans_avg_user,

    -- Classify user into frequency category based on their average transaction volume
    CASE 
      WHEN (AVG(trans_avg_one) <= 2) THEN 'Low Frequency'
      WHEN (AVG(trans_avg_one) BETWEEN 3 AND 9) THEN 'Medium Frequency'
      ELSE 'High Frequency'
    END AS frequency_category
  FROM trans_per_user_per_month
  GROUP BY id
)

-- Step 3: Summarize by frequency category
SELECT
  frequency_category,  -- User group based on frequency classification

  COUNT(id) AS customer_count,  -- Number of users in that category

  ROUND(AVG(trans_avg_user), 1) AS avg_transactions_per_month  -- Average monthly transactions for the group
FROM answer
GROUP BY frequency_category
ORDER BY AVG(trans_avg_user) DESC;  -- Sort from most active to least