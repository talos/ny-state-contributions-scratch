-- SELECT COUNT(*) FROM merged WHERE contract_id IS NOT NULL;
-- 2038075 not null contract IDs
--
-- 13230371 null contract IDs

-- CREATE INDEX vendor ON merged (vendor);

.headers on
.mode csv
.output top_receivers.csv

SELECT vendor,
    SUM(amount) total,
    COUNT(DISTINCT contract_id) num_contracts,
    COUNT(*) num_expenditures,
    GROUP_CONCAT(DISTINCT agency_unit) agencies FROM merged
WHERE contract_id IS NOT NULL
GROUP BY vendor
ORDER BY total DESC;
