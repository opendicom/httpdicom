//
//  DRS+zipped.h
//  httpdicom
//
//  Created by jacquesfauquex on 20180117.
//  Copyright © 2018 ridi.salud.uy. All rights reserved.
//

// dcm.zip?
//         StudyInstanceUID={UID} || AccessionNumber={AC} || SeriesInstanceUID={UID}
//                                                                                  &pacs={oid}


#import "DRS.h"

@interface DRS (zipped)

-(void)addZippedHandler;

@end
