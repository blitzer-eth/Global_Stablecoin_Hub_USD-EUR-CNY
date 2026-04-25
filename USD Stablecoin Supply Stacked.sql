-- Section 1, Visual 1: USD-anchored stablecoin supply across all 37+ chains
-- Tokens: USDT, USDC, USDS, USDe, PYUSD
-- Source: stablecoins_multichain.balances (Dune Spellbook)
-- Methodology: SUM of holder balances per (day, token), excluding bridge contract addresses
--              identified via labels.owner_addresses to mitigate cross-chain double-counting
WITH bridge_addresses AS (
    SELECT DISTINCT lower(concat('0x', to_hex(oa.address))) AS addr_str
    FROM labels.owner_addresses oa
    LEFT JOIN labels.owner_details od ON oa.owner_key = od.owner_key
    WHERE od.primary_category = 'Bridge'
       OR contains(od.category_tags, 'bridge')
       OR oa.contract_name LIKE '%Bridge%'
       OR oa.contract_name LIKE '%bridge%'
),
filtered_balances AS (
    SELECT
        b.day,
        CASE
            WHEN upper(b.token_symbol) = 'USDT' THEN 'USDT'
            WHEN upper(b.token_symbol) = 'USDC' THEN 'USDC'
            WHEN upper(b.token_symbol) = 'USDS' THEN 'USDS'
            WHEN upper(b.token_symbol) = 'USDE' THEN 'USDe'
            WHEN upper(b.token_symbol) = 'PYUSD' THEN 'PYUSD'
        END AS symbol,
        b.balance
    FROM stablecoins_multichain.balances b
    LEFT JOIN bridge_addresses ba ON lower(b.address) = ba.addr_str
    WHERE upper(b.token_symbol) IN ('USDT','USDC','USDS','USDE','PYUSD')
      AND b.currency = 'USD'
      AND b.day >= CURRENT_DATE - INTERVAL '180' day
      AND b.balance > 0
      AND ba.addr_str IS NULL  -- exclude bridge addresses
),
daily_supply AS (
    SELECT
        day,
        symbol,
        SUM(balance) AS total_supply
    FROM filtered_balances
    GROUP BY 1, 2
)
SELECT
    day,
    symbol,
    total_supply,
    total_supply / 1e9 AS total_supply_b
FROM daily_supply
ORDER BY day, symbol
