#import "DRS.h"

@interface DRS (wadouri)

//http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.2.html
//http://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_6.3.html

//does support transitive (to other PCS) operation
//does support distributive (to inner devices) operation
//does not support response consolidation (wado uri always return one object only)

//SYNTAX
//?requestType=WADO
//&contentType=application/dicom
//&studyUID={studyUID}
//&seriesUID={seriesUID}
//&objectUID={objectUID}

//(added, optional)
//&pacs={pacsOID}
//&custodianOID={custodianOID}

//alternative processing:
//(a) proxy custodian
//(b) local entity wado
//(c) local entity sql, filesystem
//(d) not available

-(void)addWadoHandler;

@end
