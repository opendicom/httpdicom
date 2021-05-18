#import "NSURLSessionDataTask+DRS.h"
#import "NSArray+PCS.h"


@implementation NSURLSessionDataTask (DRS)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse *__autoreleasing *)responsePointer error:(NSError *__autoreleasing *)errorPointer
{
    dispatch_semaphore_t semaphore;
    __block NSData *result = nil;
    
    semaphore = dispatch_semaphore_create(0);
    
    void (^completionHandler)(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error);
    completionHandler = ^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error)
    {
        if ( errorPointer != NULL )
        {
            *errorPointer = error;
        }
        
        if ( responsePointer != NULL )
        {
            *responsePointer = response;
        }
        
        if ( error == nil )
        {
            result = data;
        }
        
        dispatch_semaphore_signal(semaphore);
    };
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler] resume];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return result;
}


+(NSArray*)existsInPacs:(NSDictionary*)pacs
                    pid:(NSString*)pid
                 issuer:(NSString*)issuer
       returnAttributes:(BOOL)returnAttributes
{
    if (!pid || ![pid length])
    {
       NSLog(@"[NSURLSessionDataTask+DRS] no pid");
        return false;//warning
    }
    
    
    NSURLRequestCachePolicy cachepolicy;
    if ([pacs[@"cachepolicy"]length]) cachepolicy=[pacs[@"cachepolicy"] integerValue];
    else cachepolicy=1;//NSURLRequestReloadIgnoringCacheData

    NSTimeInterval timeoutinterval;
    if ([pacs[@"timeoutinterval"]length]) timeoutinterval=[pacs[@"timeoutinterval"] doubleValue];
    else timeoutinterval=10;

    
    id request=nil;
    if (issuer) request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/rs/patients?PatientID=%@&IssuerOfPatientID=%@&includefield=00100021&includefield=00080090",pacs[@"dcm4cheelocaluri"],pid,issuer]]
                                                  cachePolicy:cachepolicy
                                              timeoutInterval:timeoutinterval];
    else  request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/rs/patients?PatientID=%@&includefield=00100021",pacs[@"dcm4cheelocaluri"],pid]]
                                            cachePolicy:cachepolicy
                                        timeoutInterval:timeoutinterval];

    
    NSHTTPURLResponse *response=nil;
    NSError *error=nil;
    if ((returnAttributes==false) && [pacs[@"headavailable"]boolValue])
    {
        [request setHTTPMethod:@"HEAD"];
        [self sendSynchronousRequest:request returningResponse:&response error:&error];
        //expected
        if (response.statusCode==200) return @[];//contents
        if (response.statusCode==204) return nil;//no content
        //unexpected
       NSLog(@"[NSURLSessionDataTask+DRS] HEADpid %ld",response.statusCode);//warning
        if (error) NSLog(@"[NSURLSessionDataTask+DRS] HEADpid error:\r\n%@",[error description]);
        return nil;
    }
    else
    {
        [request setHTTPMethod:@"GET"];
        NSData *responseData=[self sendSynchronousRequest:request returningResponse:&response error:&error];
        //expected
        if (response.statusCode==200) return [NSArray arrayWithJsonData:responseData];
        //unexpected
       NSLog(@"[NSURLSessionDataTask+DRS] GETpid %ld",response.statusCode);//warning
        if (error) NSLog(@"[NSURLSessionDataTask+DRS] GETpid error:\r\n%@",[error description]);
    }
    return nil;
}
@end
