SELECT *
FROM cbsa;

SELECT *
FROM drug;

SELECT *
FROM fips_county;

SELECT *
FROM overdose_deaths;

SELECT *
FROM population;

SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM zip_fips;

--1a.	Which prescriber had the highest total number of claims (totaled over all drugs)? 		  Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) AS sum_tcc
FROM prescription
GROUP BY npi
ORDER BY sum_tcc DESC;
--npi 1881634483, sum_ttc 99707
--20592 rows

--1b.	Repeat the above, but this time report the nppes_provider_first_name, 					nppes_provider_last_org_name,  specialty_description, and the total number of 			claims.

SELECT COUNT(DISTINCT npi)
FROM prescriber;
--25050, some prescribers don't appear in prescription

SELECT COUNT(DISTINCT npi)
FROM prescription;
--20592

SELECT npi
FROM prescriber
WHERE npi IS NULL;
--none

SELECT *
FROM prescription
WHERE npi = 1194772178;
--npi from prescriber not on prescription

SELECT npi
FROM prescription
WHERE total_claim_count IS NULL;
--none

SELECT npi, COUNT(*)
FROM prescriber
GROUP BY npi
HAVING 
    COUNT(npi) >1;
--none

SELECT npi
FROM prescriber
INTERSECT
SELECT npi
FROM prescription;
--20592

(SELECT DISTINCT npi
FROM prescription)
EXCEPT
(SELECT npi
FROM prescriber);
--none

SELECT npi, SUM(total_claim_count) AS sum_tcc
FROM prescription
GROUP BY npi
ORDER BY sum_tcc DESC;

--1b. 	answer here

SELECT 	nppes_provider_first_name, 
		nppes_provider_last_org_name, 
		specialty_description,			
		SUM(total_claim_count) AS sum_tcc
FROM prescriber LEFT JOIN prescription USING(npi)
GROUP BY 	nppes_provider_first_name, 		
			nppes_provider_last_org_name, 
			specialty_description
ORDER BY sum_tcc DESC NULLS LAST;


--2a. 	Which specialty had the most total number of claims (totaled over all drugs)?

SELECT 	specialty_description,			
		SUM(total_claim_count) AS sum_tcc
FROM prescriber LEFT JOIN prescription USING(npi)
GROUP BY specialty_description
ORDER BY sum_tcc DESC NULLS LAST;

--Family Practice


--2b. 	Which specialty had the most total claims for opioids?

SELECT 	specialty_description,			
		SUM(total_claim_count) AS sum_tcc_opioids
FROM prescriber LEFT JOIN prescription USING(npi)
				INNER JOIN drug USING(drug_name)
				WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY sum_tcc_opioids DESC NULLS LAST;

--Nurse Practitioner 

--2c. 	**Challenge Question:** Are there any specialties that appear in the prescriber 		table that have no associated prescriptions in the prescription table?

(SELECT DISTINCT specialty_description
FROM prescriber)
EXCEPT
(SELECT specialty_description
FROM prescriber
INNER JOIN prescription USING(npi)
GROUP BY specialty_description);



--2d.	**Difficult Bonus:** *Do not attempt until you have solved all other problems!* 		For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT specialty_description, SUM(total_claim_count) AS sum_ttc
FROM prescriber
JOIN prescription USING(npi)
JOIN drug USING(drug_name)
GROUP BY specialty_description;

SELECT SUM(total_claim_count) AS sum_opioid_ttc
FROM prescriber
JOIN prescription USING(npi)
JOIN drug USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description;

SELECT specialty_description, (SELECT SUM(total_claim_count)
								FROM prescriber
								JOIN prescription USING(npi)
								JOIN drug USING(drug_name)
								WHERE opioid_drug_flag = 'Y'
								GROUP BY specialty_description) / 										(SUM(total_claim_count))
FROM prescriber
JOIN prescription USING(npi)
JOIN drug USING(drug_name)
GROUP BY specialty_description;

WITH sum_opioid_ttc AS (SELECT SUM(total_claim_count)
						FROM prescriber
						JOIN prescription USING(npi)
						JOIN drug USING(drug_name)
						WHERE opioid_drug_flag = 'Y'
						GROUP BY specialty_description)
SELECT specialty_description, sum_opioid_ttc/SUM(total_claim_count)
FROM prescriber
JOIN prescription USING(npi)
JOIN drug USING(drug_name)
JOIN sum_opioid_ttc 
GROUP BY specialty_description;
 
--3a. 	Which drug(generic_name) had the highest total drug cost?

SELECT drug_name, SUM(total_drug_cost) AS highest_sum_tdc
FROM prescription
GROUP BY drug_name
ORDER BY highest_sum_tdc DESC;

SELECT drug_name, generic_name, SUM(total_drug_cost) AS highest_sum_tdc
FROM prescription
LEFT JOIN drug USING(drug_name)
GROUP BY drug_name, generic_name
ORDER BY highest_sum_tdc DESC NULLS LAST;

