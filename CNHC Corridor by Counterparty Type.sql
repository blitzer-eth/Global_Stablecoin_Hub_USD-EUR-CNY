-- Section 3, Visual 6 (REVISED): CNH stablecoin transfer corridor by counterparty type
-- Methodology change: count of transfers (not volume) due to unreliable amount data.
-- Classification: CEX / Bridge / Other Contract / EOA via labels.cex_tokens + labels.owner_addresses
-- Note: "OTC desk" is not a structured label class on Dune. EOA flows can include OTC
--       counterparties but cannot be reliably distinguished without proprietary attribution.
WITH cnh_transfers AS (
    SELECT
        t.block_date,
        t."to" AS dest_address,
        CASE
            WHEN t.contract_address = 0xab4f0c4274838bfa98040c1ffa19a0941973b23e THEN 'CNHC (BNB)'
            WHEN t.contract_address = 0xc0b4c5e6a720f945cd31e999ce8d781d0adc31f1 THEN 'AxCNH (BNB)'
            WHEN t.contract_address = 0x8230bd324200b8d08602f55415c162bc5e7cff7b THEN 'AxCNH (Avax)'
        END AS series,
        t.blockchain
    FROM tokens.transfers t
    WHERE (
        (t.contract_address = 0xab4f0c4274838bfa98040c1ffa19a0941973b23e AND t.blockchain = 'bnb')
        OR (t.contract_address = 0xc0b4c5e6a720f945cd31e999ce8d781d0adc31f1 AND t.blockchain = 'bnb')
        OR (t.contract_address = 0x8230bd324200b8d08602f55415c162bc5e7cff7b AND t.blockchain = 'avalanche_c')
    )
      AND t.block_date >= CURRENT_DATE - INTERVAL '180' day
      AND t.block_time >= CURRENT_TIMESTAMP - INTERVAL '180' day
      AND t."from" != 0x0000000000000000000000000000000000000000  -- exclude mints
      AND t."to"   != 0x0000000000000000000000000000000000000000  -- exclude burns
),
cex_lookup AS (
    SELECT DISTINCT address, blockchain
    FROM labels.cex_tokens
    WHERE blockchain IN ('bnb','avalanche_c')
),
owner_lookup AS (
    SELECT
        oa.address,
        oa.blockchain,
        od.primary_category,
        oa.contract_name
    FROM labels.owner_addresses oa
    LEFT JOIN labels.owner_details od ON oa.owner_key = od.owner_key
    WHERE oa.blockchain IN ('bnb','avalanche_c')
),
classified AS (
    SELECT
        ct.series,
        CASE
            WHEN cl.address IS NOT NULL THEN 'CEX'
            WHEN ol.primary_category = 'Bridge' THEN 'Bridge'
            WHEN ol.primary_category = 'CEX' THEN 'CEX'
            WHEN ol.contract_name IS NOT NULL AND ol.contract_name <> '' THEN 'Other Contract'
            ELSE 'EOA / Unlabeled'
        END AS counterparty_type
    FROM cnh_transfers ct
    LEFT JOIN cex_lookup cl
        ON ct.dest_address = cl.address AND ct.blockchain = cl.blockchain
    LEFT JOIN owner_lookup ol
        ON ct.dest_address = ol.address AND ct.blockchain = ol.blockchain
)
SELECT
    series,
    counterparty_type,
    COUNT(*) AS transfer_count
FROM classified
GROUP BY 1, 2
ORDER BY series, transfer_count DESC
