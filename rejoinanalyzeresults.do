*004 pick paper patent pair using degree of author overlap
*002 

global wosdir "../../bigdata/wos/dta/"
global andreadir "Simultaneous Discoveries (1)/Andrea/"
global fung "../../bigdata/patents/fung/"
global pv "../../bigdata/patents/patentsview/"
global vcpat "../../bigdata/patents/ewensvcpat/"
global fromscratch (0)
*** start by classifying all of the potential twins
*** this is wasted work in part becase not all of these are actual twins

if ($fromscratch==1) {
* twinids and wosids
use "$andreadir/list5_a1_yearauthors", clear
drop if missing(wosidcited1)
drop if missing(wosidcited2)
drop if missing(pairid)
keep pairid wosidcited1 wosidcited2
duplicates drop
compress
preserve
{
keep pairid wosidcited1
rename wosidcited1 wosid
save temp1, replace
}
restore
keep pairid wosidcited2
rename wosidcited2 wosid
append using temp1
erase temp1.dta
duplicates drop
save data/candidatetwinpairs, replace


*  individual papers and their characteristics, no twin info
use "$andreadir/list5_a1_yearauthors", clear
drop if missing(wosidcited1)
drop if missing(wosidcited2)
drop if missing(pairid)
drop pairid wosidciting titleciting
duplicates drop
preserve
{
 keep *1
 duplicates drop
 rename wosidcited1 wosid
 rename title1 title
 rename authors1 authors
 rename year1 year
 save temp1, replace
}
restore
keep *2
duplicates drop
rename wosidcited2 wosid
rename title2 title
rename authors2 authors
rename year2 year
append using temp1
duplicates drop
// erase temp1.dta
drop if missing(wosid)
merge 1:1 wosid using $wosdir/wospaperpatcitesorgloc, keep(3) nogen
merge 1:1 wosid using $wosdir/wosprestige, keep(3) nogen
save data/candidatetwinpaperdetails, replace

//join, into(data/candidatetwinpairs) by(wosid) keep(3) nogen

}