--I think correct results below aggregate duplicate generic drugs and totals-- 

SELECT generic_name, SUM(total_drug_cost::money) AS highest_sum_tdc
FROM prescription
LEFT JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY highest_sum_tdc DESC NULLS LAST;

--Insulin Glargine, Hum.Rec.Anlog $104264066.35



--3b. 	Which drug(generic name) has the highest total cost per day? 		**Bonus: Round your 		 cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT *
FROM prescription;

SELECT DISTINCT drug_name
FROM prescription; --1821

SELECT DISTINCT drug_name
FROM drug;

SELECT DISTINCT generic_name
FROM drug; --1787

SELECT drug_name, SUM(total_day_supply)/SUM(total_30_day_fill_count)
FROM prescription
GROUP BY drug_name
ORDER BY drug_name;
--checking total_day_supply value, roughly 30 for most, in ERD - some have 12 - ask later

SELECT drug_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS 					   highest_cost_per_day
FROM prescription
GROUP BY drug_name
ORDER BY highest_cost_per_day DESC NULLS LAST;

SELECT drug_name, generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS highest_cost_per_day
FROM prescription
FULL JOIN drug USING(drug_name)
GROUP BY drug_name, generic_name
ORDER BY highest_cost_per_day DESC NULLS LAST;

--same answers each way, but would still use the one below to make sure duplicate generic results are aggregated--

SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS highest_cost_per_day
FROM prescription
LEFT JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY highest_cost_per_day DESC;
--C1 Esterase Inhibitor 3495.22


--4a. 	For each drug in the drug table, return the drug name and then a column named 			'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 			'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 			'neither' for all other drugs.

SELECT drug_name,
			CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug;
			

--4b.	Building off of the query you wrote for part a, determine whether more was spent 		(total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as 		MONEY for easier comparision.

SELECT 		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type,
			SUM(total_drug_cost::money)
FROM drug
JOIN prescription USING(drug_name)
GROUP BY drug_type;
--more spent on opioids



--5a.	How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information 			for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%';
--10

SELECT cbsaname
FROM cbsa
WHERE cbsaname LIKE '%TN%'
GROUP BY cbsaname;
--10


--5b.	Which cbsa has the largest combined population? Which has the smallest? Report 			the CBSA name and total population.
		--cbsa is core based statistical area
		--fipscounty is federal information processing area

SELECT *
FROM cbsa;

SELECT DISTINCT fipscounty
FROM cbsa; --1237 rows

SELECT COUNT(DISTINCT cbsaname)
FROM cbsa; --409 rows

SELECT COUNT(DISTINCT cbsa)
FROM cbsa; --409 rows

SELECT *
FROM population; --95 rows

SELECT DISTINCT fipscounty
FROM population; --95 rows

SELECT cbsaname, SUM(population) AS cbsa_pop
FROM cbsa
INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY cbsa_pop DESC NULLS LAST
LIMIT 1;
-- largest - Nashville-Davidson-Murfreesboro-Franklin, TN 1830410

SELECT cbsaname, SUM(population) AS cbsa_pop
FROM cbsa
INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY cbsa_pop
LIMIT 1;
-- smallest - Morristown, TN 116352

--5c.	What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, SUM(population) AS non_cbsa_county_pop
FROM cbsa
FULL JOIN population USING(fipscounty)
LEFT JOIN fips_county USING(fipscounty)
WHERE cbsa IS NULL
GROUP BY county
ORDER BY non_cbsa_county_pop DESC NULLS LAST
LIMIT 1;

--fipscounty 47155, Sevier County, pop 95523

WITH fips_except AS ((SELECT fipscounty
 					FROM population
					GROUP BY fipscounty)
 					EXCEPT
 					(SELECT fipscounty
 					FROM cbsa
 					GROUP BY fipscounty))
SELECT fipscounty, SUM(population) AS fips_pop
FROM fips_except
JOIN population USING (fipscounty)
GROUP BY fipscounty
ORDER BY fips_pop DESC
LIMIT 1;
--another way to solve, but less efficient

--6a.	Find all rows in the prescription table where total_claims is at least 3000. 			Report the drug_name and the total_claim_count.

SELECT *
FROM prescription;

SELECT *
FROM prescription
WHERE total_claim_count > 3000;

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000;


--6b.	For each instance that you found in part a, add a column that indicates whether 		the drug is an opioid.

SELECT*
FROM drug;

SELECT drug_name, total_claim_count, opioid_drug_flag 
FROM prescription
JOIN drug USING(drug_name)
WHERE total_claim_count > 3000
ORDER BY opioid_drug_flag DESC;

--6c.	Add another column to you answer from the previous part which gives the 				prescriber first and last name associated with each row.

SELECT drug_name, total_claim_count, opioid_drug_flag, nppes_provider_first_name, nppes_provider_last_org_name
FROM prescription
JOIN drug USING(drug_name)
JOIN prescriber USING(npi)
WHERE total_claim_count > 3000;
--Dr. David Coffey is in trouble. I was joking but I just learned he /is/ actually in jail. ;)


