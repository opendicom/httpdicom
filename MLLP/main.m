//
//  main.m
//  mllp
//
//  Created by jacquesfauquex on 2019-03-08.
//  Copyright © 2019 jacques.fauquex@opendicom.com All rights reserved.
//

/*
 syntax:
   stdin > mllpSend ip:port [charset] > stdout
 
 charset =
   1 (NSASCIIStringEncoding)
   4 (NSUTF8StringEncoding)
   5 (NSISOLatin1StringEncoding (default, if value is omitted))
 
 stdin data stream may be:
   hl7v2 message
   json object which will be transformed in hl7v2 message
 
 Exemple of json:
 {
   "Message" : "O01",
   "Version" : "2.3.1",
   "Params"  :
   {
    "sendingRisName" :                  "sendingRisName"
    "sendingRisIP"  :                   "sendingRisIP"
    ...
   }
 }
 
 stdout copies the payload received from the mllp server, or some error
 */


#import <Foundation/Foundation.h>
#import <MLLP/mllpSend.h>
#import <MLLP/NSString+A01.h>
#import <MLLP/NSString+A04.h>
#import <MLLP/NSString+O01.h>

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
if ([json[@"Message"] isEqualToString:@"A01"])
{
   NSDictionary * params=json[@"Params"];
   hl7String=[NSString
     admitInpatient:params[@"VersionID"]
     sendingRisName:params[@"sendingRisName"]
     sendingRisIP:params[@"sendingRisIP"]
     receivingCustodianTitle:params[@"receivingCustodianTitle"]
     receivingPacsaet:params[@"receivingPacsaet"]
     MessageControlId:params[@"MessageControlId"]
     CountryCode:params[@"CountryCode"]
     stringEncoding:(NSStringEncoding)[params[@"stringEncoding"]integerValue]
     PrincipalLanguage:params[@"PrincipalLanguage"]
     PatientIdentifierList:params[@"PatientIdentifierList"]
     PatientName:params[@"PatientName"]
     MotherMaidenName:params[@"MotherMaidenName"]
     PatientBirthDate:params[@"PatientBirthDate"]
     PatientAdministrativeSex:params[@"PatientAdministrativeSex"]
     ];
}
else if ([json[@"Message"] isEqualToString:@"A04"])
{
   NSDictionary * params=json[@"Params"];
   hl7String=[NSString
     registerPatient:params[@"VersionID"]
     sendingRisName:params[@"sendingRisName"]
     sendingRisIP:params[@"sendingRisIP"]
     receivingCustodianTitle:params[@"receivingCustodianTitle"]
     receivingPacsaet:params[@"receivingPacsaet"]
     MessageControlId:params[@"MessageControlId"]
     CountryCode:params[@"CountryCode"]
     stringEncoding:(NSStringEncoding)[params[@"stringEncoding"]integerValue]
     PrincipalLanguage:params[@"PrincipalLanguage"]
     PatientIdentifierList:params[@"PatientIdentifierList"]
     PatientName:params[@"PatientName"]
     MotherMaidenName:params[@"MotherMaidenName"]
     PatientBirthDate:params[@"PatientBirthDate"]
     PatientAdministrativeSex:params[@"PatientAdministrativeSex"]
     ];
}
else if ([json[@"Message"] isEqualToString:@"O01"])
{
   NSDictionary * params=json[@"Params"];
   hl7String=[NSString
       O01version:params[@"VersionID"]
       sendingApplication:params[@"sendingRisName"]
       sendingFacility:params[@"sendingRisIP"]
       receivingApplication:params[@"receivingCustodianTitle"]
       receivingFacility:params[@"receivingPacsaet"]
       messageControlId:params[@"MessageControlId"]
       countryCode:params[@"CountryCode"]
   stringEncoding:(NSStringEncoding)[params[@"stringEncoding"]integerValue]
       principalLanguage:params[@"PrincipalLanguage"]
       patIdentifierList:params[@"PatientIdentifierList"]
       patName:params[@"PatientName"]
       patMotherMaidenName:params[@"MotherMaidenName"]
       patBirthDate:params[@"PatientBirthDate"]
       patAdministrativeGender:params[@"PatientAdministrativeSex"]
       isrInsurance:params[@"isrPatientInsuranceShortName"]
       isrPlacerNumber:params[@"isrPlacerNumber"]
       isrFillerNumber:params[@"isrFillerNumber"]
       isrAN:params[@"isrAN"]
       isrReferring:params[@"isrReferring"]
       isrReading:params[@"isrReading"]
       isrStudyIUID:params[@"isrStudyIUID"]
       reqID:params[@"rpID"]
       reqProcedure:params[@"reqProcedure"]
       reqPriority:params[@"rpPriority"]
       spsDateTime:params[@"spsDateTime"]
       spsPerforming:params[@"spsPerforming"]
       sps1ID:params[@"sps1ID"]
       sps2ID:params[@"sps2ID"]
       sps3ID:params[@"sps3ID"]
       sps4ID:params[@"sps4ID"]
       sps1Modality:params[@"sps1Modality"]
       sps2Modality:params[@"sps2Modality"]
       sps3Modality:params[@"sps3Modality"]
       sps4Modality:params[@"sps4Modality"]
       sps1AET:params[@"sps1AET"]
       sps2AET:params[@"sps2AET"]
       sps3AET:params[@"sps3AET"]
       sps4AET:params[@"sps4AET"]
       sps1Protocol:params[@"sps1Protocol"]
       sps2Protocol:params[@"sps2Protocol"]
       sps3Protocol:params[@"sps3Protocol"]
       sps4Protocol:params[@"sps4Protocol"]
       sps1OrderStatus:params[@"sps1OrderStatus"]
       sps2OrderStatus:params[@"sps2OrderStatus"]
       sps3OrderStatus:params[@"sps3OrderStatus"]
       sps4OrderStatus:params[@"sps4OrderStatus"]
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
                  returnValue=(![mllpSend sendIP:ipport[0]
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
            NSLog(@"\r\n\r\nsyntax    : cat/echo json/hl7utf8\r\n                 > mllpSend ip:port [encoding (default:5)]\r\n                      > hl7payload\r\n\r\nreturns   : 0 when succes payload was received\r\n\r\nencodings : NSASCIIStringEncoding = 1\r\n            NSUTF8StringEncoding = 4\r\n            NSISOLatin1StringEncoding = 5\r\n\r\njson      : (ver message header files of mllp library)\r\n            O01\r\n            A01\r\n            A04");
            break;
      }
   }
   return returnValue;
}
