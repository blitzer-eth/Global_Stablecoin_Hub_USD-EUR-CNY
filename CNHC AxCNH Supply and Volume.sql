-- Section 3, Visual 5 (REVISED): CNHC and AxCNH on-chain activity tracking
-- Original plan was supply + USD volume; data quality forced a methodology change.
-- Findings during execution:
--   1. Neither CNHC nor AxCNH are in stablecoins_multichain catalog (no curated price feed)
--   2. The most-active CNHC contract on BNB shows token balances inconsistent with a real
--      stablecoin (single-day mints of >10^15 units), suggesting it is a non-canonical or
--      defunct deployment (consistent with CNHC Group's 2023 regulatory issues in China)
--   3. Most "AXCNH" deployments on Base/BSC look like factory-deployed copycats
-- Honest output: transfer counts and unique senders only, which IS the strategic signal.
WITH cnh_tokens AS (
    SELECT * FROM (VALUES
        ('CNHC', 'bnb',  0xab4f0c4274838bfa98040c1ffa19a0941973b23e),
        ('AxCNH','bnb',  0xc0b4c5e6a720f945cd31e999ce8d781d0adc31f1),
        ('AxCNH','avalanche_c', 0x8230bd324200b8d08602f55415c162bc5e7cff7b)
    ) AS t(symbol, blockchain, contract_address)
),
weekly_activity AS (
    SELECT
        date_trunc('week', t.block_date) AS week,
        c.symbol,
        c.blockchain,
        COUNT(*) AS transfers,
        COUNT(DISTINCT t."from") AS unique_senders,
        COUNT(DISTINCT t."to")   AS unique_receivers
    FROM tokens.transfers t
    INNER JOIN cnh_tokens c
        ON t.contract_address = c.contract_address
       AND t.blockchain       = c.blockchain
    WHERE t.block_date >= CURRENT_DATE - INTERVAL '180' day
      AND t.block_time >= CURRENT_TIMESTAMP - INTERVAL '180' day
    GROUP BY 1, 2, 3
)
SELECT
    week,
    symbol || ' (' || blockchain || ')' AS series,
    transfers,
    unique_senders,
    unique_receivers
FROM weekly_activity
ORDER BY week, series