* are any of these candidate twins cited by patents? industry patents?
*if so, is there an author match??
*if so, does the patent belong to a VC-backed startup? a Crunchbase company?
use data/candidatetwinpaperdetails, clear
drop title year
rename wosid citedwosid
split authors, generate(author) parse(";")
drop authors
reshape long author, i(citedwosid) j(authnum)
drop authnum
drop if missing(author)
replace author = trim(author)
replace author = subinstr(author, "'","",.)
replace author = subinstr(author, ".","",.)
replace author = subinstr(author, "-","",.)
replace author = subinstr(author, " ","",.)
gen authornamefinitial = regexs(1) if regexm(author, ", ?([A-Z])")
gen authornamesur = regexs(1) if regexm(author, "(.*),")
replace authornamesur = proper(authornamesur)
gen authornamelinitial = regexs(1) if regexm(authornamesur, "^([A-Z])")
drop if missing(authornamesur)
// replace author = trim(lower(regexs(1))) if regexm(author, "^(.*),.*$")
joinby citedwosid using $wosdir/wosnpl
rename citedwosid wosid
rename citingpatent patent
merge m:1 patent using $vcpat/patentWithVC112017, keep(1 3) nogen
preserve 
{
 keep wosid patentvcbacked
 fcollapse (sum) patentvcbacked, by(wosid)
 rename patentvcbacked citesfromvcbackedpatents
 save data/candidatetwincitedbyvcpatent, replace 
}
restore
rename patent patnum
joinby patnum using $pv/patinvnames
replace invnamesur = trim(invnamesur)
replace invnamegiven = trim(invnamegiven)
gen invnamefinitial = regexs(1) if regexm(invnamegiven, "^([A-Z])")
gen invnamelinitial = regexs(1) if regexm(invnamesur, "^([A-Z])")
* drop citations from universitie
merge m:1 patnum using $pv/patacad, keep(1 3) nogen
drop if patacad==1
rename patnum patent
replace invnamesur = subinstr(invnamesur, "'","",.)
replace invnamesur = subinstr(invnamesur, ".","",.)
replace invnamesur = subinstr(invnamesur, "-","",.)
replace invnamesur = subinstr(invnamesur, " ","",.)
replace invnamesur = proper(invnamesur)
replace invnamesur = regexs(1) if regexm(invnamesur, "(.*),Jr")
replace invnamesur = regexs(1) if regexm(invnamesur, "(.*),Ii")
replace invnamesur = regexs(1) if regexm(invnamesur, "(.*),Iii")
// gen samename = author==invname
gen samefinitial = authornamefinitial==invnamefinitial
gen samelinitial = authornamelinitial==invnamelinitial
gen samesurname = 0
replace samesurname = 1 if  authornamesur==invnamesur
ustrdist authornamesur invnamesur, gen(strdist) max(5)
gen authorlen = length(authornamesur)
gen invlen = length(invnamesur)
gen pctchg = strdist / ((authorlen + invlen) / 2)
gen similarsurname = 0
replace similarsurname = 1 if invlen>5 & authorlen>5 & pctchg<=.25 & ~missing(pctchg) & authornamelinitial==invnamelinitial
gen samename = 0
replace samename = 1 if authornamefinitial==invnamefinitial & samesurname==1 | (similarsurname==1 & samelinitial==1)
replace samename = 1 if samefinitial==1 & authornamesur=="Dahlback" & invnamesur=="DahlbÃ¤Ck"
replace samename = 1 if samefinitial==1 & authornamesur=="Schuler" & invnamesur=="SchÃ¼Ler"
replace samename = 1 if samefinitial==1 & authornamesur=="Buhring" & invnamesur=="BÃ¼Hring"
replace samename = 1 if samefinitial==1 & authornamesur=="Arumae" & invnamesur=="ArumÃ¤E"
replace samename = 1 if samefinitial==1 & authornamesur=="Kvaloy" & invnamesur=="KvalÃ¸Y"
replace samename = 1 if samefinitial==1 & authornamesur=="Sudhof" & invnamesur=="SÃ¼Dhof"
replace samename = 1 if samefinitial==1 & authornamesur=="Schutz" & invnamesur=="SchÃ¼Tz"
replace samename = 1 if samefinitial==1 & authornamesur=="Muller" & invnamesur=="MÃ¼Ller"
replace samename = 1 if samefinitial==1 & authornamesur=="Niemoeller" & invnamesur=="NiemÃ¶Eller"
replace samename = 1 if samefinitial==1 & authornamesur=="Gharavi" & invnamesur=="Gharvari"
replace samename = 1 if samefinitial==1 & authornamesur=="Brezillon" & invnamesur=="BrÃ©Zillon"
replace samename = 1 if samefinitial==1 & authornamesur=="Ehrlich" & invnamesur=="Erhlich"
replace samename = 1 if samefinitial==1 & authornamesur=="Gebicki" & invnamesur=="G?Bicki"
replace samename = 1 if samefinitial==1 & authornamesur=="Hutvagner" & invnamesur=="HutvÃ¡Gner"
replace samename = 1 if samefinitial==1 & authornamesur=="Gwinn" & invnamesur=="Gwynn"
replace samename = 1 if samefinitial==1 & authornamesur=="Hobbs" & invnamesur=="Hobba"
replace samename = 1 if samefinitial==1 & authornamesur=="Huong" & invnamesur=="Huang"
replace samename = 1 if samefinitial==1 & authornamesur=="Lantz" & invnamesur=="Lentz"
replace samename = 1 if samefinitial==1 & authornamesur=="Fleig" & invnamesur=="Flieg"
replace samename = 1 if samefinitial==1 & authornamesur=="Wang" & invnamesur=="Weng"
replace samename = 1 if samefinitial==1 & authornamesur=="Macrae" & invnamesur=="Mcrae"
replace samename = 1 if samefinitial==1 & authornamesur=="Okubo" & invnamesur=="Ohkubo"
replace samename = 1 if samefinitial==1 & authornamesur=="Schenk" & invnamesur=="Shenk"
replace samename = 1 if samefinitial==1 & authornamesur=="Lantz" & invnamesur=="Lentz"
replace samename = 1 if samefinitial==1 & authornamesur=="Chent" & invnamesur=="Chen"
replace samename = 1 if samefinitial==1 & authornamesur=="Woll" & invnamesur=="Woell"
replace samename = 1 if samefinitial==1 & authornamesur=="Ito" & invnamesur=="Itoh"
replace samename = 1 if samefinitial==1 & authornamesur=="Itoh" & invnamesur=="Ito"
replace samename = 1 if samefinitial==1 & authornamesur=="Bouma" & invnamesur=="Bourna"
replace samename = 1 if samefinitial==1 & authornamesur=="" & invnamesur==""
replace samename = 1 if samefinitial==1 & authornamesur=="" & invnamesur==""
replace samename = 1 if samefinitial==1 & authornamesur=="" & invnamesur==""
replace samename = 1 if samefinitial==1 & authornamesur=="" & invnamesur==""
replace samename = 1 if samefinitial==1 & authornamesur=="" & invnamesur==""
replace samename = 0 if samefinitial==1 & authornamesur=="Martin" & invnamesur=="Marcin"
bys wosid patent: egen numauthors = nvals(author)
keep if samename==1
gen samenamevcpatent = samename==1 & patentvcbacked
sort wosid patent
keep wosid patent numauthors samename samenamevcpatent city state country wosorg author invnamegiven invnamesur
merge m:1 wosid using $wosdir/wostitle, keep(1 3) nogen
merge m:1 wosid using $wosdir/wosorg, keep(1 3) nogen
merge m:1 wosid using $wosdir/wosacad, keep(1 3) nogen
save data/paperpatcitenamematches, replace
bys wosid patent: gen numsamename = sum(samename)
bys wosid patent: gen numsamenamevcpatent = sum(samenamevcpatent)
// gcollapse (first) numauthors (sum) samename samenamevcpatent, by(wosid patent)
gen pctauthorsmatched = numsamename/numauthors
bys wosid: egen maxpctauthorsmatched = max(pctauthorsmatched)
gen wospatbestinvmatch = pctauthorsmatched==maxpctauthorsmatched
drop maxpctauthorsmatched
save numnamematchesperwospat, replace
keep patent
duplicates drop
export delimited using patentswithgscholtwinmatches, replace
STOPPY
// gcollapse (sum) samename samenamevcpatent, by(wosid)
// rename samename numpatcitenamematches
// rename samenamevcpatent numvcpatcitenamematches
// save data/numpatciteauthormatches, replace

