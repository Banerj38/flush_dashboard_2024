-- ===================================================================
-- DATA FOR MASSACHUSETTS 2024 FLU SHOT DASHBOARD (TABLEAU)
-- ===================================================================

-- This query extracts data for active patients (AP) eligible for flu shots in 2024.
-- 
-- Criteria for Active Patients (AP):
--   1. Must be at least 6 months old by December 15, 2024.
--   2. Must be alive (i.e., no recorded death date).
--   3. Must have visited a healthcare facility in or after 2022.
--   4. Only encounters up to December 31, 2024, are considered.

WITH AP AS (
    SELECT 
        id,
		first,
		last,
        Date_Part ('year', AGE(birthdate)) AS age,
        race, 
        ethnicity, 
        gender,
		state,
        county,
		lat,
		lon,
        healthcare_coverage, 
        income
    FROM patients
    WHERE deathdate IS NULL  -- Selecting only living patients
    AND birthdate < '2024-06-16 00:00:00'  -- Ensuring the patient is at least 6 months old by Dec 15, 2024
    AND id IN (
        -- Including only patients who have visited a healthcare facility in or after 2022
        SELECT patient 
        FROM encounters 
        WHERE stop BETWEEN '2022-12-31 23:59:59' AND '2024-12-31 23:59:59'
    )
),

-- CTE for Flu Shot Immunization Records in 2024
-- Only the first flu shot per patient is selected for the data.
IM AS (
    SELECT 
        patient AS id, 
        MIN(date) AS vax_date  -- Selecting the earliest vaccination date for each patient
    FROM immunizations
    WHERE code = 140  -- Flu shot code
    AND date BETWEEN '2024-01-01 00:00:00' AND '2024-12-31 23:59:59'
    GROUP BY patient
)

-- Generate Flu Shot Vaccination Data for Active Patients
SELECT 
    AP.id,
	AP.first,
	AP.last,
	AP.age,
    AP.race, 
    AP.ethnicity, 
    AP.gender,
	AP.state,
    AP.county,
	AP.lat,
	AP.lon,
    AP.healthcare_coverage, 
    AP.income,
    IM.vax_date,  -- Date of flu shot (if received)
    CASE 
        WHEN IM.id IS NOT NULL THEN 1 
        ELSE 0 
    END AS vax_flag  -- 1 = Received flu shot, 0 = Did not receive flu shot
FROM AP
LEFT JOIN IM ON AP.id = IM.id;
