//custodians/titles -> lista de los titulos de custodians conocidos
//custodians/titles/{title}  -> oid correspondiente
//custodians/titles/{title}/aets -> lista de las aets vinculadas al custodian
//custodians/titles/{title}/aets/{aet}  -> oid correspondiente

//custodians/oids -> lista de los oid de custodians conocidos
//custodians/oids/{OID} -> titulo correspondiente
//custodians/oids/{OID}/aeis -> lista de los oids vinculados al custodian
//custodians/oids/{OID}/aeis/{aei} -> titulo correspondiente

//notas:
// titulos y aets are easy to remember
// oids are for computers

//do we want this exposed on the net.... ???

//pacs/{pacsoid}/services
//pacs/{pacsoid}/services/{service}
//pacs/{pacsoid}/procedures?{textSearch} -> procedure Key:title dictionary
//pacs/{pacsoid}/procedures/{key}



#import "DRS.h"

@interface DRS (pacs)

-(void)addGETCustodiansHandler;

-(void)addGETPacsHandler;

@end