use data/candidatetwinpaperdetails, clear
merge 1:1 wosid using data/candidatetwincitedbyvcpatent, keep(1 3) nogen
replace citesfromvcbackedpatents = 0 if missing(citesfromvcbackedpatents)
merge 1:1 wosid using data/numpatciteauthormatches, keep(1 3) nogen
replace numpatcitenamematches = 0 if missing(numpatcitenamematches)
replace numvcpatcitenamematches = 0 if missing(numvcpatcitenamematches)
merge 1:1 wosid using $wosdir/wosacad, keep(1 3) nogen
merge 1:1 wosid using $wosdir/wosjif, keep(1 3) nogen
merge 1:1 wosid using $wosdir/wosauthorprestige, keep(1 3) nogen
merge 1:1 wosid using $wosdir/wosprestige, keep(1 3) nogen
merge 1:1 wosid using $wosdir/wosgovbacked, keep(1 3) nogen
merge 1:1 wosid using $wosdir/wosappliedness, keep(1 3) nogen keepusing(wosmeshmagpatcites5yr)

* can we get # of authors?
save data/candidatetwinpaperdetails-extended, replace

 
 
** now connect these to the evaluation of whether they  are really twins 
 * start with classified list of twins we could check
//import excel using "data/googlescholardata/compiled_TwinAnalyzerResults_201806060747.xlsx", clear firstrow
import excel using "data/googlescholardata/compiled_TwinAnalyzerResults_201806171443.xlsx", clear firstrow
rename TwinPaperID pairid
drop if pairid=="CouldNotOrganize"
rename TotalNumber ncitingpapers
drop if ncitingpapers=="Error While Analyzing"
rename Filesthat nnotcitingjointly
rename AverageAdj avgadjacency
foreach x in pairid ncitingpapers nnotcitingjointly avgadjacency {
 destring `x', replace
}
replace avgadjacency = . if nnotcitingjointly==0
//drop if nnotcitingjointly==0
gsort -avgadjacency
gen njointcitingpapers = ncitingpapers - nnotcitingjointly
drop nnotcitingjointly ncitingpapers
drop if njointcitingpapers==0
* now we have the twin pair info. now merge in the papers
** first the paper IDS
merge 1:m pairid using data/candidatetwinpairs, keep(3) nogen
** now the paper details
merge m:1 wosid using data/candidatetwinpaperdetails-extended, keep(3) nogen
gen anypatcitenamematches = numpatcitenamematches>0
gen lnumpatcitenamematches = log(1+numpatcitenamematches)
gen anyvcpatcitenamematches = numvcpatcitenamematches>0
gen lnumvcpatcitenamematches = log(1+numvcpatcitenamematches)
* drop twins that are not both academic
merge m:1 wosid using $wosdir/wosacad, keep(1 3) nogen
keep if paperacad==1
bys pairid: gen ntwinpapers = _N
drop if ntwinpapers==1
save data/gscholtwinsregready, replace
/*
use data/gscholtwinsregready, clear

unique pairid
unique wosid

areg lnumpatcitenamematches numsubjectsperorg paperacadpct govbackedpaper jif wosmeshmagpatcites5yr pap2papcite5yr if avg>75, absorb(pairid)
areg lnumvcpatcitenamematches numsubjectsperorg paperacadpct govbackedpaper jif wosmeshmagpatcites5yr pap2papcite5yr if avg>75, absorb(pairid)

