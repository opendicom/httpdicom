//
//  main.m
//  mllp
//
//  Created by jacquesfauquex on 2019-03-08.
//  Copyright © 2019 jacques.fauquex@opendicom.com All rights reserved.
//

/*
 syntax: json / hl7utf8 message > mllpSend ip:port [charset] > stdout
 
 charset =
   1 NSASCIIStringEncoding
   4 NSUTF8StringEncoding
   5 NSISOLatin1StringEncoding (default, if value is omitted)
 
 stdin data stream may be:
   hl7
   json
 
 json Method object contents depends on Class value.
 {
   "Class" : "ORMO01_231",
   "Method" :
   {
    "singleSpsMSH_3" : "sendingRisName"
    "MSH_4"  : "sendingRisIP"
    "MSH_5"  : "receivingCustodianTitle"
    "MSH_6"  : "receivingPacsaet"
    "MSH_10" : "MessageControlId"
    "MSH_17" : "CountryCode"
    "MSH_18" : "sopStringEncoding"
    "MSH_19" : "PrincipalLanguage
    "PID_3"  : "pID"
    "PID_5"  : "pName"
    "PID_7"  : "pBirthDate"
    "PID_8"  : "pSex"
    "PV1_8"  : "isrPatientInsuranceShortName"
    "ORC_2"  : "isrPlacerNumber"
    "ORC_3"  : "isrFillerNumber"
    "ORC_5"  : "spsOrderStatus"
    "ORC_7"  : "spsDateTime"
    "ORC_7_" : "rpPriority"
    "OBR_4"  : "spsProtocolCode"
    "OBR_12" : "isrDangerCode"
    "OBR_13" : "isrRelevantClinicalInfo"
    "OBR_16" : "isrReferringPhysician"
    "OBR_18" : "isrAccessionNumber"
    "OBR_19" : "rpID"
    "OBR_20" : "spsID"
    "OBR_21" : "spsStationAETitle"
    "OBR_24" : "spsModality"
    "OBR_30" : "rpTransportationMode"
    "OBR_31" : "rpReasonForStudy"
    "OBR_32" : "isrNameOfPhysiciansReadingStudy"
    "OBR_34" : "spsTechnician"
    "OBR_44" : "rpUniversalStudyCode"
    "ZDS_1"  : "isrStudyInstanceUID"
   }
 }
 */


#import <Foundation/Foundation.h>
#import <mllp/mllpClient.h>
#import <mllp/ORMO01_231.h>

int main(int argc, const char * argv[]) {
   int returnValue=-1;
   @autoreleasepool {
      NSStringEncoding encoding=NSISOLatin1StringEncoding;
      NSArray *args=[[NSProcessInfo processInfo] arguments];
      
      
      switch (argc) {
         case 3:
            encoding=(NSStringEncoding)[args[2]intValue];
         case 2:
         {
            NSData *inputStream=[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
            if (inputStream && [inputStream length])
            {
               NSString *hl7String=nil;
 
               char firstByte=0;
               [inputStream getBytes:&firstByte length:1];
               if ( firstByte == 123)
               {
                  //{  -> json contents
                  NSError *error=nil;
                  NSDictionary *json=[NSJSONSerialization JSONObjectWithData:inputStream options:0 error:&error];
                  if (error) NSLog(@"%@",[error description]);
                  else
                  {
                     if (!json[@"Class"] || !json[@"Method"]) NSLog(@"json without \"Class\" name/value or \"Method\" object");
                     else
                     {
                        
                     }
                  }
               }
               else hl7String=[[NSString alloc]initWithData:inputStream encoding:NSUTF8StringEncoding];
#pragma mark hl7String
               if (hl7String && ![hl7String length])
               {
                  NSArray *ipport=[args[1] componentsSeparatedByString:@":"];
                  NSMutableString *payload=[NSMutableString string];
                  returnValue=(![mllpClient sendIP:ipport[0]
                                              port:ipport[1]
                                           message:hl7String
                                    stringEncoding:encoding
                                           payload:payload]
                               );
                  NSLog(@"%@",payload);
               }
               else
                  NSLog(@"unreadable or empty message in stdin");
            }
            else
               NSLog(@"hl7 message to be send expected in stdin");
         }
            break;
            
         default:
            NSLog(@"\r\n\r\nsyntax    : json / hl7utf8 message > mllpSend ip:port [encoding]\r\nreturns   : 0 when succes payload was received\r\nencodings : NSASCIIStringEncoding = 1\r\n            NSUTF8StringEncoding = 4\r\n            NSISOLatin1StringEncoding = 5 (default, if value is omitted)\r\n\r\n");
            break;
      }
   }
   return returnValue;
}
