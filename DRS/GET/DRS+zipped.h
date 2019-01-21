// dcm.zip?
//         StudyInstanceUID={UID} || AccessionNumber={AC} || SeriesInstanceUID={UID}
//                                                                                  &pacs={oid}


#import "DRS.h"

@interface DRS (zipped)

-(void)addZippedHandler;

@end
