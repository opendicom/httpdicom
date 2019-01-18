//
//  DRS+custodians.h
//  httpdicom
//
//  Created by jacquesfauquex on 20180115.
//  Copyright © 2018 opendicom.com. All rights reserved.
//

//custodians/titles -> titles of known custodians
//custodians/titles/{title}  -> corresponding OIDs
//custodians/titles/{title}/aets -> application entity titles belonging to the custodian
//custodians/titles/{title}/aets/{aet}  -> corresponding OIDs

//custodians/oids -> OIDs of known custodians
//custodians/oids/{OID} -> corresponding titles
//custodians/oids/{OID}/aeis -> application entity ids belonging to the custodian
//custodians/oids/{OID}/aeis/{aei} -> corresponding titles

//notes:
// titles and aets are easy to remember
// oids are for computers

//do we want this exposed on the net.... ???



#import "DRS.h"

@interface DRS (custodians)

-(void)addCustodiansHandler;

@end
