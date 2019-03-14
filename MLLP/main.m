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
   "Message" : "O01",
   "Version" : "231",
   "Params"  :
   {
    "sendingRisName" :                  "sendingRisName"
    "sendingRisIP"  :                   "sendingRisIP"
    "receivingCustodianTitle"  :        "receivingCustodianTitle"
    "receivingPacsaet"  :               "receivingPacsaet"
    "MessageControlId" :                "MessageControlId"
    "CountryCode" :                     "CountryCode"
    "sopStringEncoding" :               "sopStringEncoding"
    "sopStringEncoding" :               "PrincipalLanguage"
    "pID"  :                            "pID"
    "pName"  :                          "pName"
    "pBirthDate"  :                     "pBirthDate"
    "pSex"  :                           "pSex"
    "isrPatientInsuranceShortName"  :   "isrPatientInsuranceShortName"
    "isrPlacerNumber"  :                "isrPlacerNumber"
    "isrFillerNumber"  :                "isrFillerNumber"
    "spsOrderStatus"  :                 "spsOrderStatus"
    "spsDateTime"  :                    "spsDateTime"
    "rpPriority" :                      "rpPriority"
    "spsProtocolCode"  :                "spsProtocolCode"
    ""isrDangerCode" :                  "isrDangerCode"
    "isrRelevantClinicalInfo" :         "isrRelevantClinicalInfo"
    "isrReferringPhysician" :           "isrReferringPhysician"
    "isrAccessionNumber" :              "isrAccessionNumber"
    "rpID" :                            "rpID"
    "spsID" :                           "spsID"
    "spsStationAETitle" :               "spsStationAETitle"
    "spsModality" :                     "spsModality"
    "rpTransportationMode" :            "rpTransportationMode"
    "rpReasonForStudy" :                "rpReasonForStudy"
    "isrNameOfPhysiciansReadingStudy" : "isrNameOfPhysiciansReadingStudy"
    "spsTechnician" :                   "spsTechnician"
    "rpUniversalStudyCode" :            "rpUniversalStudyCode"
    "isrStudyInstanceUID"  :            "isrStudyInstanceUID"
   }
 }
 */


#import <Foundation/Foundation.h>
#import <mllp/mllpClient.h>
#import <mllp/O01.h>

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
               if ( firstByte == 123) //123={  -> json contents
               {
                  
                  NSError *error=nil;
                  NSDictionary *json=[NSJSONSerialization JSONObjectWithData:inputStream options:0 error:&error];
                  if (error) NSLog(@"%@",[error description]);
                  else
                  {
                     if (!json[@"Class"] || !json[@"Params"] || !json[@"Version"]) NSLog(@"json without \"Message\" name/value or \"Version\" or \"Params\" object");
                     else
                     {
                        if ([json[@"Message"] isEqualToString:@"O01"])
                        {
                           NSDictionary * params=json[@"Params"];
                           hl7String=[O01
                                      singleSpsMSH_3:params[@"sendingRisName"]
                                      MSH_4:params[@"sendingRisIP"]
                                      MSH_5:params[@"receivingCustodianTitle"]
                                      MSH_6:params[@"receivingPacsaet"]
                                      MSH_10:params[@"MessageControlId"]
                                      MSH_17:params[@"CountryCode"]
                                      MSH_18:(NSStringEncoding)[params[@"sopStringEncoding"]integerValue]
                                      MSH_19:params[@"PrincipalLanguage"]
                                      PID_3:params[@"pID"]
                                      PID_5:params[@"pName"]
                                      PID_7:params[@"pBirthDate"]
                                      PID_8:params[@"pSex"]
                                      PV1_8:params[@"isrPatientInsuranceShortName"]
                                      ORC_2:params[@"isrPlacerNumber"]
                                      ORC_3:params[@"isrFillerNumber"]
                                      ORC_5:params[@"spsOrderStatus"]
                                      ORC_7:params[@"spsDateTime"]
                                      ORC_7_:params[@"rpPriority"]
                                      OBR_4:params[@"spsProtocolCode"]
                                      OBR_12:params[@"isrDangerCode"]
                                      OBR_13:params[@"isrRelevantClinicalInfo"]
                                      OBR_16:params[@"isrReferringPhysician"]
                                      OBR_18:params[@"isrAccessionNumber"]
                                      OBR_19:params[@"rpID"]
                                      OBR_20:params[@"spsID"]
                                      OBR_21:params[@"spsStationAETitle"]
                                      OBR_24:params[@"spsModality"]
                                      OBR_30:params[@"rpTransportationMode"]
                                      OBR_31:params[@"rpReasonForStudy"]
                                      OBR_32:params[@"isrNameOfPhysiciansReadingStudy"]
                                      OBR_34:params[@"spsTechnician"]
                                      OBR_44:params[@"rpUniversalStudyCode"]
                                      ZDS_1:params[@"isrStudyInstanceUID"]
                                      ];
                        }
                        else NSLog(@"Class %@ not implemented",json[@"Class"]);
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
            NSLog(@"\r\n\r\nsyntax    : cat/echo json/hl7utf8\r\n                 > mllpSend ip:port [encoding (default:5)]\r\n                      > hl7payload\r\n\r\nreturns   : 0 when succes payload was received\r\n\r\nencodings : NSASCIIStringEncoding = 1\r\n            NSUTF8StringEncoding = 4\r\n            NSISOLatin1StringEncoding = 5\r\n\r\njson      : (description in corresponding header files of mllp library)\r\n            O01_231\r\n            ADT");
            break;
      }
   }
   return returnValue;
}
