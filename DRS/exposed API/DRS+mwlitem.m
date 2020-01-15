#import "DRS+mwlitem.h"
#import "K.h"

#import "NSData+PCS.h"
#import "NSString+PCS.h"
#import "NSURLSessionDataTask+DRS.h"
#import "NSUUID+DICM.h"
#import "DICMTypes.h"
#import "NSMutableString+DSCD.h"

#import <MLLP/NSString+O01.h>
#import <MLLP/mllpSend.h>

#import "ResponsePatients.h"
#import "ResponseMwlitems.h"
#import "ResponseStow.h"
#import "ResponseQido.h"

@implementation DRS (mwlitem)

NSString* correctedModality(NSString* spaceNormalized)
{
   //correct RM to MR and TC to CT
   if      ([spaceNormalized isEqualToString:@"RM"]) return @"MR";
   else if ([spaceNormalized isEqualToString:@"TC"]) return @"CT";
   else return spaceNormalized;
}

-(void)addMwlitemHandler
{
[self addHandler:@"POST" path:@"/mwlitem" processBlock:
 ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
{
#pragma mark params
    NSMutableArray *names=[NSMutableArray array];
    NSMutableArray *values=[NSMutableArray array];
    NSMutableArray *types=[NSMutableArray array];
    NSString *RequestParamsSHA512String=parseRequestParams(request, names, values);
    if ([RequestParamsSHA512String hasPrefix:@"ERROR"]) return [RSErrorResponse responseWithClientError:404 message:@"%@",RequestParamsSHA512String];
    
    for (NSUInteger idx=0;idx<[names count];idx++)
    {
        if ([values[idx]length]<256)
        {
            LOG_VERBOSE(@"mwlitem PARAM \"%@\" = \"%@\"",names[idx],values[idx]);
        }
        else
        {
            LOG_VERBOSE(@"mwlitem PARAM \"%@\" = ...",names[idx]);
            LOG_DEBUG(@"%@",values[idx]);
        }
    }
    
#pragma mark pacs
    NSString *pacsUID1=nil;
    NSDictionary *pacs=nil;
    NSUInteger pacsIndex=[names indexOfObject:@"pacs"];
    if (pacsIndex!=NSNotFound)
    {
        pacsUID1=values[pacsIndex];
        if (![DICMTypes.UIRegex numberOfMatchesInString:pacsUID1 options:0 range:NSMakeRange(0,[pacsUID1 length])])
            return [RSErrorResponse responseWithClientError:404 message:@"mwlitem pacsUID '%@' should be an OID",pacsUID1];
        pacs=DRS.pacs[pacsUID1];
        if (!pacs) return [RSErrorResponse responseWithClientError:404 message:@"mwlitem PACS '%@' not known",pacsUID1];
        
        LOG_VERBOSE(@"mwlitem PACS %@",pacs[@"pacsaet"]);
    }
    else
    {
        pacsUID1=DRS.defaultpacsoid;
        pacs=DRS.pacs[DRS.defaultpacsoid];
        LOG_VERBOSE(@"mwlitem PACS (default) %@",pacs[@"pacsaet"]);
    }

   //dcm4cheelocaluri available?
   NSString *dcm4cheelocaluri=pacs[@"dcm4cheelocaluri"];
   if (
         !pacs[@"dcm4cheelocaluri"]
       ||![pacs[@"dcm4cheelocaluri"] length]
       ) return [RSErrorResponse responseWithClientError:404 message:@"[mwlitem] pacs '%@' is not a dcm4chee-arc",pacsUID1];


#pragma mark isrAN
   NSString *isrAN1=nil;
   NSString *isrANIssuer1=nil;
   NSString *isrANType1=nil;
   NSString *isrFillerNumber=nil;
   NSUInteger isrAN1Index=[names indexOfObject:@"isrAN"];
   if (isrAN1Index==NSNotFound)isrAN1Index=[names indexOfObject:@"AccessionNumber"];
   if (isrAN1Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"mwlitem isrAN required"];
   isrAN1=values[isrAN1Index];
   
   if (![DICMTypes.SHRegex numberOfMatchesInString:isrAN1 options:0 range:NSMakeRange(0,[isrAN1 length])]) return [RSErrorResponse responseWithClientError:404 message:@"mwlitem isrAN should be > 1 and < 16 chars in length, without space, nor return, nor tab"];
   
   //Already exists in the PACS?
   NSArray *mwlitemArray=[ResponseMwlitems getFromPacs:pacs accessionNumber:isrAN1];
   if (!mwlitemArray) return [RSErrorResponse responseWithClientError:404 message:@"can not check pre existence of mwlitem isrAN '%@' in pacs '%@'",isrAN1,pacs[@"pacsaet"]];
   if ([mwlitemArray count])
   {
      LOG_ERROR(@"mwlitem AN '%@' already exists in pacs '%@'\r\n%@",isrAN1,pacs[@"pacsaet"],[mwlitemArray description]);
         return [RSErrorResponse responseWithClientError:404 message:@"mwlitem isrAN '%@' already exists in pacs '%@'",isrAN1,pacs[@"pacsaet"]];
   }
   
   NSUInteger isrANIssuer1Index=[names indexOfObject:@"isrANIssuer"];
   if (isrANIssuer1Index!=NSNotFound)
   {
      isrANIssuer1=values[isrANIssuer1Index];
      NSUInteger isrANType1Index=[names indexOfObject:@"isrANType"];
      if (isrANType1Index!=NSNotFound)
      {
         //universal
         isrANType1=values[isrANType1Index];
         isrFillerNumber=[NSString stringWithFormat:@"%@^^%@^%@",
               isrAN1,
               isrANIssuer1,
               isrANType1
               ];
      }
      else
      {
         //local
         isrANType1=@"";
         isrFillerNumber=[NSString stringWithFormat:@"%@^%@",
               isrAN1,
               isrANIssuer1
               ];
      }
   }
   else
   {
      isrANIssuer1Index=[names indexOfObject:@"issuerUniversal"];
      if (isrANIssuer1Index!=NSNotFound)
      {
         //universal
         isrANIssuer1=values[isrANIssuer1Index];
         NSUInteger isrANType1Index=[names indexOfObject:@"isrANType"];
         if (isrANType1Index!=NSNotFound) isrANType1=values[isrANType1Index];
         else isrANType1=@"ISO";
         isrFillerNumber=[NSString stringWithFormat:@"%@^^%@^%@",
               isrAN1,
               isrANIssuer1,
               isrANType1
               ];
      }
      else
      {
         //local
         isrANIssuer1Index=[names indexOfObject:@"issuerLocal"];
         if (isrANIssuer1Index!=NSNotFound)
         {
            isrANIssuer1=values[isrANIssuer1Index];
            isrANType1=@"";
         }
         else
         {
            isrANIssuer1=pacsUID1;
            isrANType1=@"ISO";
         }
         isrFillerNumber=[NSString stringWithFormat:@"%@^%@",
               isrAN1,
               isrANIssuer1
               ];
      }
   }
      
   
   
    LOG_VERBOSE(@"mwlitem NEW# %@ %@ %@",isrAN1,isrANType1,isrANIssuer1);


#pragma mark sps1
   //when spsxLocation is specified in the message, we check posible incongruences of its caracteristics with the ones registered in the file pacs.
   //This is also used to determine modality / aet when these are not supplied in the message
   NSString *sps1Location1=nil;
   NSDictionary *sps1Location1Dict=nil;
   NSArray *sps1Location1Modalities=nil;
   NSArray *sps1Location1AETs=nil;
   NSString *sps1Modality1=nil;
   NSArray *sps1Protocol1Array=nil;
   NSString *sps1Protocol1OBR4=nil;
   NSString *sps1AET1=nil;

   NSUInteger sps1Location1Index=[names indexOfObject:@"sps1Location"];
   if (sps1Location1Index!=NSNotFound)
      sps1Location1Index=[names indexOfObject:@"sps1Service"];
   if (sps1Location1Index!=NSNotFound)
      sps1Location1Index=[names indexOfObject:@"servicio"];
   if (sps1Location1Index!=NSNotFound)
      sps1Location1Index=[names indexOfObject:@"sala"];
   if (sps1Location1Index!=NSNotFound)
   {
      sps1Location1=[values[sps1Location1Index]spaceNormalize];
      //check if sps1Location is known in the pacs file and get corresponding modalities and AETs
      sps1Location1Dict=(pacs[@"services"])[sps1Location1];
      if (!sps1Location1Dict)
      {
         sps1Location1Modalities=@[];
         sps1Location1AETs=@[];
      }
      else
      {
         if ([sps1Location1Dict[@"modalities"]count])
            sps1Location1Modalities=[sps1Location1Dict[@"modalities"] componentsSlashOrBackSlashSeparated];
         else sps1Location1Modalities=@[];
       
         if ([sps1Location1Dict[@"aetitles"]count])
            sps1Location1Modalities=[sps1Location1Dict[@"aetitles"] componentsSlashOrBackSlashSeparated];
         else sps1Location1Modalities=@[];
      }
   }
   
   //sps1Modality in the message (may be also written modalidad or modality)
   NSUInteger sps1Modality1Index=[names indexOfObject:@"sps1Modality"];
   if (sps1Modality1Index==NSNotFound) sps1Modality1Index=[names indexOfObject:@"modalidad"];
       /*
       sps1Modality1Index=[names indexOfObjectPassingTest:^(id s, NSUInteger idx, BOOL *stop){
           return [s isEqualToString:@"modalidad"];
       }];
        */
   if (sps1Modality1Index==NSNotFound)
      sps1Modality1Index=[names indexOfObject:@"modality"];
   if (sps1Modality1Index!=NSNotFound)
   sps1Modality1=correctedModality([values[sps1Modality1Index]spaceNormalize]);
   
   if (!sps1Modality1 || ![sps1Modality1 length])
   {
       //the message doesn´t provide modality. Find default in LocationModalities
        if ([sps1Location1Modalities count]!=1)
        {
           //there was no or many modality in location, so we don´t know which is the correct one
           return [RSErrorResponse responseWithClientError:404 message:@"sps1Modality required"];
        }
        sps1Modality1=sps1Location1Modalities[0];
    }
    else if ([sps1Location1Modalities count])
    {
       //the message specifies modality. And LocationModalities has information about modalities, too. Assert if they are compatible.
        if ([sps1Location1Modalities indexOfObject:sps1Modality1]==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"sps1Modality %@ not available in sps1Location  %@",sps1Modality1,sps1Location1];
    }
    else if ([K.modalities indexOfObject:sps1Modality1]==NSNotFound)
    {
       //sps1Modality is not a valid modality
       return [RSErrorResponse responseWithClientError:404 message:@"sps1Modality '%@', should be one of %@",sps1Modality1, [K.modalities description]];
    }
    //sps1Modality OK
   
   NSUInteger sps1Protocol1Index=[names indexOfObject:@"sps1Protocol"];
   if (sps1Protocol1Index!=NSNotFound) sps1Protocol1Array=[values[sps1Protocol1Index] protocolCodeArray];
   //protocol: OBR 4 Procedure Code (CE) ^^^code^meaning^scheme
   if ([sps1Protocol1Array count]==3)
   {
      sps1Protocol1OBR4=[NSString stringWithFormat:@"^^^%@^%@^%@",
                         sps1Protocol1Array[0],
                         sps1Protocol1Array[1],
                         sps1Protocol1Array[2]
                         ];
   }
   else sps1Protocol1OBR4=sps1Protocol1Array[0];

   NSUInteger sps1AET1Index=[names indexOfObject:@"sps1AET"];
   if (sps1AET1Index!=NSNotFound) sps1AET1=values[sps1AET1Index];

#pragma mark sps2
   NSString *sps2Location1=nil;
   NSDictionary *sps2Location1Dict=nil;
   NSArray *sps2Location1Modalities=nil;
   NSArray *sps2Location1AETs=nil;
   NSString *sps2Modality1=nil;
   NSArray *sps2Protocol1Array=nil;
   NSString *sps2Protocol1OBR4=nil;
   NSString *sps2AET1=nil;

   NSUInteger sps2Location1Index=[names indexOfObject:@"sps2Location"];
   NSUInteger sps2Modality1Index=[names indexOfObject:@"sps2Modality"];
   if ((sps2Location1Index!=NSNotFound) || (sps2Modality1Index!=NSNotFound))
   {
      if (sps2Location1Index!=NSNotFound)
      {
         sps2Location1=[values[sps2Location1Index]spaceNormalize];
         //check if sps2Location is known in the pacs file and get corresponding modalities and AETs
         sps2Location1Dict=(pacs[@"services"])[sps2Location1];
         if (!sps2Location1Dict)
         {
            sps2Location1Modalities=@[];
            sps2Location1AETs=@[];
         }
         else
         {
            if ([sps2Location1Dict[@"modalities"]count])
               sps2Location1Modalities=[sps2Location1Dict[@"modalities"] componentsSlashOrBackSlashSeparated];
            else sps2Location1Modalities=@[];
            
            if ([sps2Location1Dict[@"aetitles"]count])
               sps2Location1Modalities=[sps2Location1Dict[@"aetitles"] componentsSlashOrBackSlashSeparated];
            else sps2Location1Modalities=@[];
         }
      }
      
      //sps2Modality in the message (may be also written modalidad or modality)
      if (sps2Modality1Index!=NSNotFound) sps2Modality1=correctedModality([values[sps2Modality1Index]spaceNormalize]);
      
      if (!sps2Modality1 || ![sps2Modality1 length])
      {
         //the message doesn´t provide modality. Find default in LocationModalities
         if ([sps2Location1Modalities count]!=1)
         {
            //there was no or many modality in location, so we don´t know which is the correct one
            return [RSErrorResponse responseWithClientError:404 message:@"sps2Modality required"];
         }
         sps2Modality1=sps2Location1Modalities[0];
      }
      else if ([sps2Location1Modalities count])
      {
         //the message specifies modality. And LocationModalities has information about modalities, too. Assert if they are compatible.
         if ([sps2Location1Modalities indexOfObject:sps2Modality1]==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"sps2Modality %@ not available in sps2Location  %@",sps2Modality1,sps2Location1];
      }
      else if ([K.modalities indexOfObject:sps2Modality1]==NSNotFound)
      {
         //sps2Modality is not a valid modality
         return [RSErrorResponse responseWithClientError:404 message:@"sps2Modality '%@', should be one of %@",sps2Modality1, [K.modalities description]];
      }
      //sps2Modality OK
      
      NSUInteger sps2Protocol1Index=[names indexOfObject:@"sps2Protocol"];
      if (sps2Protocol1Index!=NSNotFound) sps2Protocol1Array=[values[sps2Protocol1Index] protocolCodeArray];
      //protocol: OBR 4 Procedure Code (CE) ^^^code^meaning^scheme
      if ([sps2Protocol1Array count]==3)
      {
         sps2Protocol1OBR4=[NSString stringWithFormat:@"^^^%@^%@^%@",
                            sps2Protocol1Array[0],
                            sps2Protocol1Array[1],
                            sps2Protocol1Array[2]
                            ];
      }
      else sps2Protocol1OBR4=sps2Protocol1Array[0];

      NSUInteger sps2AET1Index=[names indexOfObject:@"sps2AET"];
      if (sps2AET1Index!=NSNotFound) sps2AET1=values[sps2AET1Index];
   }

   
#pragma mark sps3
   NSString *sps3Location1=nil;
   NSDictionary *sps3Location1Dict=nil;
   NSArray *sps3Location1Modalities=nil;
   NSArray *sps3Location1AETs=nil;
   NSString *sps3Modality1=nil;
   NSArray *sps3Protocol1Array=nil;
   NSString *sps3Protocol1OBR4=nil;
   NSString *sps3AET1=nil;

   NSUInteger sps3Location1Index=[names indexOfObject:@"sps3Location"];
   NSUInteger sps3Modality1Index=[names indexOfObject:@"sps3Modality"];
   if ((sps3Location1Index!=NSNotFound) || (sps3Modality1Index!=NSNotFound))
   {
      if (sps3Location1Index!=NSNotFound)
      {
         sps3Location1=[values[sps3Location1Index]spaceNormalize];
         //check if sps3Location is known in the pacs file and get corresponding modalities and AETs
         sps3Location1Dict=(pacs[@"services"])[sps3Location1];
         if (!sps3Location1Dict)
         {
            sps3Location1Modalities=@[];
            sps3Location1AETs=@[];
         }
         else
         {
            if ([sps3Location1Dict[@"modalities"]count])
               sps3Location1Modalities=[sps3Location1Dict[@"modalities"] componentsSlashOrBackSlashSeparated];
            else sps3Location1Modalities=@[];
            
            if ([sps3Location1Dict[@"aetitles"]count])
               sps3Location1Modalities=[sps3Location1Dict[@"aetitles"] componentsSlashOrBackSlashSeparated];
            else sps3Location1Modalities=@[];
         }
      }
      
      //sps3Modality in the message (may be also written modalidad or modality)
      if (sps3Modality1Index!=NSNotFound) sps3Modality1=correctedModality([values[sps3Modality1Index]spaceNormalize]);
      
      if (!sps3Modality1 || ![sps3Modality1 length])
      {
         //the message doesn´t provide modality. Find default in LocationModalities
         if ([sps3Location1Modalities count]!=1)
         {
            //there was no or many modality in location, so we don´t know which is the correct one
            return [RSErrorResponse responseWithClientError:404 message:@"sps3Modality required"];
         }
         sps3Modality1=sps3Location1Modalities[0];
      }
      else if ([sps3Location1Modalities count])
      {
         //the message specifies modality. And LocationModalities has information about modalities, too. Assert if they are compatible.
         if ([sps3Location1Modalities indexOfObject:sps3Modality1]==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"sps3Modality %@ not available in sps3Location  %@",sps3Modality1,sps3Location1];
      }
      else if ([K.modalities indexOfObject:sps3Modality1]==NSNotFound)
      {
         //sps3Modality is not a valid modality
         return [RSErrorResponse responseWithClientError:404 message:@"sps3Modality '%@', should be one of %@",sps3Modality1, [K.modalities description]];
      }
      //sps3Modality OK
      
      NSUInteger sps3Protocol1Index=[names indexOfObject:@"sps3Protocol"];
      if (sps3Protocol1Index!=NSNotFound) sps3Protocol1Array=[values[sps3Protocol1Index] protocolCodeArray];
      //protocol: OBR 4 Procedure Code (CE) ^^^code^meaning^scheme
      if ([sps3Protocol1Array count]==3)
      {
         sps3Protocol1OBR4=[NSString stringWithFormat:@"^^^%@^%@^%@",
                            sps3Protocol1Array[0],
                            sps3Protocol1Array[1],
                            sps3Protocol1Array[2]
                            ];
      }
      else sps3Protocol1OBR4=sps3Protocol1Array[0];

      NSUInteger sps3AET1Index=[names indexOfObject:@"sps3AET"];
      if (sps3AET1Index!=NSNotFound) sps3AET1=values[sps3AET1Index];
   }

   
#pragma mark sps4
   NSString *sps4Location1=nil;
   NSDictionary *sps4Location1Dict=nil;
   NSArray *sps4Location1Modalities=nil;
   NSArray *sps4Location1AETs=nil;
   NSString *sps4Modality1=nil;
   NSArray *sps4Protocol1Array=nil;
   NSString *sps4Protocol1OBR4=nil;
   NSString *sps4AET1=nil;

   NSUInteger sps4Location1Index=[names indexOfObject:@"sps4Location"];
   NSUInteger sps4Modality1Index=[names indexOfObject:@"sps4Modality"];
   if ((sps4Location1Index!=NSNotFound) || (sps4Modality1Index!=NSNotFound))
   {
      if (sps4Location1Index!=NSNotFound)
      {
         sps4Location1=[values[sps4Location1Index]spaceNormalize];
         //check if sps4Location is known in the pacs file and get corresponding modalities and AETs
         sps4Location1Dict=(pacs[@"services"])[sps4Location1];
         if (!sps4Location1Dict)
         {
            sps4Location1Modalities=@[];
            sps4Location1AETs=@[];
         }
         else
         {
            if ([sps4Location1Dict[@"modalities"]count])
               sps4Location1Modalities=[sps4Location1Dict[@"modalities"] componentsSlashOrBackSlashSeparated];
            else sps4Location1Modalities=@[];
            
            if ([sps4Location1Dict[@"aetitles"]count])
               sps4Location1Modalities=[sps4Location1Dict[@"aetitles"] componentsSlashOrBackSlashSeparated];
            else sps4Location1Modalities=@[];
         }
      }
      
      //sps4Modality in the message (may be also written modalidad or modality)
      if (sps4Modality1Index!=NSNotFound) sps4Modality1=correctedModality([values[sps4Modality1Index]spaceNormalize]);
      
      if (!sps4Modality1 || ![sps4Modality1 length])
      {
         //the message doesn´t provide modality. Find default in LocationModalities
         if ([sps4Location1Modalities count]!=1)
         {
            //there was no or many modality in location, so we don´t know which is the correct one
            return [RSErrorResponse responseWithClientError:404 message:@"sps4Modality required"];
         }
         sps4Modality1=sps4Location1Modalities[0];
      }
      else if ([sps4Location1Modalities count])
      {
         //the message specifies modality. And LocationModalities has information about modalities, too. Assert if they are compatible.
         if ([sps4Location1Modalities indexOfObject:sps4Modality1]==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"sps4Modality %@ not available in sps4Location  %@",sps4Modality1,sps4Location1];
      }
      else if ([K.modalities indexOfObject:sps4Modality1]==NSNotFound)
      {
         //sps4Modality is not a valid modality
         return [RSErrorResponse responseWithClientError:404 message:@"sps4Modality '%@', should be one of %@",sps4Modality1, [K.modalities description]];
      }
      //sps4Modality OK
      
      NSUInteger sps4Protocol1Index=[names indexOfObject:@"sps4Protocol"];
      if (sps4Protocol1Index!=NSNotFound) sps4Protocol1Array=[values[sps4Protocol1Index] protocolCodeArray];
      //protocol: OBR 4 Procedure Code (CE) ^^^code^meaning^scheme
      if ([sps4Protocol1Array count]==3)
      {
         sps4Protocol1OBR4=[NSString stringWithFormat:@"^^^%@^%@^%@",
                            sps4Protocol1Array[0],
                            sps4Protocol1Array[1],
                            sps4Protocol1Array[2]
                            ];
      }
      else sps4Protocol1OBR4=sps4Protocol1Array[0];

      NSUInteger sps4AET1Index=[names indexOfObject:@"sps4AET"];
      if (sps4AET1Index!=NSNotFound) sps4AET1=values[sps4AET1Index];
   }
      
#pragma mark reqProcedure
   //=StudyDescription
   NSArray *reqProcedure1Array=nil;
   NSString *reqProcedureOBR44=nil;
   NSString *reqProcedureDescription=nil;

   NSUInteger reqProcedure1Index=[names indexOfObject:@"reqProcedure"];
   if (reqProcedure1Index==NSNotFound) reqProcedure1Index=[names indexOfObject:@"StudyDescription"];
   if (reqProcedure1Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"reqProcedure required"];

   reqProcedure1Array=[values[reqProcedure1Index] procedureCodeArrayForContextPacs:pacsUID1];
      
      /*
       cases:
       nil => reject
       count 1 => not coded
       count 3 => add codes to protocols
       */
      
   if (!reqProcedure1Array) return [RSErrorResponse responseWithClientError:404 message:@"reqProcedure/studyDescription should not contain |"];

   //procedure: OBR 44 Procedure Code (CE) code^meaning^scheme
   if ([reqProcedure1Array count]==3)
   {
      reqProcedureOBR44=[NSString stringWithFormat:@"%@^%@^%@",
                      reqProcedure1Array[0],
                      reqProcedure1Array[1],
                      reqProcedure1Array[2]
                      ];
      reqProcedureDescription=reqProcedure1Array[1];
   }
   else
   {
      reqProcedureOBR44=reqProcedure1Array[0];
      reqProcedureDescription=reqProcedure1Array[0];
   }
      
      

#pragma mark pat
   NSString *patFamily1Name1=nil;
   NSString *patFamily2Name1=nil;
   NSString *patGivenNames1=nil;
   NSString *patIDCountry1=nil;
   NSString *patIDType1=nil;
   NSString *patIDIssuer1=nil;
   NSString *patID1=nil;
   NSString *patBirthDate1=nil;
   NSString *patAdministrativeGender1=nil;
   NSMutableString *composedPatName=nil;
   
   NSUInteger patFamily1Name1Index=[names indexOfObject:@"patFamily1Name"];
   if (patFamily1Name1Index==NSNotFound) patFamily1Name1Index=[names indexOfObject:@"apellido1"];
   if (patFamily1Name1Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"patFamily1Name required"];
   patFamily1Name1=[[values[patFamily1Name1Index] uppercaseString]spaceNormalize];

   NSUInteger patFamily2Name1Index=[names indexOfObject:@"patFamily2Name"];
   if (patFamily2Name1Index==NSNotFound) patFamily2Name1Index=[names indexOfObject:@"patMotherMaidenName"];
   if (patFamily2Name1Index==NSNotFound) patFamily2Name1Index=[names indexOfObject:@"apellido2"];
   if (patFamily2Name1Index==NSNotFound) patFamily2Name1=@"";
   else patFamily2Name1=[[values[patFamily2Name1Index] uppercaseString]spaceNormalize];

   NSUInteger patGivenNames1Index=[names indexOfObject:@"patGivenNames"];
   if (patGivenNames1Index==NSNotFound) patGivenNames1Index=[names indexOfObject:@"nombres"];
   if (patGivenNames1Index==NSNotFound) patGivenNames1=@"";
   else patGivenNames1=[[values[patGivenNames1Index] uppercaseString]spaceNormalize];
   
   NSUInteger patIDCountry1Index=[names indexOfObject:@"patIDCountry"];
   if (patIDCountry1Index==NSNotFound) patIDCountry1Index=[names indexOfObject:@"PatientIDCountry"];
   if (patIDCountry1Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"patIDCountry required"];
   patIDCountry1=[values[patIDCountry1Index] uppercaseString];
   //check if patIDCountry1 is known
   NSUInteger iso3166Index=NSNotFound;
   iso3166Index=[K.iso3166[PAIS] indexOfObject:patIDCountry1];
   if (iso3166Index==NSNotFound)
   {
        iso3166Index=[K.iso3166[COUNTRY] indexOfObject:patIDCountry1];
        if (iso3166Index==NSNotFound)
        {
            iso3166Index=[K.iso3166[AB] indexOfObject:patIDCountry1];
            if (iso3166Index==NSNotFound)
            {
                iso3166Index=[K.iso3166[ABC] indexOfObject:patIDCountry1];
                if (iso3166Index==NSNotFound)
                {
                    iso3166Index=[K.iso3166[XXX] indexOfObject:patIDCountry1];
                    if (iso3166Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"patIDCountry '%@' not valid",patIDCountry1];
                }
            }
        }
   }
   
   NSUInteger patIDType1Index=[names indexOfObject:@"patIDType"];
   if (patIDType1Index==NSNotFound) patIDType1Index=[names indexOfObject:@"PatientIDType"];
   if (patIDType1Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"patIDType required"];
   if ([[K.personidtype allKeys] indexOfObject:values[patIDType1Index]]==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"patIDType '%@' unknown",values[patIDType1Index]];
    
   patIDIssuer1=[NSString stringWithFormat:@"2.16.858.1.%@.%@",(K.iso3166[XXX])[iso3166Index],values[patIDType1Index]];
   
   NSUInteger patID1Index=[names indexOfObject:@"patID"];
   if (patID1Index==NSNotFound) patID1Index=[names indexOfObject:@"PatientID"];
   if (patID1Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"patID required"];
   patID1=values[patID1Index];
   if (![DICMTypes.SHRegex numberOfMatchesInString:patID1 options:0 range:NSMakeRange(0,[patID1 length])]) return [RSErrorResponse responseWithClientError:404 message:@"patID should be > 1 and < 16 chars in length, without space, nor return, nor tab"];
    
   NSUInteger patBirthDate1Index=[names indexOfObject:@"patBirthDate"];
   if (patBirthDate1Index==NSNotFound) patBirthDate1Index=[names indexOfObject:@"PatientBirthDate"];
   if (patBirthDate1Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"patBirthDate required"];
   patBirthDate1=values[patBirthDate1Index];
   if (![DICMTypes.DARegex numberOfMatchesInString:patBirthDate1 options:0 range:NSMakeRange(0,[patBirthDate1 length])]) return [RSErrorResponse responseWithClientError:404 message:@"patBirthDate format should be aaaammdd"];
    
   //PatientSex
   NSUInteger patAdministrativeGender1Index=[names indexOfObject:@"patAdministrativeGender"];
   if (patAdministrativeGender1Index==NSNotFound) patAdministrativeGender1Index=[names indexOfObject:@"PatientSex"];
   if (patAdministrativeGender1Index==NSNotFound) return [RSErrorResponse responseWithClientError:404 message:@"patAdministrativeGender required"];
   patAdministrativeGender1=[values[patAdministrativeGender1Index]uppercaseString];
   NSUInteger PatientSexSaluduyIndex=0;
   if ([patAdministrativeGender1 isEqualToString:@"M"])PatientSexSaluduyIndex=1;
   else if ([patAdministrativeGender1 isEqualToString:@"F"])PatientSexSaluduyIndex=2;
   else if ([patAdministrativeGender1 isEqualToString:@"O"])PatientSexSaluduyIndex=9;
   else  return [RSErrorResponse responseWithClientError:404 message:@"patAdministrativeGender should be 'M','F' or 'O'"];
   
   composedPatName=[NSMutableString stringWithString:patFamily1Name1];
   if ([patFamily2Name1 length]) [composedPatName appendFormat:@">%@",patFamily2Name1];
   if ([patGivenNames1 length]) [composedPatName appendFormat:@"^%@",patGivenNames1];
   

    
#pragma mark patient in pacs ?
   
   NSArray* patientMetadata=[ResponsePatients
                             getFromPacs:pacs
                             patID:patID1
                             issuer:patIDIssuer1
                             ];

   switch ([patientMetadata count]) {
      case 1:
            LOG_VERBOSE(@"mwlitem PAT %@^^^%@ %@ %@ %@\r\n",patID1, patIDIssuer1, ((((patientMetadata[0])[@"00100010"])[@"Value"])[0])[@"Alphabetic"],  (((patientMetadata[0])[@"00100030"])[@"Value"])[0],  (((patientMetadata[0])[@"00100040"])[@"Value"])[0]);
            break;
            
         case 0://create patient
            //returns nil if the request could not be performed
            //returns @"" when the patient was registered
            //returns @"error message" if the server responded with an error
         {
            NSString *response=[ResponsePatients
                                putToPacs:pacs
                                family1:patFamily1Name1
                                family2:patFamily2Name1
                                given:patGivenNames1
                                patID:patID1
                                issuer:patIDIssuer1
                                birthdate:patBirthDate1
                                sex:patAdministrativeGender1
                                contentType:@"application/json" ];
           if ( !response ) return [RSErrorResponse responseWithClientError:404 message:@"can not create patient %@",patID1];
                                
           if ([response length]) return [RSErrorResponse responseWithClientError:404 message:@"can not create patient %@. %@",patID1,response];
                                
           LOG_VERBOSE(@"PAT new: %@^^^%@",patID1, patIDIssuer1);
         }
           break;
            
        default:
            LOG_ERROR(@"mwlitem PAT ambiguity %@^^^%@",patID1, patIDIssuer1);
           return [RSErrorResponse responseWithClientError:404 message:@"patient ambiguity: %@",[patientMetadata description]];
            break;
      }

#pragma mark isrReferring
   NSString *isrReferring1=nil;
   NSUInteger isrReferring1Index=[names indexOfObject:@"isrReferring"];
   if (isrReferring1Index!=NSNotFound) isrReferring1Index=[names indexOfObject:@"ReferringPhysiciansName"];
   if (isrReferring1Index!=NSNotFound)
   {
      NSString *normalized=[values[isrReferring1Index] spaceNormalize];
      NSArray *subcomponents=[normalized componentsSeparatedByString:@"^"];
      if ([subcomponents count]==3)
         isrReferring1=[NSString stringWithFormat:@"%@^%@^%@",subcomponents[0],subcomponents[1],[subcomponents[2]localizedLowercaseString]];
      else isrReferring1=[NSString stringWithString:normalized];
   }

   
#pragma mark isrReading
   
   NSString *isrReading1=nil;
   NSUInteger isrReading1Index=[names indexOfObject:@"isrReading"];
   if (isrReading1Index!=NSNotFound) isrReading1Index=[names indexOfObject:@"NameofPhysicianReadingStudy"];
   if (isrReading1Index!=NSNotFound)
   {
      NSString *normalized=[values[isrReading1Index]spaceNormalize];
      NSArray *subcomponents=[normalized componentsSeparatedByString:@"^"];
      if ([subcomponents count]==3)
         isrReading1=[NSString stringWithFormat:@"%@^%@^%@",subcomponents[0],subcomponents[1],[subcomponents[2]localizedLowercaseString]];
      else isrReading1=[NSString stringWithString:normalized];
   }

   
#pragma mark reqPriority
   NSString *reqPriority1=nil;
   
   NSUInteger reqPriority1Index=[names indexOfObject:@"reqPriority"];
   if (reqPriority1Index==NSNotFound) reqPriority1Index=[names indexOfObject:@"Priority"];
   if (reqPriority1Index==NSNotFound) reqPriority1=@"T";
   else if ([[values[reqPriority1Index] uppercaseString] isEqualToString:@"URGENT"])reqPriority1=@"A";
   else reqPriority1=@"T";
   
   
#pragma mark other default params
   
   NSDate *now=[NSDate date];
   
   NSString *studyIUID=[[NSUUID UUID]ITUTX667UIDString];

   //not available yet
   NSString * messageControlID=nil;
   NSString * isrPlacerNumber=nil;
   NSString * isrInsurance=nil;
   NSString * reqID=nil;
   NSString * spsPerforming=nil;
   NSString * sps1ID=nil;
   NSString * sps2ID=nil;
   NSString * sps3ID=nil;
   NSString * sps4ID=nil;

   
#pragma mark - create mllp mwlitem
   
   

   if ([pacs[@"mwl"]isEqualToString:@"mllp"])
   {
      NSString *msg=[NSString
                     O01version:@"2.3.1"
                     sendingApplication:pacs[@"pacsaet"]
                     sendingFacility:request.remoteAddressString
                     receivingApplication:pacs[@"custodiantitle"]
                     receivingFacility:pacs[@"pacsaet"]
                     messageControlId:messageControlID
                     countryCode:pacs[@"countrycode"]
                     stringEncoding:(NSStringEncoding)[pacs[@"sopstringencoding"]integerValue]
                     principalLanguage:pacs[@"principallanguage"]
                     patIdentifierList:[NSString stringWithFormat:@"%@^^^%@",patID1,patIDIssuer1]
                     patName:[NSString stringWithString:composedPatName]
                     patMotherMaidenName:patFamily2Name1
                     patBirthDate:patBirthDate1
                     patAdministrativeGender:patAdministrativeGender1
                     isrInsurance:isrInsurance
                     isrPlacerNumber:isrPlacerNumber
                     isrFillerNumber:isrFillerNumber
                     isrAN:isrAN1
                     isrReferring:isrReferring1
                     isrReading:isrReading1
                     isrStudyIUID:studyIUID
                     reqID:reqID
                     reqProcedure:reqProcedureOBR44
                     reqPriority:reqPriority1
                     spsDateTime:[DICMTypes DTStringFromDate:now]
                     spsPerforming:spsPerforming
                     sps1ID:sps1ID
                     sps2ID:sps2ID
                     sps3ID:sps3ID
                     sps4ID:sps4ID
                     sps1Modality:sps1Modality1
                     sps2Modality:sps2Modality1
                     sps3Modality:sps3Modality1
                     sps4Modality:sps4Modality1
                     sps1AET:sps1AET1
                     sps2AET:sps2AET1
                     sps3AET:sps3AET1
                     sps4AET:sps4AET1
                     sps1Protocol:sps1Protocol1OBR4
                     sps2Protocol:sps2Protocol1OBR4
                     sps3Protocol:sps3Protocol1OBR4
                     sps4Protocol:sps4Protocol1OBR4
                     sps1OrderStatus:@"ARRIVED"
                     sps2OrderStatus:@"ARRIVED"
                     sps3OrderStatus:@"ARRIVED"
                     sps4OrderStatus:@"ARRIVED"
         ];

      LOG_DEBUG(@"mwlitem MLLP ->\r\n%@",msg);
      
      NSMutableString * payload=[NSMutableString string];

      NSString *ipString=pacs[@"mllpip"];
      if (!ipString)
      {
         [payload appendString:@"mllp ip not available"];
         return [RSErrorResponse responseWithClientError:404 message:@"%@",payload];
      }
      
      NSString *portString=pacs[@"mllpport"];
      if (!portString)
      {
         [payload appendString:@"mllp port not available"];
         return [RSErrorResponse responseWithClientError:404 message:@"%@",payload];
      }

      if (![mllpSend sendIP:ipString
                       port:portString
                    message:msg
                stringEncoding:(NSStringEncoding)[pacs[@"sopstringencoding"]integerValue]
                       payload:(NSMutableString*)payload])
      {
         //could not send mllp
         LOG_ERROR(@"mwlitem MLLP <-\r\n%@",payload);
         return [RSErrorResponse responseWithClientError:404 message:@"%@",payload];
      }
      LOG_DEBUG(@"mwlitem MLLP <-\r\n%@",payload);
   }

   
   NSMutableString* html = [NSMutableString stringWithString:@"<html><body>"];
   [html appendFormat:@"<p>mwlitem sent to %@</p>",dcm4cheelocaluri];

#pragma mark - dscd
    NSMutableString *dscd=[NSMutableString string];
    [dscd appendDSCDprefix];
    [dscd appendSCDprefix];

#pragma mark <realmCode> *
#pragma mark <typeId> 1
    [dscd appendCDAprefix];
    
#pragma mark <templateId> *
    
#pragma mark <id> 1
    NSString *CDAID=[[NSUUID UUID]ITUTX667UIDString];
    /*RIDI
     NSString *CDAID=[NString stringWithFormat:@"2.16.858.2.%llu.67430.%@.%lu.%llu",
        organizationId,
        [DICMTypes DTStringFromDate:timestamp],
        incremental,
        manufacturerId];
     */
    [dscd appendCDAID:CDAID];
    
#pragma mark <code> 1
#pragma mark <title> ?
   switch ([reqProcedure1Array count]) {
      case 1:
         [dscd appendRequestCDATitle:reqProcedure1Array[0]];
         break;
      case 3:
         [dscd appendRequestCDATitle:reqProcedure1Array[1]];
         break;
      default:
         [dscd appendRequestCDATitle:@"Informe imagenológico"];
         break;
   }
   
#pragma mark <effectiveTime> 1
    [dscd appendCurrentCDAEffectiveTime];
    
#pragma mark <confidentialityCode> 1
    [dscd appendNormalCDAConfidentialityCode];
    
#pragma mark <languageCode> ?
    [dscd appendEsCDALanguageCode];
    
#pragma mark <setId> ?
    
#pragma mark <versionNumber> ?
    [dscd appendFirstCDAVersionNumber];

#pragma mark <copyTime> ?

    

#pragma mark <recordTarget> +
    [dscd appendCDARecordTargetWithPid:patID1
                                issuer:patIDIssuer1
                             apellido1:patFamily1Name1
                             apellido2:patFamily2Name1
                               nombres:patGivenNames1
                                   sex:patAdministrativeGender1
                             birthdate:patBirthDate1];
    
#pragma mark <author> +
    [dscd appendCDAAuthorAnonymousOrgid:pacsUID1
                                orgname:pacs[@"custodiantitle"]];
#pragma mark <dataEnterer> ?
#pragma mark <informant> *

#pragma mark <custodian> 1
    [dscd appendCDACustodianOid:pacs[@"custodianoid"]
                           name:pacs[@"custodiantitle"]];

#pragma mark <informationRecipient> *
    //(=ReferringPhysiciansName)
    if (isrReferring1) [dscd appendCDAInformationRecipient:isrReferring1];

#pragma mark <legalAuthenticator> ?
#pragma mark <authenticator> *
#pragma mark <participant> *
    

#pragma mark <inFulfillentOf> * <Order>
    //(=AccessionNumber)
    [dscd appendCDAInFulfillmentOfOrder:isrAN1 issuerOID:isrANIssuer1];

#pragma mark <documentationOf> * <serviceEvent>
    //(=Procedimiento)
    if (reqProcedure1Index!=NSNotFound)
    {        
        if ([reqProcedure1Array count]==1) [dscd appendCDADocumentationOfNotCoded:reqProcedure1Array[0]];
        else [dscd appendCDADocumentationOf:reqProcedure1Array];
    }
    
#pragma mark <relatedDocument> *
    //(=documento reemplazado)
#pragma mark <authorization> *

#pragma mark <componentOf> ? <encompassingEncounter>
    //      <code>
    //      <effectiveTime>  <low> <high>
    //      <location>
    //      <encounterParticipant
    [dscd appendCDAComponentOfEncompassingEncounterEffectiveTime:
     [[DICMTypes DAStringFromDate:now] stringByAppendingString:[DICMTypes TMStringFromDate:now]]
     ];
    
#pragma mark <component> 1
    
    //enclosureTextarea & enclosurePdf
    NSString *enclosureTextarea=nil;
    NSUInteger enclosureTextareaIndex=[names indexOfObject:@"enclosureTextarea"];
    if ((enclosureTextareaIndex!=NSNotFound) && [values[enclosureTextareaIndex] length]) enclosureTextarea=values[enclosureTextareaIndex];

    NSString *enclosurePdf=nil;
    NSUInteger enclosurePdfIndex=[names indexOfObject:@"enclosurePdf"];
    if ((enclosurePdfIndex!=NSNotFound) && [values[enclosurePdfIndex] length]) enclosurePdf=values[enclosurePdfIndex];

    if (enclosureTextarea)
    {
        if (enclosurePdf) [dscd appendCDAComponentWithTextThumbnail:enclosureTextarea forBase64Pdf:enclosurePdf];
        else              [dscd appendCDAComponentWithText:enclosureTextarea];
    }
    else if (enclosurePdf)[dscd appendCDAComponentWithBase64Pdf:enclosurePdf];
    else                  [dscd appendEmptyCDAComponent];
        
#pragma mark epilog
    [dscd appendCDAsuffix];
    [dscd appendSCDsuffix];
    [dscd appendDSCDsuffix];
    
/*
#pragma mark - TODO create array procedureCode {code, scheme meaning, traduction}
    NSDictionary *pacsProcedureDict=K.procedureindexes[pacsUID1];
    if (reqProcedure1Index!=NSNotFound)
    {
        NSDictionary *standarizedSchemesCodes=(pacsProcedureDict[@"codes"])[reqProcedure1Index];
        for (NSString *standarizedScheme in standarizedSchemesCodes)
        {
            NSString *standarizedCode=standarizedSchemesCodes[standarizedScheme];
            NSDictionary *standarizedCodeDict=(K.code[standarizedScheme])[standarizedCode];
           
            if ([standarizedCodeDict[@"translation"] count])
            {
#pragma mark TOOD translation
            }
        }
    }
*/
    NSString *seriesUID=[[NSUUID UUID]ITUTX667UIDString];
    NSString *SOPIUID=[[NSUUID UUID]ITUTX667UIDString];

    //dicom object
    //returns @"" when the dicom object was stowed
    //returns @"error message" or nil if the stow failed

    NSString *errorMessage=
    [ResponseStow
     singleEnclosedDICMToPacs:pacs
     CS:@"ISO_IR 192"
     DA:[DICMTypes DAStringFromDate:now]
     TM:[DICMTypes TMStringFromDate:now]
     TZ:K.defaultTimezone
     modality:@"OT"
     accessionNumber:isrAN1
     accessionIssuer:isrANIssuer1
     accessionType:isrANType1
     studyDescription:reqProcedureDescription
     procedureCodes:reqProcedure1Array
     referring:isrReferring1
     reading:isrReading1
     name:patGivenNames1
     pid:patIDType1
     issuer:patIDIssuer1
     birthdate:patBirthDate1
     sex:patAdministrativeGender1
     instanceUID:SOPIUID
     seriesUID:seriesUID
     studyUID:studyIUID
     seriesNumber:@"-32"
     seriesDescription:@"Orden de servicio"
     enclosureHL7II:@""
     enclosureTitle:@"Solicitud de informe imagenológico"
     enclosureTransferSyntax:@"1.2.840.10008.5.1.4.1.1.104.2"
     enclosureData:[dscd dataUsingEncoding:NSUTF8StringEncoding]
     contentType:@"application/dicom"
     ];

     if ([errorMessage length])
     {
        [html appendFormat:@"<p>%@</p></body></html>",errorMessage];
        return [RSErrorResponse responseWithClientError:404 message:@"%@",html];
     }
    [html appendFormat:@"<p>solicitud dicom cda sent to %@</p>",dcm4cheelocaluri];


#pragma mark qido of the stow, in order to actualize metadata in pacs
   
   if (![[ResponseQido objectsFoundInPacs:pacs
                                 studyUID:studyIUID
                                seriesUID:nil
                                   sopUID:nil
         ]count])
    {
        [html appendString:@"<p>qido failed</p>"];
    }

    
#pragma mark create user in html5dicom
    /*
    Url : http://ip:puerto/accounts/api/user
     found in services1dict html5dicomuserserviceuri
     
    Content-Type : application/json
    
    Body
    {
        "institution": “IRP",
        "username": "15993195-1",
        "password": "clave",
        "first_name": "Claudio Anibal",
        "last_name": "Baeza Gonzalez",
        "is_active": “False"
    }
    
    Para la MWL “is_active" debe ser False
    Para el informe “is_active” debe ser True
    */
    
     NSUInteger clave1Index=[names indexOfObject:@"clave"];
    if (clave1Index==NSNotFound) LOG_VERBOSE(@"[mwlitem] no parameter 'clave' -> no user created in html5dicom");
    else
    {
        NSString *clave1String=values[clave1Index];
        if (![clave1String length]) LOG_VERBOSE(@"mwlitem] parameter 'clave'empty -> no user created in html5dicom");
        else
        {
           NSString *errorMessage=[ResponsePatients
                                   postHtml5dicomuserForPacs:pacs
                                                 institution:pacs[@"custodiantitle"]
                                                    username:patID1
                                                    password:clave1String
                                                   firstname:patGivenNames1
                                                    lastname:[NSString stringWithFormat:@"%@ %@",patFamily1Name1, patFamily2Name1]
                                                    isactive:NO
                                   ];

           
            if (!errorMessage || [errorMessage length])
            {
               LOG_WARNING(@"user not created in html5dicom\r\n%@",errorMessage);
               [html appendFormat:@"user not created in html5dicom\r\n%@",errorMessage];
            }
            else
            {
               LOG_VERBOSE(@"user created in html5dicom");
               [html appendFormat:@"user not created in html5dicom"];
            }
        }
    }
    
    /*
     [html appendString:@"<dl>"];
     for (int i=0; i < [names count]; i++)
     {
     [html appendFormat:@"<dt>%@</dt>",names[i]];
     if (  !types
     ||![types[i] length]
     || [types[i] hasPrefix:@"text"]
     || [types[i] hasPrefix:@"application/json"]
     || [types[i] hasPrefix:@"application/dicom+json"]
     || [types[i] hasPrefix:@"application/xml"]
     || [types[i] hasPrefix:@"application/xml+json"]
     )[html appendFormat:@"<dd>%@</dd>",values[i]];
     else
     {
     [html appendString:@"<dd>"];
     [html appendFormat:@"<embed src=\"data:%@;base64,%@\" width=\"500\" height=\"375\" type=\"%@\">",types[i],values[i],types[i] ];
     [html appendString:@"</dd>"];
     }
     
     }
     [html appendString:@"</dl>"];*/

    [html appendString:@"</body></html>"];
     
     return [RSDataResponse responseWithHTML:html];
     
     
     
     }(request));}];
}


@end