--7. 	The goal of this exercise is to generate a full list of all pain management 			specialists in Nashville and the number of claims they had for each opioid. 			**Hint:** The results from all 3 parts will have 637 rows.


--7a.	First, create a list of all npi/drug_name combinations for pain management 				specialists (specialty_description = 'Pain Managment') in the city of Nashville 		(nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag 		= 'Y'). **Warning:** Double-check your query before running it. You will only 			need to use the prescriber and drug tables since you don't need the claims 				numbers yet.

SELECT npi
FROM prescriber
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
AND prescriber.specialty_description = 'Pain Management';
--7

SELECT drug_name
FROM drug
WHERE opioid_drug_flag = 'Y';
--91 
--7*91 = 637


SELECT prescriber.npi, drug.drug_name
FROM prescriber
CROSS JOIN drug
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
AND prescriber.specialty_description = 'Pain Management'
AND drug.opioid_drug_flag = 'Y'
ORDER BY prescriber.npi;



--7b.	Next, report the number of claims per drug per prescriber. Be sure to include all 		combinations, whether or not the prescriber had any claims. You should report the 		npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi, drug.drug_name, prescription.total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription ON prescriber.npi = prescription.npi AND drug.drug_name = prescription.drug_name
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
AND prescriber.specialty_description = 'Pain Management'
AND drug.opioid_drug_flag = 'Y'
ORDER BY total_claim_count DESC NULLS LAST;


--7c.	Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi, drug.drug_name, COALESCE(prescription.total_claim_count, 0) AS total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription ON prescriber.npi = prescription.npi AND drug.drug_name = prescription.drug_name
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
AND prescriber.specialty_description = 'Pain Management'
AND drug.opioid_drug_flag = 'Y'
ORDER BY total_claim_count DESC NULLS LAST;

SELECT *
FROM prescription
WHERE npi = 1457685976;



--***BONUS***--
--1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT DISTINCT npi
FROM prescription;
--20592

SELECT DISTINCT npi
FROM prescriber;
--25050

(SELECT DISTINCT npi
FROM prescriber)
EXCEPT
(SELECT DISTINCT npi
FROM prescription)
--4458

--2.
--a.	Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) AS sum_ttc
FROM drug
JOIN prescription USING(drug_name)
JOIN prescriber USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY sum_ttc DESC
LIMIT 5;


--b.	Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(total_claim_count) AS sum_ttc
FROM drug
JOIN prescription USING(drug_name)
JOIN prescriber USING(npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY sum_ttc DESC
LIMIT 5;

--c.	Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

(SELECT generic_name, SUM(total_claim_count) AS sum_ttc
FROM drug
JOIN prescription USING(drug_name)
JOIN prescriber USING(npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY sum_ttc DESC
LIMIT 5)
UNION
(SELECT generic_name, SUM(total_claim_count) AS sum_ttc
FROM drug
JOIN prescription USING(drug_name)
JOIN prescriber USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY sum_ttc DESC
LIMIT 5);




--3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--a.	First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT npi, SUM(total_claim_count) AS sum_ttc, 'Nashville' AS city
FROM prescriber
JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'NASHVILLE'
GROUP BY npi
ORDER BY sum_ttc DESC
LIMIT 5;

--b.	Now, report the same for Memphis.

SELECT npi, SUM(total_claim_count) AS sum_ttc, 'Memphis' AS city
FROM prescriber
JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'MEMPHIS'
GROUP BY npi
ORDER BY sum_ttc DESC
LIMIT 5;

--c.	Combine your results from a and b, along with the results for Knoxville and Chattanooga.

(SELECT npi, SUM(total_claim_count) AS sum_ttc, 'Nashville' AS city
FROM prescriber
JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'NASHVILLE'
GROUP BY npi
ORDER BY sum_ttc DESC
LIMIT 5)
UNION ALL
(SELECT npi, SUM(total_claim_count) AS sum_ttc, 'Memphis' AS city
FROM prescriber
JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'MEMPHIS'
GROUP BY npi
ORDER BY sum_ttc DESC
LIMIT 5)
UNION ALL
(SELECT npi, SUM(total_claim_count) AS sum_ttc, 'Knoxville' AS city
FROM prescriber
JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'KNOXVILLE'
GROUP BY npi
ORDER BY sum_ttc DESC
LIMIT 5)
UNION ALL
(SELECT npi, SUM(total_claim_count) AS sum_ttc, 'Chattanooga' AS city
FROM prescriber
JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'Chattanooga'
GROUP BY npi
ORDER BY sum_ttc DESC
LIMIT 5);



--4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.



--5.
--a.	Write a query that finds the total population of Tennessee.



--b.	Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.



