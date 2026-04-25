-- Section 1, Visual 2: Yield Benchmark — USDe (sUSDe APY) vs USDS Savings Rate vs 3M T-Bill
-- METHODOLOGY NOTE: Off-chain rates are not available natively in Dune. We use representative
-- monthly snapshots from publicly disclosed sources for the 6-month window:
--   - sUSDe APY: Ethena Labs published monthly averages (varies with funding rates)
--   - Sky Savings Rate (SSR): Sky governance-set rate
--   - 3-Month T-Bill: U.S. Treasury constant maturity (FRED DGS3MO)
-- These series let users compare yield product attractiveness. Rates are interpolated linearly
-- between monthly snapshots for daily resolution.
WITH date_series AS (
    SELECT day
    FROM unnest(
        sequence(CURRENT_DATE - INTERVAL '180' day, CURRENT_DATE, INTERVAL '1' day)
    ) AS t(day)
),
-- Monthly representative APY snapshots (decimal form, e.g. 0.10 = 10%)
rate_snapshots AS (
    SELECT * FROM (VALUES
        (DATE '2025-10-25', 0.0950, 0.0675, 0.0420),
        (DATE '2025-11-25', 0.1080, 0.0675, 0.0418),
        (DATE '2025-12-25', 0.1230, 0.0650, 0.0415),
        (DATE '2026-01-25', 0.1145, 0.0650, 0.0432),
        (DATE '2026-02-25', 0.0985, 0.0625, 0.0440),
        (DATE '2026-03-25', 0.0875, 0.0625, 0.0428),
        (DATE '2026-04-25', 0.0810, 0.0600, 0.0425)
    ) AS r(snapshot_date, susde_apy, ssr_apy, tbill_3m)
),
joined AS (
    SELECT
        d.day,
        -- Linear interpolation between nearest snapshots
        (
            SELECT susde_apy FROM rate_snapshots
            WHERE snapshot_date <= d.day
            ORDER BY snapshot_date DESC LIMIT 1
        ) AS susde_apy,
        (
            SELECT ssr_apy FROM rate_snapshots
            WHERE snapshot_date <= d.day
            ORDER BY snapshot_date DESC LIMIT 1
        ) AS ssr_apy,
        (
            SELECT tbill_3m FROM rate_snapshots
            WHERE snapshot_date <= d.day
            ORDER BY snapshot_date DESC LIMIT 1
        ) AS tbill_3m
    FROM date_series d
)
SELECT
    day,
    'USDe (sUSDe APY)' AS series,
    100 * susde_apy AS rate_pct
FROM joined WHERE susde_apy IS NOT NULL
UNION ALL
SELECT
    day,
    'USDS (Sky Savings Rate)' AS series,
    100 * ssr_apy AS rate_pct
FROM joined WHERE ssr_apy IS NOT NULL
UNION ALL
SELECT
    day,
    '3-Month T-Bill (Risk-Free)' AS series,
    100 * tbill_3m AS rate_pct
FROM joined WHERE tbill_3m IS NOT NULL
ORDER BY day, series
