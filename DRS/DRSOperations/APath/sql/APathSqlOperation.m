#import "APathSqlOperation.h"
#import "NSURLSessionDataTask+PCS.h"
#import "ODLog.h"
#import "K.h"

@interface APathSqlOperation ()
@property (nonatomic, copy) NSString* URLstring;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* RepositoryUniqueID;
@property (nonatomic, copy) NSString* timezone;
@property (nonatomic) NSUInteger indexfield;
@property (nonatomic) unsigned short indexvr;
@property (nonatomic) NSUInteger offset;
@property (nonatomic) NSUInteger limit;
@property (nonatomic) NSUInteger status;
@end

@implementation APathSqlOperation
@synthesize URLstring;
@synthesize RepositoryUniqueID;
@synthesize timezone;

#pragma mark -

- (instancetype)initWithURLstring:(NSString*)URLstring
                      cachePolicy:(NSURLRequestCachePolicy)cachePolicy
                  timeoutInterval:(NSTimeInterval)timeoutInterval
                            title:(NSString*)title
               RepositoryUniqueID:(NSString*)RepositoryUniqueID
                         timezone:(NSString*)timezone
                            level:(NSUInteger)level
                       indexfield:(NSUInteger)indexfield
                           offset:(NSUInteger)offset
                            limit:(NSUInteger)limit
{
    if (!URLstring || !title || !RepositoryUniqueID)
    {
        LOG_ERROR(@"DRSQidoJsonOperation init incomplete");
        return nil;
    }
    
    //aditional quick init validations
    //...

    self = [super init];
    if (self)
    {
        self.URLstring = URLstring;
        self.title = title;
        self.name = [NSString stringWithFormat:@"DRSQidoJsonOperation_%@",title];
        self.RepositoryUniqueID = RepositoryUniqueID;
        
        if (timezone) self.timezone = timezone;
        else self.timezone = K.defaultTimezone;
        
        self.indexfield = indexfield;
        self.indexvr = [K.vr[indexfield] unsignedShortValue];
        self.offset = offset;
        self.limit = limit;
        self.status = 0;

        indexString=[NSMutableArray array];
        items=[NSMutableArray array];
    }
    return self;
}


- (void)start
{
    if (!self.cancelled)
    {
        [super start];
        
        /*
        - (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
    completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
         */
         
        NSURLResponse *response=nil;
        NSError *error=nil;
        
        NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLstring]
                                      cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                         timeoutInterval:300];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];//application/dicom+json not accepted !!!!!
        //Cache-control: no-cache
        
        NSData *jsonArrayData=[NSURLSessionDataTask sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error)
        {
            LOG_WARNING(@"%@\r\n%@", self.name, [error description]);
            [self finish];
        }
        else
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            LOG_DEBUG(@"%@",[httpResponse description]);
            self.status = httpResponse.statusCode;
            if (self.status!=200)
            {
                switch (self.status) {
                    case 400:
                        LOG_WARNING(@"%@ 400 Bad Request\r\nThe QIDO-RS Provider was unable to perform the query because the Service Provider cannot understand the query component", self.name);
                        break;
                    case 401:
                        LOG_WARNING(@"%@ 401 Unauthorized\r\nThe QIDO-RS Provider refused to perform the query because the client is not authenticated", self.name);
                        break;
                    case 403:
                        LOG_WARNING(@"%@ 403 Forbidden\r\nThe QIDO-RS Provider understood the request, but is refusing to perform the query (e.g., an authenticated user with insufficient privileges)", self.name);
                        break;
                    case 413:
                        LOG_WARNING(@"%@ 413 Request entity too large\r\nThe query was too broad and a narrower query or paging should be requested. The use of this status code should be documented in the conformance statement", self.name);
                        break;
                    case 503:
                        LOG_WARNING(@"%@ 503 Busy\r\nService is unavailable", self.name);
                        break;

                    default:
                        LOG_WARNING(@"%@ unknown error\r\n%@", self.name,[httpResponse description]);
                        break;
                }
            }
            else //status=200
            {
                NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonArrayData options:NSJSONReadingMutableContainers error:nil];
                
                if (error) {
                    LOG_WARNING(@"%@\r\n%@", self.name, [error description]);
                    [self finish];
                }
/*todo
                else
                {
                    
                    if ([jsonArray count])
                    {
                        //add results
                        
                        switch (self.indexvr) {
                            case 0x4353://CS
                                <#statements#>
                                break;
                                
                            case 0x4441://DA
                                <#statements#>
                                break;
                                
                            case 0x4953://IS
                                <#statements#>
                                break;
                                
                            case 0x4C4F://LO
                                <#statements#>
                                break;
                                
                            case 0x504E://PN
                                <#statements#>
                                break;
                                
                            case 0x5348://SH
                                <#statements#>
                                break;
                                
                            case 0x544D://TM
                                <#statements#>
                                break;
                                
                            case 0x5549://UI
                                <#statements#>
                                break;
                                
                            case 0x5554://UT
                                <#statements#>
                                break;
                                
                            default:
                                break;
                        }

                    }
                }
*/
                
                //output format
                /*
                 [
                 {
                 "0020000D":
                 {
                 "vr": "UI",
                 "Value":
                 [
                 "1.2.392.200036.9116.2.2.2.1762893313.1029997326.945873"
                 ]
                 }
                 }
                 ]

                 to be transformed into
                 
                 [
                 {
                 "0020000D":
                 [
                 "1.2.392.200036.9116.2.2.2.1762893313.1029997326.945873"
                 ]
                 }
0                 ]

                 */

            }
         }
    }
}

//RetrieveURL 00081190 UR (wadors url)
//SpecificCharacterSet 00080005 CS
//TimezoneOffsetFromUTC 00080201 SH
//InstanceAvailability 00080056 CS (ONLINE, NEARLINE, OFFLINE, UNAVAILABLE)
//datatables -> datatablesPatient



//The operationQueue manager gets next objects and at some point sends a cancel
//This allows for concurrent fecth operations, asynchronous data sources, and chuncked responses
//For now, though, the data source is synchronous
-(NSDictionary*)results
{
    if (self.cancelled || !items)
    {
        [self finish];
        return nil;
    }
    NSUInteger count=[items count];
    NSArray *array=[NSArray arrayWithArray:items];
    [items removeObjectsInRange:NSMakeRange(0,count)];
    return array;
}

@end
