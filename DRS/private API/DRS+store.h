//http://dicom.nema.org/medical/dicom/current/output/html/part18.html#sect_10.5

//POST /pacs/{OID}/studies/{uid}?

#import "DRS.h"

@interface DRS (store)

-(void)addPOSTstudiesHandler;

@end
