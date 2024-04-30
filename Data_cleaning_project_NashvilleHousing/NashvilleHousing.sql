select * 
from NashvilleHousing;


-- Populate Property Address Data
-- Lets use the COALESCE(or IFNULL) function to replace a null values

select *
from NashvilleHousing
where propertyaddress is null;


select 
	a.parcelid, 
	a.propertyaddress,
	b.parcelid,
	b.propertyaddress,
	coalesce(a.propertyaddress, b.propertyaddress)
from NashvilleHousing a
join NashvilleHousing b
	on a.parcelid = b.parcelid
	and a.uniqueid <> b.uniqueid
where a.propertyaddress is null;


update NashvilleHousing a
set propertyaddress = coalesce(a.propertyaddress, b.propertyaddress)
from NashvilleHousing b
where a.parcelid = b.parcelid
  and a.uniqueid <> b.uniqueid
  and a.propertyaddress is NULL;



-- Breaking out Address into Individual Columns(Address, City, State)

select 
	propertyaddress
from NashvilleHousing;


select 
	substring(propertyaddress from 1 for position(',' in propertyaddress) -1) as Address,
	substring(propertyaddress from position(',' in propertyaddress) +1) as City
from NashvilleHousing;


alter table NashvilleHousing
add propertysplitaddress varchar(200);

update NashvilleHousing
set propertysplitaddress = substring(propertyaddress from 1 for position(',' in propertyaddress) -1);

alter table NashvilleHousing
add propertysplitcity varchar(200);

update NashvilleHousing
set propertysplitcity = substring(propertyaddress from position(',' in propertyaddress) +1);



select 
	split_part(owneraddress, ',', 1) as address,     -- lets use SPLIT_PART function intead
	split_part(owneraddress, ',', 2) as city,
	split_part(owneraddress, ',', 3) as state
from NashvilleHousing;
	

alter table NashvilleHousing
add ownersplitaddress varchar(200);

update NashvilleHousing
set ownersplitaddress = split_part(owneraddress, ',', 1);

alter table NashvilleHousing
add ownersplitcity varchar(200);

update NashvilleHousing
set ownersplitcity = split_part(owneraddress, ',', 2);

alter table NashvilleHousing
add ownersplitstate varchar(200);

update NashvilleHousing
set ownersplitstate = split_part(owneraddress, ',', 3);


select *
from NashvilleHousing;


-- Change Y and N to 'Yes' adn 'No' in SoldasVacant field

select distinct soldasvacant
from NashvilleHousing;


select 
	soldasvacant,
	case when soldasvacant = 'Y' then 'Yes'
		 when soldasvacant = 'N' then 'No'
		 else soldasvacant
	end
from NashvilleHousing;


update NashvilleHousing
set
soldasvacant = 	case when soldasvacant = 'Y' then 'Yes'
		 			 when soldasvacant = 'N' then 'No'
		 			 else soldasvacant
				end;



-- Remove duplicates (be carefull while using with real data)

with RN_CTE as (
    select 
        *,
        row_number() over (partition by parcelid, propertyaddress, saledate, saleprice, legalreference
                           order by uniqueid) as rn
    FROM 
        NashvilleHousing
)
delete from NashvilleHousing
using RN_CTE
where RN_CTE.rn > 1
  and NashvilleHousing.uniqueid = RN_CTE.uniqueid;



select * from NashvilleHousing;



-- Remove unused columns (be carefull while using with real data) 
-- Anyway best practice simply just create a view from original data and then working with it

alter table NashvilleHousing
drop column propertyaddress, 
drop column owneraddress, 
drop column taxdistrict;





































