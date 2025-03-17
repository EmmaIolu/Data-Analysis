--primul cte(e bun)
WITH payment_summary AS (
    SELECT 
        user_id, 
        game_name, 
        DATE_TRUNC('month', payment_date::DATE) AS payment_month, 
        SUM(revenue_amount_usd) AS total_revenue
    FROM games_payments
    GROUP BY user_id, game_name, payment_month
),
--al 2 lea cte
 payment_with_lags AS (
    SELECT 
        user_id, 
        game_name, 
        DATE_TRUNC('month', payment_date::DATE) AS payment_month, 
        SUM(revenue_amount_usd) AS total_revenue,
        DATE_TRUNC('month', payment_date::DATE) - INTERVAL '1' MONTH AS previous_calendar_month,
        DATE_TRUNC('month', payment_date::DATE) + INTERVAL '1' MONTH AS next_calendar_month,
        LAG(DATE_TRUNC('month', payment_date::DATE)) OVER(PARTITION BY user_id ORDER BY DATE_TRUNC('month', payment_date::DATE)) AS previous_paid_month,
        LEAD(DATE_TRUNC('month', payment_date::DATE)) OVER(PARTITION BY user_id ORDER BY DATE_TRUNC('month', payment_date::DATE)) AS next_paid_month,
        LAG(SUM(revenue_amount_usd)) OVER(PARTITION BY user_id ORDER BY DATE_TRUNC('month', payment_date::DATE)) AS previous_paid_month_revenue
    FROM games_payments
    GROUP BY user_id, game_name, DATE_TRUNC('month', payment_date::DATE)
),
-- Al treilea CTE: Calculul Churn Month, Churned Revenue, Expansion Revenue și Contraction Revenue
churn_and_expansion AS (
    SELECT 
        pwl.*, 
        CASE 
            WHEN previous_paid_month IS NULL THEN total_revenue 
            ELSE 0 
        END AS new_mrr,
        CASE 
            WHEN next_paid_month IS NULL OR next_paid_month != next_calendar_month THEN next_calendar_month
            ELSE NULL
        END AS churn_month,
        CASE 
            WHEN next_paid_month IS NULL OR next_paid_month != next_calendar_month THEN total_revenue
            ELSE NULL
        END AS churned_revenue,
        CASE 
            WHEN previous_paid_month = previous_calendar_month AND total_revenue > previous_paid_month_revenue THEN total_revenue - previous_paid_month_revenue
            ELSE NULL
        END AS expansion_revenue,
        CASE 
            WHEN previous_paid_month = previous_calendar_month AND total_revenue < previous_paid_month_revenue THEN total_revenue - previous_paid_month_revenue
            ELSE NULL
        END AS contraction_revenue
    FROM payment_with_lags pwl
)
SELECT 
    ce.user_id,
    ce.game_name,
    ce.payment_month,
    ce.total_revenue,
    ce.previous_calendar_month,
    ce.next_calendar_month,
    ce.previous_paid_month,
    ce.next_paid_month,
    ce.previous_paid_month_revenue,
    ce.new_mrr,
    ce.churn_month,
    ce.churned_revenue,
    ce.expansion_revenue,
    ce.contraction_revenue,
    gpu.language,
    gpu.has_older_device_model,
    gpu.age
FROM churn_and_expansion ce
LEFT JOIN project.games_paid_users gpu 
    ON ce.user_id = gpu.user_id;


