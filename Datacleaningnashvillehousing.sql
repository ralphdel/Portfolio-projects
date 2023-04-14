/* Nashville housing data cleaning

*/

-- View tables, Parameters, Variable 
SELECT  *
FROM nashvillehousing


--Quick overview of the dataset
SELECT DISTINCT landuse
FROM nashvillehousing 

-- Covert SaleDate from date time to date (standardize date format)
SELECT SaleDate, CAST(saledate as  date)
FROM nashvillehousing

-- Update Nashville Housing table with new date format
ALTER TABLE  NashvilleHousing
ADD SaleDatenew date 

UPDATE  Nashvillehousing
SET Saledatenew = CAST(saledate as  date)

-- DROP THE PREVIOUS SALESDATE COLUMN 
ALTER TABLE nashvillehousing 
DROP COLUMN saledate 


--3) Filling the NULL PROPERTY ADDRESS WITH 
SELECT   Parcelid, propertyaddress
FROM nashvillehousing
WHERE  propertyaddress IS NOT NULL

/* We can see from above that 29 rows doesn't have a property address */
SELECT   Parcelid, propertyaddress
FROM nashvillehousing
ORDER BY Parcelid
/* WE can see that for most the data with same parcelid, the propertyadress is the same 
Therefore houses with the same parcelid, but the NULL address can be filled with the equivqlent property address

-- SELF JOIN THE TABLE ON PARECELID since it's the same for the two table and where 
 unique */
SELECT a.parcelid, a.propertyaddress,-- ISNULL(a.propertyaddress, b.PropertyAddress)
b.parcelid, b.propertyaddress
FROM nashvillehousing a
JOIN nashvillehousing b
ON a.parcelid=b.parcelid
AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress is  NULL

-- Update the values of the propertyaddress with tghe appropraite data.

UPDATE a
SET Propertyaddress= ISNULL(a.propertyaddress, b.PropertyAddress)
FROM nashvillehousing a
JOIN nashvillehousing b
  ON a.parcelid=b.parcelid
  AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress is NULL

----------------- Break the property address  into States, City and Address. 
SELECT CHARINDEX(',', PropertyAddress)
FROM NashvilleHousing
-- The CHARINDEX() above gives the position of the (,) in the property addrress above 

SELECT 
PropertyAddress, SUBSTRING(propertyaddress, 1, CHARINDEX(',', PropertyAddress)-1),
LEN(propertyaddress)-(CHARINDEX(',', PropertyAddress)+1) as state_len,
LEN(propertyaddress) as fullstr_length,
CHARINDEX(',',propertyaddress)+2 as Main_spacebstate,
SUBSTRING(Propertyaddress, CHARINDEX(',',propertyaddress)+2, LEN(propertyaddress)-(CHARINDEX(',', PropertyAddress)+1)) as state_string
FROM NashvilleHousing

---- i had serious issue while writing this code above because of spaces in the 
--i) for instance i didnt get to know on time that there were double spacing between 600 and 'C' in '"600  CHERRY GLEN CIR, NASHVILLE"
-- Had to use a for loop in python to get position of each character and figure out the spaces 

-->>> st = '600  CHERRY GLEN CIR, NASHVILLE'
-->>> for i in st:
--    print(f'{i} ---')

---Update table with appropraite columns and data 
ALTER TABLE nashvillehousing 
ADD propertysplitaddress varchar(255), propertysplitcity varchar(50)

UPDATE nashvillehousing 
SET propertysplitaddress = SUBSTRING(propertyaddress, 1, CHARINDEX(',', PropertyAddress)-1),
propertysplitcity=  SUBSTRING(Propertyaddress, CHARINDEX(',',propertyaddress)+2, LEN(propertyaddress)-(CHARINDEX(',', PropertyAddress)+1))

ALTER TABLE  nashvillehousing
DROP COLUMN propertyaddress


---------Now i want to split the owners address into CITY, state and address 
-- Will use PARSENAME function for this instead of SUBSTRING, checking out the owners address 
SELECT  OwnerAddress
FROM nashvillehousing
--- The address, city, and state are separated with a ',' in owneraddress column but parsename  function only works with period
-- We need to replace the ',' with '.'

SELECT PARSENAME(REPLACE(owneraddress, ',','.'), 3),
PARSENAME(REPLACE(owneraddress, ',','.'), 2),
PARSENAME(REPLACE(owneraddress, ',','.'), 1)
FROM nashvillehousing

ALTER TABLE nashvillehousing 
ADD Ownersplitaddress varchar(255), ownercity varchar(50), ownerstatecode varchar(10)

UPDATE NashvilleHousing
SET Ownersplitaddress= PARSENAME(REPLACE(owneraddress, ',','.'), 3),
ownercity=PARSENAME(REPLACE(owneraddress, ',','.'), 2),
ownerstatecode=PARSENAME(REPLACE(owneraddress, ',','.'), 1)


--Change Y AND N to Yes and No in Soldasvacant  column
--	Used case statement for this 
SELECT soldasvacant,
CASE  WHEN soldasvacant= 'Y' THEN 'Yes'
	  WHEN SoldAsVacant= 'N' THEN 'No'
	  ELSE Soldasvacant
	  END AS SoldAsVacantcorr
FROM nashvillehousing


UPDATE nashvillehousing
SET soldasvacant=CASE  WHEN soldasvacant= 'Y' THEN 'Yes'
	  WHEN SoldAsVacant= 'N' THEN 'No'
	  ELSE Soldasvacant
	  END


-----------Remove duolicates ---------------------
--some windows function such as; row_number and rank help us remove duplicates 

 WITH row_numcte AS 
				(SELECT *, ROW_NUMBER() OVER
				( PARTITION BY Parcelid,
								propertysplitcity,
								propertysplitaddress,
								saledatenew,
								saleprice,
								legalreference
							    ORDER BY Uniqueid) row_num
				FROM nashvillehousing)
SELECT *
FROM row_numcte
WHERE row_num > 1

---The code above gives us duplicates data, i.e where parcelid, salesprices, saledate,propertyaddress and legalreference are all the same
---- So the next thing we do is delete those duplicates data because we don't need them. 104 records will be deleted. 
 WITH row_numcte AS 
				(SELECT *, ROW_NUMBER() OVER
				( PARTITION BY Parcelid,
								propertysplitcity,
								propertysplitaddress,
								saledatenew,
								saleprice,
								legalreference
							    ORDER BY Uniqueid) row_num
				FROM nashvillehousing)
DELETE 
FROM row_numcte
WHERE row_num > 1

									
-----lastly delete unused column, well i made some mistake deleting some earlier, it's not advisable to do unless you get permission to do so. 
--Delete unsued column 
ALTER TABLE nashvillehousing
DROP COLUMN  owneraddress, taxdistrict 



SELECT  *
FROM nashvillehousing
