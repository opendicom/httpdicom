//wadors multipart/related;type=application/dicom
 
// /studies/{StudyInstanceUID}
//http://dicom.nema.org/medical/dicom/current/output/html/part18.html#sect_6.5.1
 
// /studies/{StudyInstanceUID}/series/{SeriesInstanceUID}
//http://dicom.nema.org/medical/dicom/current/output/html/part18.html#sect_6.5.2
 
// /studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}
//http://dicom.nema.org/medical/dicom/current/output/html/part18.html#sect_6.5.3
 
//Accept: multipart/related;type="application/dicom"

//additional parameter: pacs={oid}


#import "DRS.h"

@interface DRS (wadors)

-(void)addWadorsHandler;

@end
