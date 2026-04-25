# 🌍 Global Stablecoin Hub: USD / EUR / CNY

**[View Dashboard on Dune](https://dune.com/blitzer/global-stablecoin-hub-usd-eur-cny)**

This dashboard provides a cross-currency view of the on-chain stablecoin market, organized by anchor currency: **USD (~97% market share), EUR (MiCA expansion), and CNY (offshore RMB frontier)**. It tracks supply, yield, liquidity depth, and counterparty corridors across 38 chains spanning EVM, Solana, and Tron.

The suite is designed for analysts and researchers to compare how fiat-pegged stablecoins are scaling under different regulatory regimes — from the dominant US dollar tier, to the post-MiCA European market, to the still-nascent offshore RMB experiment.

---

## :camera_flash: Snapshot

<img width="3734" height="5413" alt="image" src="https://github.com/user-attachments/assets/7c61f29e-90a1-4da1-a561-e0702143e71d" />

---

## 🔍 Query Breakdown

### 1. USD Stablecoin Total Supply
A stacked area view of the dominant dollar tier across **all 38 chains** in the multichain spell.

* **Five-Token Aggregation:** Combines USDT, USDC, USDS, USDe, and PYUSD into a single supply panel, exposing the relative scale of payments rails (USDT/USDC), yield-bearing dollars (USDe), and the post-DAI rebrand (USDS).
* **Bridge Deduplication:** Joins `labels.owner_addresses` with `labels.owner_details` to identify and exclude bridge contract addresses, mitigating cross-chain double-counting that would otherwise inflate supply figures by the size of locked-and-minted wrappers.
* **Partition-Pruned Window:** Filters on `day` for the most recent 180 days to keep refresh costs predictable on this large multichain spell.

### 2. Yield Benchmark: sUSDe vs sUSDS Savings Rate vs 3M T-Bill
A line-chart comparison of the three primary dollar-yield instruments competing for stablecoin float.

* **Three-Way Race:** Plots the variable Ethena sUSDe APY, the governance-set Sky Savings Rate (SSR via sUSDS), and the 3-month US Treasury Bill as a risk-free reference.
* **On-Chain vs Off-Chain Bridging:** T-Bill data is not on-chain; a 26-week hardcoded series of public Treasury data is layered against the on-chain rates to make the spread visible at a glance. For a production feed, the hardcoded series should be replaced with a manual-upload macro table.
* **Spread Reading:** When sUSDe pulls above sUSDS, it signals positive funding rates on perps; when sUSDS sits above T-Bills, it indicates Sky is bidding to retain dollar deposits.

### 3. EUR Stablecoin Supply with MiCA Phase Tag
Tracks the post-MiCA European stablecoin landscape across EURC, EURS, and jEUR.

* **Three-Phase Categorization:** Adds a `mica_phase` column tagging each day as Pre-MiCA / MiCA Stablecoin Titles in Force / Post-MiCA Full Framework, anchored on the 2024-06-30 and 2024-12-30 effective dates. The column is preserved as metadata for future window expansions.
* **Concentration Visibility:** Stacking the three EUR-anchored tokens reveals that EURC dominates at ~€267M, while EURS holds ~€125M and jEUR has effectively rounded to zero — the MiCA-compliant issuer (Circle) has captured the regulated rail.
* **Bridge-Filtered Supply:** Applies the same `labels.owner_addresses` exclusion as the USD query for an apples-to-apples comparison of native-issued supply.

### 4. EUR/USD Pair Daily Volume on Uniswap and Aerodrome
Uses daily traded volume as a liquidity-depth proxy for the EUR stablecoin DEX market.

* **Volume-as-Depth Proxy:** True LP reserve depth would require per-pool TVL queries against `uniswap_v3_*.Pool_evt_Mint/Burn` and Aerodrome equivalents. Daily volume is a defensible proxy because thin pools force traders elsewhere — sustained volume implies usable depth.
* **Cross-DEX Comparison:** Filters `dex.trades` for EUR/USD cross pairs (EURC/EURS/jEUR/EURE/EURI vs USDC/USDT/USDS/PYUSD/DAI) on Uniswap (multi-chain) and Aerodrome (Base only), normalizing the venue-level competition.
* **Anomaly Filter:** Excludes trades with `amount_usd > 1e9` to remove price-feed glitches that would otherwise skew the daily aggregates.

### 5. CNHC and AxCNH Weekly On-Chain Activity
Tracks the offshore RMB stablecoin frontier — and documents why it remains a frontier.

* **Catalog Gap Workaround:** Neither CNHC nor AxCNH is in the `stablecoins_multichain` catalog, and no Dune price feed exists for them. Falls back to `tokens.transfers` filtered by hardcoded contract addresses identified via a probe query.
* **Honest Metrics Choice:** The originally planned supply and USD-volume metrics returned nonsensical values (10^15-scale numbers from a likely non-canonical CNHC contract on BNB), so the visualization was restructured around `transfers`, `unique_senders`, and `unique_receivers` — counts cannot lie about activity level.
* **Strategic Read:** Weekly counts in the single-to-low-double digits, with one 129-transfer deployment burst, confirm both projects are effectively dormant on-chain.

### 6. CNH Stablecoin Corridor Analysis: Counterparty Distribution
Classifies CNHC and AxCNH transfer destinations into CEX / Bridge / Other Contract / EOA buckets.

* **Label-Driven Classification:** Joins `labels.cex_tokens` and `labels.owner_addresses` (with `owner_details.primary_category`) against transfer destination addresses, producing a structured corridor breakdown without relying on hand-curated lists.
* **OTC-Desk Caveat:** Dune does not maintain a structured `OTC` label class. EOA flows could include OTC counterparties but cannot be reliably distinguished without proprietary attribution; the four-bucket classification is the most rigorous available from public labels.
* **Headline Finding:** Across both tokens and both BNB plus Avalanche deployments, **zero CEX hits and zero bridge hits** — all flows go to EOA or Other Contract addresses. The strategic intent these projects signaled at launch has not translated into institutional-rail integration.

---

## 🛠️ Data Sources

* **Stablecoin balances and transfers (USD + EUR):** `stablecoins_multichain.balances` and `stablecoins_multichain.transfers` — Dune Spellbook curated tables covering 38 chains across EVM, Solana, and Tron, with USD pricing and ISO 4217 currency tagging built in.
* **Token metadata:** `stablecoins_multichain.tokens` for symbol/decimals lookup; `tokens.erc20` for raw contract resolution where the multichain spell does not cover a token (CNHC, AxCNH).
* **Raw transfer fallback (CNH):** `tokens.transfers` filtered by hardcoded contract addresses, used for tokens absent from the curated stablecoin catalog.
* **DEX liquidity:** `dex.trades` filtered on `project IN ('uniswap', 'aerodrome', 'aerodrome_slipstream')` and partition-pruned on `block_month`.
* **Address labels:** `labels.owner_addresses` joined with `labels.owner_details` for bridge identification and counterparty classification; `labels.cex_tokens` for centralized exchange wallet tagging.

### Methodology Notes

* **Source attribution correction:** The original brief referenced `stablecoin.transfers` / `stablecoin.balances` as Steakhouse Financial tables. These tables are actually part of the Dune Spellbook (community spell). Steakhouse Financial publishes Morpho vault, Sky/Maker accounting, and lending market tables under `dune.steakhouse.*` — none of which carry the cross-chain stablecoin transfer/balance data used here.
* **Bridge filter:** The `address_category` field referenced in the brief does not exist on these tables. The functionally equivalent filter uses `LEFT JOIN labels.owner_addresses` with exclusion where `primary_category = 'Bridge'` or `contract_name` contains "bridge".
* **Window:** All queries operate on a rolling 180-day window for predictable refresh costs. Expanding the window for the EUR section would enable Pre-MiCA / Post-MiCA regime-change comparison, which is currently encoded as metadata only.
* **Query structure:** All six queries are written using CTEs with partition-column WHERE filters for cost control.
