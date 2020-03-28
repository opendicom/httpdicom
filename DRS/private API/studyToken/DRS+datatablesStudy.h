#import "DRS.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark enums

enum P {
   PKey,
   PID,
   PName,
   PIssuer,
   PBirthDate,
   PSex
};

enum E{
   EKey,
   EUID,
   EDescription,
   EDate,
   ETime,
   EAN,
   EID,
   ERef,
   ERead,
   ENumSeries,
   EModalities,
   EInstitution,
   ESocial,
   EANIssuerId,
   EANIssuerUID,
   EANIssuerTyp,
};


enum DE {
   DEEmpty,
   DEDatatablesSeries,
   DERead,
   DEDatatablesPatient,
   DEName,
   DEDateTime,
   DEModalities,
   DEDescription,
   DERef,
   DESocial,
   DEIssuer,
   DEBirthDate,
   DESex,
   DEAN,
   DEANIssuerUID,
   DEID,
   DEUID,
   DEDateTime2,
   DEInstitution,
   DEPKey,
   DEEKey,
   DEPacs,
   DEPID
};




@interface DRS (datatablesStudy)

+(void)datateblesStudySql4dictionary:(NSDictionary*)d;

/*
 sources
 =======
 
 d
 -
 callback
 draw
 
 columns
 
 start
 length
 search%5Bvalue%5D
 search%5Bregex%5D
 date_start
 date_end
 username
 useroid
 session
 custodiantitle
 aet
 role
 max
 new
 _

 
 SQL Patient
 -----------
 
 PKey       = P[0][0]
 PID        = P[0][1]
 PName      = P[0][2] removeTrailingCarets
 PIssuer    = P[0][3]
 PBirthDate = P[0][4]
 PSex       = P[0][5]

 SQL Study
 ---------
 
 EKey         = E[0][0]
 EUID         = E[0][1]
 EDescription = E[0][2]
 EDate        = E[0][3] iso
 ETime        = E[0][4] iso
 EAN          = E[0][5]
 EID          = E[0][6]
 ERef         = E[0][7] removeTrailingCarets
 ERead        = E[0][8] removeTrailingCarets = custom3
 ENumSeries   = E[0][9]
 EModalities  = E[0][10]
 EInstitution = E[0][11] = custom1
 ESocial      = E[0][12] = custom2
 EANIssuerId  = E[0][13]
 EANIssuerUID = E[0][14]
 EANIssuerTyp = E[0][15]

 
 
 array format
 ============
 
 @[
 0 (0)  ""
 1 (1-3)  "
    datatables/series?AccessionNumber=%@
    &IssuerOfAccessionNumber.UniversalEntityID=%@
    &StudyInstanceUID= %@
    &session=%@
    [EAN][EANIssuerUID][EUID]
    "
 2 (4)  ERead
 3 (5-6)  "
    datatables?PatientID=%@
    &IssuerOfPatientID.UniversalEntityID=%@
    &session=%@
    [PID][PIssuer]
    "
 4 (7)  PName,
 5 (8  EDateTime,
 6 (9  EModalities
 7 (10 EDescription
 8 (11 ERef
 9 (12 ESocial
 10 (13 PIssuer
 11 (14 PBirthDate
 12 (15 PSex
 13 (16 EAN
 14 (17 EANIssuerUID
 15 (18 EID
 16 (19 EUID
 17 (20 EDateTime
 18 (21 EInstitution
 
 19 (22 PKey
 20 (23 EKey
 21 (24 devOID
 22 (25 cache
 23 (26 PID
 ]
 
 */
@end

NS_ASSUME_NONNULL_END
