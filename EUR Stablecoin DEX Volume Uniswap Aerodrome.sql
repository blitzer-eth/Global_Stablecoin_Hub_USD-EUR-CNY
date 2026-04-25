-- Section 2, Visual 4: EUR/USD stablecoin pair liquidity proxy
-- Methodology note: True "liquidity depth" requires LP reserve data. We proxy with daily
-- traded volume on EUR pairs at Uniswap (v3+v4) and Aerodrome — high volume ⇒ deep usable
-- liquidity (otherwise slippage forces traders elsewhere).
-- Filtered to USD/EUR cross pairs (one EUR-anchored stablecoin, one USD-anchored stablecoin).
WITH eur_usd_pairs AS (
    SELECT
        block_date,
        project,
        blockchain,
        token_bought_symbol,
        token_sold_symbol,
        amount_usd
    FROM dex.trades
    WHERE block_month >= date_trunc('month', CURRENT_DATE - INTERVAL '180' day)
      AND block_date  >= CURRENT_DATE - INTERVAL '180' day
      AND project IN ('uniswap','aerodrome','aerodrome_slipstream')
      AND blockchain IN ('ethereum','base','arbitrum','optimism','polygon')
      AND (
            (upper(token_bought_symbol) IN ('EURC','EURS','JEUR','EURE','EURI')
             AND upper(token_sold_symbol)   IN ('USDC','USDT','USDS','PYUSD','DAI'))
         OR (upper(token_sold_symbol)   IN ('EURC','EURS','JEUR','EURE','EURI')
             AND upper(token_bought_symbol) IN ('USDC','USDT','USDS','PYUSD','DAI'))
      )
      AND amount_usd IS NOT NULL
      AND amount_usd > 0
      AND amount_usd < 1e9  -- filter out obvious data anomalies
),
labeled AS (
    SELECT
        block_date,
        CASE
            WHEN project = 'uniswap'   THEN 'Uniswap'
            WHEN project IN ('aerodrome','aerodrome_slipstream') THEN 'Aerodrome'
        END AS dex,
        CASE
            WHEN upper(token_bought_symbol) IN ('EURC','EURS','JEUR','EURE','EURI')
                THEN upper(token_bought_symbol)
            ELSE upper(token_sold_symbol)
        END AS eur_token,
        amount_usd
    FROM eur_usd_pairs
)
SELECT
    block_date AS day,
    dex,
    eur_token,
    SUM(amount_usd) AS daily_volume_usd
FROM labeled
GROUP BY 1, 2, 3
ORDER BY day, dex, eur_token
