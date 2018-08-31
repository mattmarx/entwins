global sourcedatadir "E:/Dropbox (BOSTON UNIVERSITY)/bigdata/mag/dta/"
//global sourcedatadir ../../../bigdata/mag/dta/

** start with list of papers that are co-cited and figure out which are twins
use "$sourcedatadir/magcocitedpapers", clear
/* 
will need to generate groups of twins with a unique ID corresponding to them
maybe just work your way down the list of citingpaper/cocitation and gen one twinid for all
*/

* first throw out papers missing authors
rename citedmagid magid
* keep only papers that DON'T match the list of papers missing names
merge m:1 magid using "$sourcedatadir/magpapersmissingauthornames", keep(1) nogen
rename magid citedmagid

* now get rid of papers not cited at least 5x
//rename citedpaperid paperid
//merge m:1 paperid using $sourcedatadir/magcited5x, keep(3) nogen
//rename paperid citedpaperid

* get years next so we can place them into possible cohorts
rename citedmagid magid
merge m:1 magid using "$sourcedatadir/magyear", keep(3) nogen
rename magid citedmagid
sort citingmagid cocitation year
bys citingmagid cocitation: gen yearjump = (year - year[_n-1])>1 
gen twinid = .
replace twinid = 1000 if _n==1
replace twinid = twinid[_n-1] + !(citingmagid==citingmagid[_n-1] & cocitation==cocitation[_n-1] & yearjump==0) if _n>1
drop yearjump
bys twinid: gen numtwins = _N
keep if numtwins==2
drop numtwins

** no overlapping authors
rename citedmagid magid
joinby magid using "$sourcedatadir/magauthoraffiliation"
rename magid citedmagid
bys twinid authorid: egen twinauthorappearances = nvals(citedmagid)
gen tempduplicateauthors = twinauthorappearances>1
bys twinid citedmagid: egen duplicateauthors = max(tempduplicateauthors)
drop if duplicateauthors==1
keep citingmagid citedmagid cocitation year twinid
duplicates drop

preserve
{
  keep twinid citedmagid
  duplicates drop
  save candidatetwins, replace
  use candidatetwins, clear
  * find all the papers that cite each cited paper (not just jointly - need full list)
  //joinby citedmagid using $sourcedatadir/PaperReferences
  joinby citedmagid using "$sourcedatadir/magcitations"
  * for each twin, count the unique number of forward citations for the two twins
  bys twinid: egen twinpaperunioncites = nvals(citingmagid)
  * for each twin count the number of forward citations that show up for boht of them.
  bys twinid citingmagid: egen numcitedpapers = nvals(citedmagid)
  gen papercitesbothtwins = numcitedpapers>1
  bys twinid: egen twinpaperintersectioncites = sum(papercitesbothtwins)
  replace twinpaperintersectioncites = twinpaperintersectioncites / 2
  gen jaccard = twinpaperintersectioncites / twinpaperunioncites
  keep twinid jaccard
  duplicates drop
  gen jaccard5 = jaccard>.5
  gen jaccard3 = jaccard>.3
  gen jaccard1 = jaccard>.1
  save twinjaccard, replace
}
restore
merge m:1 twinid using twinjaccard, keep(1 3) nogen
save twinswithjaccard, replace

use twinswithjaccard, clear
rename citingmagid withinparencitingmagid
joinby citedmagid using "$sourcedatadir/magreferences"
* now have <parenciter><cited><otherciter>
* figure out whether otherciter cited all twins (=2)
rename citingmagid newcitingmagid
bys twinid newcitingmagid: egen numtwinscited = nvals(citedmagid)
drop if numtwinscited==1
drop numtwinscited
* now mark where withinparen is same as the new citer
gen notnewciter = withinparencitingmagid==newcitingmagid
bys twinid newcitingmagid: egen covered = max(notnewciter)
drop if covered==1
drop notnewciter covered
keep twinid
duplicates drop
gen jointlycitedoutsideparens = 1
save jointlycitedoutsideparens, replace

use twinswithjaccard, clear
merge m:1 twinid using jointlycitedoutsideparens, keep(1 3) nogen
replace jointlycitedoutsideparens = 0 if missing(jointlycitedoutsideparens)
drop citingmagid 
rename citedmagid magid
save magtwins, replace
use magtwins, clear


count
tab jointlycitedoutsideparens
tab jointlycitedoutsideparens jaccard5
tab jointlycitedoutsideparens jaccard3
tab jointlycitedoutsideparens jaccard1


* if you want to check that the names match the cites
gen authororder = 1
joinby magid authororder using "$sourcedatadir/magauthoraffiliation", unmatched(master)
drop authororder
rename magid twinmagid
merge m:1 authorid using "$sourcedatadir/magauthorname", keep(1 3) nogen
merge m:1 affiliationid using "$sourcedatadir/magaffiliationames", keep(1 3) nogen
rename twinmagid magid
merge m:1 magid using "$sourcedatadir/magtitles", keep(1 3) nogen
drop _merge
gen alwaysameparen = 1 - jointlycitedoutsideparens
drop jointlycitedoutsideparens
drop authorid affiliationid
order twinid magid cocitation alwaysameparen jaccard* 
sort twinid
gen firstinitial = regexs(1) if regexm(authorname, "^([a-zA-Z])")
gen lastname = regexs(1) if regexm(authorname, "([a-zA-Z\'\-]*)$")
gen name2match = firstinitial + lastname
bysort twinid: egen numnames = nvals(name2match)
save magtwins1stauthoraffil, replace
use magtwins1stauthoraffil, clear
keep twinid paperid
export delimited using magtwinidpaperid, replace

STOPPY


/* RESURRECT IF YOU PERMI MORE THAN TWINS (TRIPLETS, ETC)
drop twins more than a year apart
bys twinid: egen firstyear = min(year)
bys twinid: egen finalyear = max(year)
gen twinyearspan = finalyear - firstyear
drop if twinyearspan>1
*/


* get a snapshot for David to review.

use magtwins1stauthoraffil, clear
gen randnum = uniform()
bys twinid: replace randnum = randnum[_N]
keep if randnum>.99
keep twinid magid cocitation year authorname papertitle
order twinid magid year authorname papertitle cocitation
rename authorname firstauthor
export excel using "D:\Dropbox\research\entwins\data\magcandidatetwins.xls", firstrow(variables) replace

* re-import and see whether David's "closeness' ratings correspond to Bikard heuristics
import excel using magcandidatetwins_dh.xls, firstrow clear
drop year firstauthor papertitle cocitation
merge 1:1 twinid magid using magtwins1stauthoraffil, keep(3) nogen keepusing(alwaysameparen jaccard*)
drop magid
duplicates drop
summ closeness
ttest closeness, by(alwaysameparen)
corr closeness jaccard
ttest closeness, by(jaccard5)
ttest closeness, by(jaccard3)
ttest closeness, by(jaccard1)
summ closeness if jaccard5==1 & alwaysameparen==1
summ closeness if jaccard3==1 & alwaysameparen==1
summ closeness if jaccard1==1 & alwaysameparen==1

ttest closeness if jaccard5==1, by(alwaysameparen)
ttest closeness if jaccard3==1, by(alwaysameparen)
ttest closeness if jaccard1==1, by(alwaysameparen)



