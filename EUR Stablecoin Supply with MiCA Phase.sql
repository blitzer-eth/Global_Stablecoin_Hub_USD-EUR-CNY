-- Section 2, Visual 3: EUR-anchored stablecoin supply (EURC, EURS, jEUR)
-- Includes MiCA phase categorization (MiCA stablecoin titles took effect 2024-06-30,
-- full crypto-asset framework 2024-12-30; we use 2024-12-30 as the "Post-MiCA full" cutoff)
-- Source: stablecoins_multichain.balances
WITH bridge_addresses AS (
    SELECT DISTINCT lower(concat('0x', to_hex(oa.address))) AS addr_str
    FROM labels.owner_addresses oa
    LEFT JOIN labels.owner_details od ON oa.owner_key = od.owner_key
    WHERE od.primary_category = 'Bridge'
       OR contains(od.category_tags, 'bridge')
       OR oa.contract_name LIKE '%Bridge%'
),
filtered_balances AS (
    SELECT
        b.day,
        CASE
            WHEN upper(b.token_symbol) = 'EURC' THEN 'EURC'
            WHEN upper(b.token_symbol) = 'EURS' THEN 'EURS'
            WHEN upper(b.token_symbol) = 'JEUR' THEN 'jEUR'
        END AS symbol,
        b.balance,
        b.balance_usd
    FROM stablecoins_multichain.balances b
    LEFT JOIN bridge_addresses ba ON lower(b.address) = ba.addr_str
    WHERE upper(b.token_symbol) IN ('EURC','EURS','JEUR')
      AND b.currency = 'EUR'
      AND b.day >= CURRENT_DATE - INTERVAL '180' day
      AND b.balance > 0
      AND ba.addr_str IS NULL
),
daily_supply AS (
    SELECT
        day,
        symbol,
        SUM(balance) AS total_supply_eur,
        SUM(balance_usd) AS total_supply_usd
    FROM filtered_balances
    GROUP BY 1, 2
)
SELECT
    day,
    symbol,
    total_supply_eur,
    total_supply_eur / 1e6 AS supply_m_eur,
    CASE
        WHEN day < DATE '2024-06-30' THEN '1. Pre-MiCA'
        WHEN day < DATE '2024-12-30' THEN '2. MiCA Stablecoin Titles in Force'
        ELSE '3. Post-MiCA Full Framework'
    END AS mica_phase
FROM daily_supply
ORDER BY day, symbol
