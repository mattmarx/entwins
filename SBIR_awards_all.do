forvalues i = 0/166 {
clear all
set more off
import excel "/Users/llanahan/Dropbox/NAS SBIR/SBIR awards/`i'.xlsx", sheet("Worksheet") firstrow
save "/Users/llanahan/Dropbox/NAS SBIR/SBIR awards/`i'.dta", replace
}

clear all 
set more off
use "/Users/llanahan/Dropbox/NAS SBIR/SBIR awards/0.dta"
forvalues i = 1/166 {
append using "/Users/llanahan/Dropbox/NAS SBIR/SBIR awards/`i'.dta", force
}

** clean up company name to assess how many firms there are
gen sbc = lower(Company)
replace sbc = subinstr(sbc, " ", "",.)
replace sbc = subinstr(sbc, ".", "",.)
replace sbc = subinstr(sbc, ",", "",.)
replace sbc = subinstr(sbc, "-", "",.)
egen firm_id = group(sbc)
egen tot_award_count = count(sbc), by (sbc)
* 24973 unique firm names in the dataset (1982 - 2018 (4/13/18))

gen agency = 1 if Agency == "Department of Agriculture"
replace agency = 2 if Agency == "Department of Commerce"
replace agency = 3 if Agency == "Department of Defense"
replace agency = 4 if Agency == "Department of Education"
replace agency = 5 if Agency == "Department of Energy"
replace agency = 6 if Agency == "Department of Health and Human Services"
replace agency = 7 if Agency == "Department of Homeland Security"
replace agency = 8 if Agency == "Department of Interior"
replace agency = 9 if Agency == "Department of Transportation"
replace agency = 10 if Agency == "Environmental Protection Agency"
replace agency = 11 if Agency == "National Aeronautics and Space Administration"
replace agency = 12 if Agency == "National Science Foundation"
replace agency = 13 if Agency == "Nuclear Regulatory Commission"

label define agency_nl 1 "Department of Agriculture" 2 "Department of Commerce" ///
3 "Department of Defense" 4 "Department of Education" 5 "Department of Energy" ///
6 "Department of Health and Human Services" 7 "Department of Homeland Security" ///
8 "Department of Interior" 9 "Department of Transportation"  10 "Environmental Protection Agency" ///
11 "National Aeronautics and Space Administration" 12 "National Science Foundation" ///
13 "Nuclear Regulatory Commission"
lab values agency agency_nl

* assessment of DOE firms *
egen tot_award_count_agency = count(sbc), by (sbc agency)
lab var tot_award_count "Total award count"
gen only_one_agency = 1 if tot_award_count == tot_award_count_agency
recode only_one_agency (.=0)
lab var only_one_agency "Firm recipient from only one agency"
gen only_doe = 1 if only_one_agency == 1 & agency == 5
egen only_doe_count = group(sbc) if only_doe == 1
lab var only_doe "Firm only secure award from DOE"
lab var only_doe_count "metric to count number of firms with only DOE"
sort firm_id
br firm_id agency 
by firm_id: gen ever_doe_prep = 1 if agency == 5
egen ever_doe = max(ever_doe_prep), by(firm_id)
lab var ever_doe "Firm ever secure award from DOE"
egen ever_doe_count = group(sbc) if ever_doe == 1
lab var ever_doe_count "metric to count number of firms with ever DOE"
br firm_id agency only_doe AwardYear if ever_doe == 1
* average number of awards by DOE firm
sort sbc
by sbc: gen doe_num_award = _n if ever_doe ==1
lab var doe_num_award "metric to count number of awards for ever DOE"

destring, replace 
** first year of SBIR award
gen phase = 1 if Phase == "Phase I"
replace phase = 2 if Phase == "Phase II"
gen phase1 = 1 if phase == 1
recode phase1 (.=0)
gen phase2 = 1 if phase == 2
recode phase2 (.=0)
egen first_yr_sbir = min(AwardYear), by(firm_id)
** AWARDS Data
save "/Users/llanahan/Dropbox/NAS SBIR/SBIR awards/all SBIR awards as of 041318.dta", replace
save "/Users/llanahan/Dropbox/NAS SBIR/Economics Outcome/all SBIR awards.dta", replace
preserve
drop Abstract
export delimited using "/Users/llanahan/Dropbox/NAS SBIR/Economics Outcome/all SBIR awards.csv", replace
restore 

** clean up address (first address reported)
sort sbc AwardYear phase
by sbc: gen counter = _n
keep if counter == 1
drop counter
sort firm_id
by firm_id:  gen dup = cond(_N==1,0,_n)
sum dup
drop dup
** FIRM Data
save "/Users/llanahan/Dropbox/NAS SBIR/SBIR awards/all SBIR firms as of 041318.dta", replace
save "/Users/llanahan/Dropbox/NAS SBIR/Economics Outcome/all SBIR firms.dta", replace
preserve
drop Abstract
export delimited using "/Users/llanahan/Dropbox/NAS SBIR/Economics Outcome/all SBIR firms.csv", replace
restore
