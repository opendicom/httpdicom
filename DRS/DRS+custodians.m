//
//  DRS+custodians.m
//  httpdicom
//
//  Created by jacquesfauquex on 20180115.
//  Copyright © 2018 opendicom.com. All rights reserved.
//

#import "DRS+custodians.h"
#import "K.h"

@implementation DRS (custodians)

-(void)addCustodiansHandler
{
    [self addHandler:@"GET" pathFirstSegment:@"custodians" processBlock:
     ^(RSRequest* request, RSCompletionBlock completionBlock)
     {completionBlock(^RSResponse* (RSRequest* request){
        
        //using NSURLComponents instead of RSRequest
        NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
        
        NSArray *urlPathComp=[urlComponents.path componentsSeparatedByString:@"/"];
        NSUInteger urlPathCount=[urlPathComp count];
        if ([[urlPathComp lastObject]isEqualToString:@""]) urlPathCount--;
        
        if (urlPathCount<3) return [RSErrorResponse responseWithClientError:400 message:@"%@ [no handler]",urlComponents.path];
        
        if ([urlPathComp[2]isEqualToString:@"titles"])
        {
            //custodians/titles
            if (urlPathCount==3) return [RSDataResponse responseWithData:DRS.titlesdata contentType:@"application/json"];
            
            NSUInteger p3Length = [urlPathComp[3] length];
            if (  (p3Length>16)
                ||![K.SHRegex numberOfMatchesInString:urlPathComp[3] options:0 range:NSMakeRange(0,p3Length)])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{title} datatype should be DICOM SH]",urlComponents.path];
            
            if (!DRS.titles[urlPathComp[3]])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{title} not found]",urlComponents.path];
            
            //custodians/titles/{TITLE}
            if (urlPathCount==4) return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:DRS.titles[urlPathComp[3]]] options:0 error:nil] contentType:@"application/json"];
            
            if (![urlPathComp[4]isEqualToString:@"aets"])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{title} unique resource is 'aets']",urlComponents.path];
            
            //custodians/titles/{title}/aets
            if ((urlPathCount==5)||((urlPathCount==6)&&![urlPathComp[5]length]))
                return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[DRS.titlesaets objectForKey:urlPathComp[3]] options:0 error:nil] contentType:@"application/json"];
            
            NSUInteger p5Length = [urlPathComp[5]length];
            if (  (p5Length>16)
                ||![K.SHRegex numberOfMatchesInString:urlPathComp[5] options:0 range:NSMakeRange(0,p5Length)])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{aet}datatype should be DICOM SH]",urlComponents.path];
            
            NSUInteger aetIndex=[[DRS.titlesaets objectForKey:urlPathComp[3]] indexOfObject:urlPathComp[5]];
            if (aetIndex==NSNotFound)
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{aet} not found]",urlComponents.path];
            
            if (urlPathCount>6) return [RSErrorResponse responseWithClientError:400 message:@"%@ [no handler]",urlComponents.path];
            
            //custodians/titles/{title}/aets/{aet}
            return [RSDataResponse responseWithData:
                    [NSJSONSerialization dataWithJSONObject:
                     [NSArray arrayWithObject:(DRS.oidsaeis[DRS.titles[urlPathComp[3]]])[aetIndex]]
                                                    options:0
                                                      error:nil
                     ]
                                        contentType:@"application/json"
                    ];
        }
        
        
        if ([urlPathComp[2]isEqualToString:@"oids"])
        {
            //custodians/oids
            if (urlPathCount==3) return [RSDataResponse responseWithData:DRS.oidsdata contentType:@"application/json"];
            
            NSUInteger p3Length = [urlPathComp[3] length];
            if (  (p3Length>64)
                ||![K.UIRegex numberOfMatchesInString:urlPathComp[3] options:0 range:NSMakeRange(0,p3Length)]
                )
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{OID} datatype should be DICOM UI]",urlComponents.path];
            
            if (!DRS.oids[urlPathComp[3]])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{OID} not found]",urlComponents.path];
            
            //custodian/oids/{OID}
            if (urlPathCount==4) return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:DRS.oids[urlPathComp[3]]] options:0 error:nil] contentType:@"application/json"];
            
            if (![urlPathComp[4]isEqualToString:@"aeis"])
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{OID} unique resource is 'aeis']",urlComponents.path];
            
            //custodian/oids/{OID}/aeis
            if ((urlPathCount==5)||((urlPathCount==6)&&![urlPathComp[5]length]))
                return [RSDataResponse responseWithData:[NSJSONSerialization dataWithJSONObject:[DRS.oidsaeis objectForKey:urlPathComp[3]] options:0 error:nil] contentType:@"application/json"];
            
            NSUInteger p5Length = [urlPathComp[5]length];
            if (  (p5Length>64)
                ||![K.UIRegex numberOfMatchesInString:urlPathComp[5] options:0 range:NSMakeRange(0,p5Length)]
                )
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{aei}datatype should be DICOM UI]",urlComponents.path];
            
            NSUInteger aeiIndex=[[DRS.oidsaeis objectForKey:urlPathComp[3]] indexOfObject:urlPathComp[5]];
            if (aeiIndex==NSNotFound)
                return [RSErrorResponse responseWithClientError:404 message:@"%@ [{aei} not found]",urlComponents.path];
            
            if (urlPathCount>6) return [RSErrorResponse responseWithClientError:400 message:@"%@ [no handler]",urlComponents.path];
            
            //custodian/oids/{OID}/aeis/{aei}
            return [RSDataResponse responseWithData:
                    [NSJSONSerialization dataWithJSONObject:
                     [NSArray arrayWithObject:(DRS.pacs[urlPathComp[5]])[@"dicomaet"]]
                                                    options:0
                                                      error:nil
                     ]
                                        contentType:@"application/json"
                    ];
        }
        return [RSErrorResponse responseWithClientError:404 message:@"%@ [no handler]",urlComponents.path];
        
    }(request));}];
}
@end
