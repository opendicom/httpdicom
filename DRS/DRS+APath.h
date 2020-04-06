//
//  DRS+APath.h
//  httpdicom
//
//  Created by jacquesfauquex on 20180119.
//  Copyright © 2018 opendicom.com. All rights reserved.
//

/*
 Syntax
 
 /attributes? (added patient, like in dcm4chee-arc)
 /studies/attributes?
 /studies/{StudyInstanceUID}/series/attributes?
 /series/attributes?
 /studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/attributes?
 /studies/{StudyInstanceUID}/instances/attributes?
 /instances/attributes?
 
 parameters:
 
 filters

 "pacs=" {HomeCommunityID, attribute DICOM (0040,E031) | RepositoryUniqueID, attribute DICOM (0040,E030)} if pacs is not present... trying with any locally declared pacs.

 "list=" followed by one or more APaths or APath ranges separated with a coma
 "module=" followed by the name of one or more modules, "QIDO-RS", "private"
 
 "orderby="
 
 "offset"
 "limit"
 
 ================
 
 Response header:
 X-Result-Count is used in the header of the response to indicate the total of answer found
 
 Response body: application/json
 
 {
    "req":  {
       "uri": "http://",
       "date": 2017
    },
    "resp": {
       "status": 200,
       "offset": 1,
       "limit": 20,
       "count": 100,
       "next": "http://",
       "date": "20170101"
    },
    "data": {
       "uids": [
          "studyUID_seriesUID_instanceUID"
          ],
       "list": [
          {
             "apath": [
                "aaaaaaaa.bbbbbbbb",
                "cccccccc$.~FD",
                "dddddddd",
                "eeeeeeee"
             ],
             "value": [
                "X^Y",
                [ 6.5454 , 6.4343 ],
                null,
                {"bulkdataURI": "http://"}
             ]
          }
       ],
       "module1": [
       {
          "apath": [],
          "value": []
       }
       ]
    },
    "dict": {
       "tag": ["00100010"],
       "vr": ["PN"],
       "key": ["PatientName"]
    },
    "err": {
       "client": "",
       "server": ""
    }
 }
 */

#define queueconcurrency 4

#define patientLevel 0
#define patientBottomFilterNumber 16

#define IssuerOfPatientID 0
#define IssuerOfPatientIDLocalNamespaceEntityID 1
#define IssuerOfPatientIDUniversalEntityID 2
#define IssuerOfPatientIDUniversalEntityIDType 3
#define PatientID 4
#define PatientName 5
#define PatientBirthDate 6
#define PatientSex 7


#define studyLevel 1
#define studyBottomFilterNumber 39

//procedure code 17+
#define ProcedureCodeValue 17
#define ProcedureCodingSchemeDesignator 18
#define ProcedureCodeMeaning 19

//study 20+
#define StudyInstanceUID 20
#define StudyDescription 21
#define StudyDate 22
#define StudyTime 23
#define StudyID 24

#define AccessionNumber 29

#define IssuerOfAccessionNumberLocalNamespaceEntityID 30
#define IssuerOfAccessionNumberUniversalEntityID 31
#define IssuerOfAccessionNumberUniversalEntityIDType 32
#define ReferringPhysicianName 33
#define NameOfPhysiciansReadingStudy 34
#define ModalitiesInStudy 35
#define NumberOfStudyRelatedSeries 36
#define NumberOfStudyRelatedInstances 37


#define seriesLevel 2
#define seriesBottomFilterNumber 59

//series 40+
#define SeriesInstanceUID 40
#define Modality 41
#define SeriesDescription 42
#define SeriesNumber 43
#define BodyPartExamined 44

#define StationName 47
#define InstitutionalDepartmentName 48
#define InstitutionName 49
#define PerformingPhysicianName 50

#define InstitutionCodeValue 52
#define InstitutionschemeDesignator 53

#define PerformedProcedureStepStartDate 55
#define PerformedProcedureStepStartTime 56
#define RequestScheduledProcedureStepID 57
#define RequestProcedureID 58

#define NumberOfSeriesRelatedInstances 59


#define instanceLevel 3
#define instanceBottomFilterNumber 63

//instances 60+
#define SOPInstanceUID 60
#define SOPClassUID 61
#define InstanceNumber 62
#define HL7InstanceIdentifier 63

//the 64 bits correspond to the array of 64 queryable tags
#define specificFilterBitmap 0x90040106E0DA0070
#define genericFilterBitmap  0x60338E0901240085


#import "DRS.h"

@interface DRS (APath)

@property (class, nonatomic, readonly) NSArray               *levels;
@property (class, nonatomic, readonly) NSArray               *key;
@property (class, nonatomic, readonly) NSArray               *tag;
@property (class, nonatomic, readonly) NSArray               *vr;

-(void)addAPathHandler;

@end
