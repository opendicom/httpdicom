//
//  DRS+APath.h
//  httpdicom
//
//  Created by jacquesfauquex on 20180119.
//  Copyright © 2018 opendicom.com. All rights reserved.
//

/*
 Syntax
 
 /patients/attributes? (added patient, like in dcm4chee-arc)
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
 
 Response body: json
 */

#import "DRS.h"

@interface DRS (APath)

-(void)addAPathHandler;
-(NSUInteger)countSqlProlog:(NSString*)prolog from:(NSString*)from leftjoin:(NSString*)leftjoin where:(NSString*)where;

@end
