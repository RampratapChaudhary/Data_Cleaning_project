create database property;
use property;
show tables;
select * from nashville_housing;
--standardize date format
ALTER TABLE nashville_housing
add SaleDateConverted date;

UPDATE nashville_housing
SET saleDateConverted = STR_TO_DATE(SaleDate, '%M %e, %Y');

---Populate property address data
select * from nashville_housing where propertyaddress is null 
order by parcelID;

UPDATE nashville_housing SET propertyaddress = NULL WHERE propertyaddress = '';

UPDATE nashville_housing a
JOIN nashville_housing b
ON a.parcelID = b.parcelID AND a.uniqueID <> b.uniqueID
SET a.propertyaddress = IFNULL(a.propertyaddress, b.propertyaddress)
WHERE a.propertyaddress IS NULL;

---Breaking out address into individual columns(Address,City,State)
SELECT 
    SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS address1,
    SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1, LENGTH(PropertyAddress)) AS address2
FROM nashville_housing;

ALTER TABLE nashville_housing
add propertySplitaddress varchar(255);

UPDATE nashville_housing
SET propertySplitaddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);

ALTER TABLE nashville_housing
add propertySplitCity varchar(255);

UPDATE nashville_housing
SET propertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1, LENGTH(PropertyAddress));

SELECT * FROM nashville_housing; 

SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(owneraddress, ',', ',,'), ',,', 1), ',', -1),
       SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(owneraddress, ',', ',,'), ',,', 2), ',', -1),
       SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(owneraddress, ',', ',,'), ',,', 3), ',', -1) 
FROM nashville_housing;

ALTER TABLE nashville_housing
add ownerSplitAddress varchar(255);

UPDATE nashville_housing
SET ownerSplitAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(owneraddress, ',', ',,'), ',,', 1), ',', -1);

ALTER TABLE nashville_housing
add ownerSplitCity varchar(255);

UPDATE nashville_housing
SET ownerSplitCity  = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(owneraddress, ',', ',,'), ',,', 2), ',', -1);

ALTER TABLE nashville_housing
add ownerSplitstate varchar(255);

UPDATE nashville_housing
SET ownerSplitstate  = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(owneraddress, ',', ',,'), ',,', 3), ',', -1);

SELECT * FROM nashville_housing; 

--- Change Y AND N to yes and NO in "Sold as vacant" field
select distinct(SoldAsVacant),count(SoldAsVacant)
from nashville_housing group by SoldAsVacant order by 2;

select SoldAsVacant, case when SoldAsVacant='Y' then 'Yes'
                          when SoldAsVacant='N' then 'No' 
                          ELSE SoldAsVacant
                          End from nashville_housing;
                          
 UPDATE nashville_housing
SET SoldAsVacant = CASE 
                       WHEN SoldAsVacant = 'Y' THEN 'Yes'
                       WHEN SoldAsVacant = 'N' THEN 'No'
                       ELSE SoldAsVacant
                   END
WHERE SoldAsVacant IN ('Y', 'N');

--- Remove duplicates
with RowNumCTE AS(SELECT *, ROW_NUMBER() OVER(partition by parcelID,propertyaddress,
salePrice,SaleDate,legalReference order by uniqueID) ROW_NUM
from nashville_housing)
delete from RowNumCTE WHERE ROW_NUM>1 ---ORDER BY propertyAddress;

CREATE TEMPORARY TABLE temp_table
SELECT MIN(uniqueID) AS min_uniqueID
FROM nashville_housing
GROUP BY parcelID, propertyaddress, salePrice, SaleDate, legalReference;

DELETE FROM nashville_housing
WHERE uniqueID NOT IN (
    SELECT min_uniqueID
    FROM temp_table
);

DROP TEMPORARY TABLE IF EXISTS temp_table;
select * from nashville_housing 
	 
---- Delete unused columns
ALTER TABLE nashville_housing
  DROP COLUMN owneraddress,
  DROP COLUMN taxDistrict,
  DROP COLUMN propertyAddress;

	
