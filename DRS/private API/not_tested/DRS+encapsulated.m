#import "DRS+encapsulated.h"

#import "NSURLSessionDataTask+DRS.h"

#import "RequestPOSTEncapsulated.h"

#import "NSMutableURLRequest+patient.h"
#import "NSMutableURLRequest+html5dicom.h"

#import "NSData+PCS.h"
#import "NSString+PCS.h"
#import "NSMutableString+DSCD.h"
#import "NSUUID+DICM.h"

#import "NSDictionary+DICM.h"
#import "NSMutableDictionary+DICM.h"
#import "NSMutableData+DICM.h"

#import "RequestPOSTEncapsulated.h"

static NSRegularExpression * _encapsulatedRegex=nil;
NSRegularExpression *encapsulatedRegex(void)
{
   if (!_encapsulatedRegex) _encapsulatedRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\/(OT|DOC)\\/(xml|cda|scd|dscd|pdf)$" options:0 error:NULL];
   return _encapsulatedRegex;
}

//////////////////////////////////////////////////////////////////////

@implementation DRS (encapsulated)


const UInt32        tag00020000     = 0x02;
const UInt32        vrULmonovalued  = 0x044C55;
-(NSData*)createCDADICMDataWithCS:(NSString*)CS
                               DA:(NSString*)DA
                               TM:(NSString*)TM
                               TZ:(NSString*)TZ
                               AN:(NSString*)AN
                          ANLocal:(NSString*)ANLocal
                      ANUniversal:(NSString*)ANUniversal
                  ANUniversalType:(NSString*)ANUniversalType
                         modality:(NSString*)modality
                 studyDescription:(NSString*)studyDescription
                   procedureCodes:(NSArray*)procedureCodes
                        referring:(NSString*)referring
                          reading:(NSString*)reading
                             name:(NSString*)name
                              pid:(NSString*)pid
                           issuer:(NSString*)issuer
                        birthdate:(NSString*)birthdate
                              sex:(NSString*)sex
                      instanceUID:(NSString*)instanceUID
                        seriesUID:(NSString*)seriesUID
                         studyUID:(NSString*)studyUID
                          studyID:(NSString*)studyID
                     seriesNumber:(NSString*)seriesNumber
                seriesDescription:(NSString*)seriesDescription
                    instanceHL7II:(NSString*)instanceHL7II
                    instanceTitle:(NSString*)instanceTitle
                   transferSyntax:(NSString*)ransferSyntax
                             data:(NSData*)data
                   boundaryString:(NSString*)boundaryString
{
   //pid and issuer compulsory
   if (!pid || ![pid length] || !issuer || ![issuer length])
   {
      NSLog(@"both pid (%@) and issuer(%@) are required",pid,issuer);
      return nil;
   }

   
   NSMutableDictionary *dicm=[NSMutableDictionary dictionary];
   
   //DICMC120100    SOP Common
   [dicm addEntriesFromDictionary:
    [NSDictionary
     DICMC120100ForSOPClassUID1:@"1.2.840.10008.5.1.4.1.1.104.2"
                SOPInstanceUID1:instanceUID
                       charset1:CS
                            DA1:DA
                            TM1:TM
                             TZ:TZ
     ]
    ];
   
    //DICMC070101    Patient
    [dicm addEntriesFromDictionary:
     [NSDictionary
      DICMC070101PatientWithName:name
      pid:pid
      issuer:issuer
      birthdate:birthdate
      sex:sex
      ]
     ];
   
    //DICMC070201    General Study
    [dicm addEntriesFromDictionary:
     [NSDictionary
      DICMC070201StudyWithUID:AN
      DA:DA
      TM:TM
      ID:studyID
      AN:AN
      ANLocal:ANLocal
      ANUniversal:ANUniversal
      ANUniversalType:ANUniversalType
      description:studyDescription
      procedureCodes:procedureCodes
      referring:referring
      reading:reading
      ]
     ];
   
    //DICMC240100    Encapsulated Series
    [dicm addEntriesFromDictionary:
     [NSDictionary
      DICMC240100ForModality1:modality
      seriesUID1:seriesUID
      seriesNumber2:seriesNumber
      seriesDA3:DA
      seriesTM3:TM
      seriesDescription3:seriesDescription
      ]
     ];
   
    //DICMC070501    General Equipment
    [dicm addEntriesFromDictionary:
     [NSDictionary DICMC070501ForInstitution:ANLocal]
     ];
   
    //DICMC080601    SC Equipment
    [dicm addEntriesFromDictionary:
     [NSDictionary DICMC080601ForConversionType1:@"WSD"]
     ];
   
    //DICMC240200    Encapsulated Document
    [dicm addEntriesFromDictionary:
     [NSDictionary
      DICMC240200EncapsulatedCDAWithDA:DA
      TM:TM
      title:instanceTitle
      HL7II:instanceHL7II
      data:data
     ]
    ];
   
   
   //MutableDictionary -> NSMutableData
   NSMutableData *stowData=[NSMutableData data];
   
   if ([boundaryString length])
      [stowData appendData:
       [
        [NSString stringWithFormat:@"\r\n--%@\r\nContent-Type:application/dicom\r\n\r\n",boundaryString]
        dataUsingEncoding:NSASCIIStringEncoding
        ]
       ];
   
   [stowData increaseLengthBy:128];
   [stowData appendDICMSignature];
   
    
   NSMutableData *metainfoData=[NSMutableData DICMDataGroup2WithDICMDictionary:
    [NSDictionary DICM0002ForMediaStorageSOPClassUID:@"1.2.840.10008.5.1.4.1.1.104.2"
       mediaStorageSOPInstanceUID:instanceUID
       implementationClassUID:@""
       implementationVersionName:@""
       sourceApplicationEntityTitle:@""
       privateInformationCreatorUID:@""
       privateInformation:nil
     ]
   ];
   UInt32 count00020000 = (UInt32)[metainfoData length];
   [stowData appendBytes:&tag00020000    length:4];
   [stowData appendBytes:&vrULmonovalued length:4];
   [stowData appendBytes:&count00020000  length:4];
   [stowData appendData:metainfoData];
   
   
   [stowData appendData:
    [NSMutableData DICMDataWithDICMDictionary:dicm bulkdataBaseURI:nil]
    ];
   
   if ([boundaryString length])
      [stowData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundaryString] dataUsingEncoding:NSASCIIStringEncoding]];
   
   return [NSData dataWithData:stowData];
}



/*   return [RequestPOSTEncapsulated toPacs:pacs
dicomSubtype:@""
boundaryString:boundaryString
bodyData:stowData
];
*/


-(void)POSTencapsulated
{
   [self addHandler:@"POST" regex:encapsulatedRegex processBlock:
    ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
       {
          NSError *error=nil;

          NSArray * pathComponents=[request.URL pathComponents];
          BOOL isDOC=[pathComponents[0] isEqualToString:@"DOC"];
          BOOL isOT=[pathComponents[0] isEqualToString:@"OT"];
          NSString * objectType=pathComponents[1];

          
          NSURLComponents * urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];

#pragma mark params
          NSMutableArray *names=[NSMutableArray array];
          NSMutableArray *values=[NSMutableArray array];
          NSMutableArray *types=[NSMutableArray array];
          NSMutableString *jsonString=[NSMutableString string];
          NSMutableString *errorString=[NSMutableString string];
          if (!parseRequestParams(request, names, values, types, jsonString, errorString))
             return [RSErrorResponse responseWithClientError:404 message:@"%@",errorString];
          
          
#pragma mark validation pacs
          NSMutableString *pacsOID=[NSMutableString string];
          NSDictionary *pacs=pacsParam(names,
                                       values,
                                       pacsOID,
                                       errorString);
          

#pragma mark dcm4cheelocaluri available?
             if (
                 !pacs[@"dcm4cheelocaluri"]
                 ||![pacs[@"dcm4cheelocaluri"] length]
                 )
             {
                LOG_WARNING(@"<-404:  pacs '%@' is not a dcm4chee-arc one",pacsOID);
                return [RSErrorResponse responseWithClientError:404 message:@"pacs '%@' is not a dcm4chee-arc one",pacsOID];
             }
             LOG_INFO(@"<pacs> %@",pacsOID);
          }
          else
          {
             pacsOID=DRS.defaultpacsoid;
             pacs=DRS.pacs[DRS.defaultpacsoid];
             LOG_INFO(@"<pacs> %@ (default)",pacsOID);
          }
          
          
#pragma mark validation PatientID input
          //PatientID must be present
          NSUInteger PatientID1Index=[names indexOfObject:@"PatientID"];
          if (PatientID1Index==NSNotFound)
          {
             LOG_WARNING(@"[pdf]<request> <-404:  'PatientID' required");
             return [RSErrorResponse responseWithClientError:404 message:@"[pdf] 'PatientID' required"];
          }
          NSString *PatientID1=values[PatientID1Index];
          if (![DICMTypes.SHRegex numberOfMatchesInString:values[PatientID1Index] options:0 range:NSMakeRange(0,[PatientID1 length])])
          {
             LOG_WARNING(@"[pdf]<request> <-404:  PatientID should be > 1 and < 16 chars in length, without space, nor return, nor tab");
             return [RSErrorResponse responseWithClientError:404 message:@"[pdf] PatientID should be > 1 and < 16 chars in length, without space, nor return, nor tab"];
          }
          
          //PatientIDIssuer input
          NSUInteger IDCountryIndex=[names indexOfObject:@"PatientIDCountry"];
          if (IDCountryIndex==NSNotFound)
          {
             LOG_WARNING(@"[pdf]<request> <-404: 'PatientIDCountry' required");
             return [RSErrorResponse responseWithClientError:404 message:@"[pdf] 'PatientIDCountry' required"];
          }
          
          NSString *IDCountryValue=[values[IDCountryIndex] uppercaseString];
          
          NSUInteger iso3166Index=NSNotFound;
          iso3166Index=[K.iso3166[PAIS] indexOfObject:IDCountryValue];
          if (iso3166Index==NSNotFound)
          {
             iso3166Index=[K.iso3166[COUNTRY] indexOfObject:IDCountryValue];
             if (iso3166Index==NSNotFound)
             {
                iso3166Index=[K.iso3166[AB] indexOfObject:IDCountryValue];
                if (iso3166Index==NSNotFound)
                {
                   iso3166Index=[K.iso3166[ABC] indexOfObject:IDCountryValue];
                   if (iso3166Index==NSNotFound)
                   {
                      iso3166Index=[K.iso3166[XXX] indexOfObject:IDCountryValue];
                      if (iso3166Index==NSNotFound)
                      {
                         LOG_WARNING(@"[pdf]<request> <-404:  PatientID Country '%@' not valid",IDCountryValue);
                         return [RSErrorResponse responseWithClientError:404 message:@"[pdf] PatientID Country '%@' not valid",IDCountryValue];
                      }
                   }
                }
             }
          }
          
          NSUInteger PatientIDTypeIndex=[names indexOfObject:@"PatientIDType"];
          if (PatientIDTypeIndex==NSNotFound)
          {
             LOG_WARNING(@"[pdf]<request> <-404: 'PatientIDType' required");
             return [RSErrorResponse responseWithClientError:404 message:@"[pdf] 'PatientIDType' required"];
          }
          if ([[K.personidtype allKeys] indexOfObject:values[PatientIDTypeIndex]]==NSNotFound)
          {
             LOG_WARNING(@"[pdf]<request> <-404: PatientIDType '%@' unknown",values[PatientIDTypeIndex]);
             return [RSErrorResponse responseWithClientError:404 message:@"[pdf] PatientIDType '%@' unknown",values[PatientIDTypeIndex]];
          }
          
          NSString *IssuerOfPatientID1=[NSString stringWithFormat:@"2.16.858.1.%@.%@",(K.iso3166[XXX])[iso3166Index],values[PatientIDTypeIndex]];
          
          
#pragma mark validation AccessionNumber input
          //AccessionNumber must be present
          NSUInteger AccessionNumberIndex=[names indexOfObject:@"AccessionNumber"];
          if (AccessionNumberIndex==NSNotFound)
          {
             LOG_WARNING(@"[pdf]<request> <-404: AccessionNumber required");
             return [RSErrorResponse responseWithClientError:404 message:@"[pdf] AccessionNumber required"];
          }
          NSString *AccessionNumber1=values[AccessionNumberIndex];
          
          if (![DICMTypes.SHRegex numberOfMatchesInString:AccessionNumber1 options:0 range:NSMakeRange(0,[values[AccessionNumberIndex] length])])
          {
             LOG_WARNING(@"[pdf]<request> AccessionNumber should be > 1 and < 16 chars in length, without space, nor return, nor tab");
             return [RSErrorResponse responseWithClientError:404 message:@"[pdf] AccessionNumber should be > 1 and < 16 chars in length, without space, nor return, nor tab"];
          }
          
          NSString *issuerLocal1=nil;
          NSUInteger issuerLocalIndex=[names indexOfObject:@"issuerLocal"];
          if ((issuerLocalIndex!=NSNotFound) && [values[issuerLocalIndex] length]) issuerLocal1=values[issuerLocalIndex];
          
          NSString *issuerUniversal1=nil;
          NSUInteger issuerUniversalIndex=[names indexOfObject:@"issuerUniversal"];
          if ((issuerUniversalIndex!=NSNotFound) && [values[issuerUniversalIndex] length]) issuerUniversal1=values[issuerUniversalIndex];
          
          NSString *issuerType1=nil;
          NSUInteger issuerTypeIndex=[names indexOfObject:@"issuerType"];
          if (issuerTypeIndex==NSNotFound) issuerTypeIndex=[names indexOfObject:@"issuerTipo"];
          if ((issuerTypeIndex!=NSNotFound) && [values[issuerTypeIndex] length]) issuerType1=values[issuerTypeIndex];
          
#pragma mark initializations
          NSDate *now=[NSDate date];
          NSString *CDAID=[[NSUUID UUID]ITUTX667UIDString];
          NSString *studyUID=nil;
          NSString *seriesUID=nil;
          NSString *SOPIUID=nil;
          NSMutableURLRequest *POSTencapsulatedRequest;
          //pacs or input
          NSString *patientFamily1=nil;
          NSString *patientFamily2=nil;
          NSString *patientNames=nil;
          
          NSString *PatientName1=nil;
          NSString *PatientBirthdate1=nil;
          NSString *PatientSexValue1=nil;
          NSString *ReferringPhysiciansName1=nil;
          NSString *NameofPhysicianReadingStudy1=nil;
          NSUInteger NameofPhysicianReadingStudyIndex=[names indexOfObject:@"NameofPhysicianReadingStudy"];
          if (NameofPhysicianReadingStudyIndex!=NSNotFound) NameofPhysicianReadingStudy1=[values[NameofPhysicianReadingStudyIndex] spaceNormalize];
          
#pragma mark dscd
          NSMutableString *dscd=[NSMutableString string];
          [dscd appendDSCDprefix];
          [dscd appendSCDprefix];
          
#pragma mark <realmCode> *
#pragma mark <typeId> 1
          [dscd appendCDAprefix];
          
#pragma mark <templateId> *
          
#pragma mark <id> 1
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
          // (=StudyDescription)
          NSString *enclosureTextarea=nil;
          NSUInteger enclosureTextareaIndex=[names indexOfObject:@"DocumentTitle"];
          if ((enclosureTextareaIndex!=NSNotFound) && [values[enclosureTextareaIndex] length]) enclosureTextarea=values[enclosureTextareaIndex];
          else if (isDOC) enclosureTextarea=@"informe imagenológico";
          else enclosureTextarea=@"pdf";
          
          [dscd appendRequestCDATitle:enclosureTextarea];
          //appendReportCDATitle
          
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
          
          
          
          
#pragma mark ACCESSIONNUMBER ALREADY IN PACS?
          NSDictionary *existingStudy=[NSURLSessionDataTask existsInPacs:pacs accessionNumber:AccessionNumber1 issuerLocal:issuerLocal1 issuerUniversal:issuerUniversal1 issuerType:issuerType1 returnAttributes:true];
#pragma mark - YES
          if (existingStudy)
          {
             LOG_VERBOSE(@"[pdf]<accessionNumber>\r\n%@",[existingStudy description]);
             //check if Patient ID matches
             BOOL IDmatches=[PatientID1 isEqualToString:((existingStudy[@"00100020"])[@"Value"])[0]];
             // !!!!!!!  el pacs no devuelve 00100021 !!!!!!!
             //if (IssuerOfPatientID1) IDmatches &= [IssuerOfPatientID1 isEqualToString:((existingStudy[@"00100021"])[@"Value"])[0]];
             
             //Si AccessionNumber corresponde a un estudio presente en el PACS y PatientID a un paciente que no corresponde, el informe está rechazado
             if (!IDmatches)
             {
                LOG_WARNING(@"[pdf]<request> <-404:  there exists a study with same accession number but different patient ID. Cannot register the report.");
                
                return [RSErrorResponse responseWithClientError:404 message:@"[pdf] there exists a study with same accession number but different patient ID. Cannot register the report."];
             }
             
             //Si el identificador del paciente corresponde pero los otros datos patronímicos no corresponden, ni de cerca (por ejemplo sexo diferente, fecha de nacimiento muy diferente, nombres o apellido que no corresponden) el informe está rechazado.
             //#pragma mark TODO check other demographics
             
             //  Si ambos el accessionNumber y PatientID  corresponden a un estudio ya presente en el PACS, el informe se adjunta al estudio y los otros campos demográficos del paciente son opcionales y no tomados en cuenta
             
             
             
#pragma mark <recordTarget> +
             PatientName1=(((existingStudy[@"00100010"])[@"Value"])[0])[@"Alphabetic"];
             NSArray *PatientArray=[PatientName1 componentsSeparatedByString:@"^"];
             NSArray *PatientFamilyArray=[PatientArray[0] componentsSeparatedByString:@">"];
             patientFamily1=PatientFamilyArray[0];
             if ([PatientFamilyArray count]==2) patientFamily2=PatientFamilyArray[1];
             if ([PatientArray count]>1) patientNames=PatientArray[1];
             [dscd appendCDARecordTargetWithPid:((existingStudy[@"00100020"])[@"Value"])[0]
                                         issuer:((existingStudy[@"00100021"])[@"Value"])[0]
                                      apellido1:patientFamily1
                                      apellido2:patientFamily2
                                        nombres:patientNames
                                            sex:((existingStudy[@"00100040"])[@"Value"])[0]
                                      birthdate:((existingStudy[@"00100030"])[@"Value"])[0]
              ];
             
#pragma mark <author> +
             if (NameofPhysicianReadingStudy1 && [NameofPhysicianReadingStudy1 length])
             {
                NSArray  *readingInstServProf=[NameofPhysicianReadingStudy1 componentsSeparatedByString:@"^"];
                NSString* institution=readingInstServProf[0];
                NSString* service=nil;
                NSString* user=nil;
                if ([readingInstServProf count]>1) service=readingInstServProf[1];
                if ([readingInstServProf count]>2) user=readingInstServProf[2];
                
                [dscd appendCDAAuthorInstitution:institution
                                         service:service
                                            user:user];
             }
             else [dscd appendCDAAuthorAnonymousOrgid:pacsOID orgname:pacs[@"custodiantitle"]];
             
             
#pragma mark <dataEnterer> ?
#pragma mark <informant> *
             
#pragma mark <custodian> 1
             [dscd appendCDACustodianOid:pacs[@"custodianoid"]
                                    name:pacs[@"custodiantitle"]];
             
#pragma mark <informationRecipient> *
             NSString *informationRecipient=(((existingStudy[@"00080090"])[@"Value"])[0])[@"Alphabetic"];
             if (informationRecipient && [informationRecipient length]) ReferringPhysiciansName1=informationRecipient;
             else
             {
                NSUInteger ReferringPhysiciansNameIndex=[names indexOfObject:@"ReferringPhysiciansName"];
                if (ReferringPhysiciansNameIndex!=NSNotFound) ReferringPhysiciansName1=[values[ReferringPhysiciansNameIndex] spaceNormalize];
             }
             if (ReferringPhysiciansName1) [dscd appendCDAInformationRecipient:ReferringPhysiciansName1];
             
#pragma mark <legalAuthenticator> ?
#pragma mark <authenticator> *
#pragma mark <participant> *
             
             
#pragma mark <inFulfillentOf> * <Order>
             //(=AccessionNumber)
             [dscd appendCDAInFulfillmentOfOrder:((existingStudy[@"00080050"])[@"Value"])[0] issuerOID:pacs[@"custodianoid"]];
             
#pragma mark <documentationOf> * <serviceEvent>
             //(=Procedimiento)
             [dscd appendCDADocumentationOfNotCoded:((existingStudy[@"00081030"])[@"Value"])[0]];
             
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
             
             [dscd appendCDAsuffix];
             [dscd appendSCDsuffix];
             [dscd appendDSCDsuffix];
             
#pragma mark request to APPEND to study
             
             studyUID=((existingStudy[@"0020000D"])[@"Value"])[0];
             seriesUID=[[NSUUID UUID]ITUTX667UIDString];
             SOPIUID=[[NSUUID UUID]ITUTX667UIDString];
             
             //dicom object
             if (isDOC)
             {
                POSTencapsulatedRequest=
                [NSMutableURLRequest
                 POSTencapsulatedToPacs:pacs
                 CS:@"ISO_IR 192"
                 DA:[DICMTypes DAStringFromDate:now]
                 TM:[DICMTypes TMStringFromDate:now]
                 TZ:K.defaultTimezone
                 AN:AccessionNumber1
                 ANLocal:pacs[@"pacsaet"]
                 ANUniversal:pacs[@"custodianoid"]
                 ANUniversalType:@"ISO"
                 modality:@"DOC"
                 studyDescription:((existingStudy[@"00081030"])[@"Value"])[0]
                 procedureCodes:@[]
                 referring:ReferringPhysiciansName1
                 reading:NameofPhysicianReadingStudy1
                 name:PatientName1
                 pid:((existingStudy[@"00100020"])[@"Value"])[0]
                 issuer:((existingStudy[@"00100021"])[@"Value"])[0]
                 birthdate:((existingStudy[@"00100030"])[@"Value"])[0]
                 sex:((existingStudy[@"00100040"])[@"Value"])[0]
                 instanceUID:SOPIUID
                 seriesUID:seriesUID
                 studyUID:studyUID
                 studyID:nil
                 seriesNumber:@"-16"
                 seriesDescription:@"Informe imagenológico"
                 enclosureHL7II:CDAID
                 enclosureTitle:enclosureTextarea
                 enclosureTransferSyntax:@"1.2.840.10008.5.1.4.1.1.104.2"
                 enclosureData:[dscd dataUsingEncoding:NSUTF8StringEncoding]
                 contentType:@"application/dicom"
                 ];
             }
             else //pdf document which is not a report
             {
                POSTencapsulatedRequest=
                [NSMutableURLRequest
                 POSTencapsulatedToPacs:pacs
                 CS:@"ISO_IR 192"
                 DA:[DICMTypes DAStringFromDate:now]
                 TM:[DICMTypes TMStringFromDate:now]
                 TZ:K.defaultTimezone
                 AN:AccessionNumber1
                 ANLocal:pacs[@"pacsaet"]
                 ANUniversal:pacs[@"custodianoid"]
                 ANUniversalType:@"ISO"
                 modality:@"OT"
                 studyDescription:((existingStudy[@"00081030"])[@"Value"])[0]
                 procedureCodes:@[]
                 referring:ReferringPhysiciansName1
                 reading:NameofPhysicianReadingStudy1
                 name:PatientName1
                 pid:((existingStudy[@"00100020"])[@"Value"])[0]
                 issuer:((existingStudy[@"00100021"])[@"Value"])[0]
                 birthdate:((existingStudy[@"00100030"])[@"Value"])[0]
                 sex:((existingStudy[@"00100040"])[@"Value"])[0]
                 instanceUID:SOPIUID
                 seriesUID:seriesUID
                 studyUID:studyUID
                 studyID:nil
                 seriesNumber:@"-31"
                 seriesDescription:@"documento PDF"
                 enclosureHL7II:CDAID
                 enclosureTitle:enclosureTextarea
                 enclosureTransferSyntax:@"1.2.840.10008.5.1.4.1.1.104.2"
                 enclosureData:[dscd dataUsingEncoding:NSUTF8StringEncoding]
                 contentType:@"application/dicom"
                 ];
             }
             
             
          }
          else //No existe AccessionNumber
          {
#pragma mark - NO
             
#pragma mark patient in pacs ?
             NSArray *patients=[NSURLSessionDataTask existsInPacs:pacs pid:PatientID1 issuer:IssuerOfPatientID1 returnAttributes:true];
             if (patients)
             {
                if ([patients count]>1)
                {
                   LOG_WARNING(@"[pdf]<request> <-404:  there is more than one patient with pid:%@ and issuer:%@",PatientID1,IssuerOfPatientID1);
                   return [RSErrorResponse responseWithClientError:404 message:@"[pdf] <request> <-404:  there is more than one patient with pid:%@ and issuer:%@",PatientID1,IssuerOfPatientID1];
                }
                PatientName1=((((patients[0])[@"00100010"])[@"Value"])[0])[@"Alphabetic"];
                PatientBirthdate1=(((patients[0])[@"00100030"])[@"Value"])[0];
                PatientSexValue1=(((patients[0])[@"00100040"])[@"Value"])[0];
             }
             else
             {
                //NO. Create patient
                //PatientName input
                NSMutableString *PatientMutableName=[NSMutableString string];
                
                NSUInteger apellido1Index=[names indexOfObject:@"apellido1"];
                if (apellido1Index==NSNotFound)
                {
                   LOG_WARNING(@"[pdf]<request> <-404:  'apellido1' required");
                   return [RSErrorResponse responseWithClientError:404 message:@"[pdf] 'apellido1' required"];
                }
                patientFamily1=[[values[apellido1Index] uppercaseString]spaceNormalize];
                [PatientMutableName appendString:patientFamily1];
                
                NSUInteger apellido2Index=[names indexOfObject:@"apellido2"];
                patientFamily2=[[values[apellido2Index] uppercaseString]spaceNormalize];
                if (apellido2Index!=NSNotFound) [PatientMutableName appendFormat:@">%@",patientFamily2];
                
                NSUInteger nombresIndex=[names indexOfObject:@"nombres"];
                patientNames=[[values[nombresIndex] uppercaseString]spaceNormalize];
                
                if (nombresIndex!=NSNotFound) [PatientMutableName appendFormat:@"^%@",patientNames];
                PatientName1=[NSString stringWithString:PatientMutableName];
                
                
                //PatientBirthDate
                NSUInteger PatientBirthDateIndex=[names indexOfObject:@"PatientBirthDate"];
                if (PatientBirthDateIndex==NSNotFound)
                {
                   LOG_WARNING(@"[pdf]<request> <-404:  'PatientBirthDate' required");
                   return [RSErrorResponse responseWithClientError:404 message:@"[pdf] 'PatientBirthDate' required"];
                }
                PatientBirthdate1=values[PatientBirthDateIndex];
                if (![DICMTypes.DARegex numberOfMatchesInString:PatientBirthdate1 options:0 range:NSMakeRange(0,[PatientBirthdate1 length])])
                {
                   LOG_WARNING(@"[pdf]<request> <-404:  'PatientBirthdate' format should be aaaammdd");
                   return [RSErrorResponse responseWithClientError:404 message:@"[pdf] 'PatientBirthdate' format should be aaaammdd"];
                }
                
                //PatientSex
                NSUInteger PatientSexIndex=[names indexOfObject:@"PatientSex"];
                if (PatientSexIndex==NSNotFound)
                {
                   LOG_WARNING(@"[pdf]<request> <-404:  'PatientSex' required");
                   return [RSErrorResponse responseWithClientError:404 message:@"[pdf] 'PatientSex' required"];
                }
                PatientSexValue1=[values[PatientSexIndex]uppercaseString];
                NSUInteger PatientSexSaluduyIndex=0;
                if ([PatientSexValue1 isEqualToString:@"M"])PatientSexSaluduyIndex=1;
                else if ([PatientSexValue1 isEqualToString:@"F"])PatientSexSaluduyIndex=2;
                else if ([PatientSexValue1 isEqualToString:@"O"])PatientSexSaluduyIndex=9;
                else
                {
                   LOG_WARNING(@"[pdf]<request> <-404:  'PatientSex' should be 'M','F' or 'O'");
                   return [RSErrorResponse responseWithClientError:404 message:@"[pdf] 'PatientSex' should be 'M','F' or 'O'"];
                }
                LOG_INFO(@"[pdf] <PatientID> %@",PatientID1);
                
                
                
                
                
                NSString *URLString=[NSString stringWithFormat:@"%@/rs/patients/%@%%5E%%5E%%5E%@",
                                     pacs[@"dcm4cheelocaluri"],
                                     PatientID1,IssuerOfPatientID1
                                     ];
                LOG_VERBOSE(@"[pdf] <Patient> PUT  request %@",URLString);
                NSMutableURLRequest *PUTpatientRequest=
                [NSMutableURLRequest
                 PUTpatient:URLString
                 name:PatientName1
                 pid:PatientID1
                 issuer:IssuerOfPatientID1
                 birthdate:(NSString *)PatientBirthdate1
                 sex:PatientSexValue1
                 contentType:@"application/json"
                 timeout:60
                 ];
                LOG_DEBUG(@"[pdf] <Patient> PUT request HTTPBody: %@",[[NSString alloc] initWithData:[PUTpatientRequest HTTPBody] encoding:NSUTF8StringEncoding]);
                
                NSHTTPURLResponse *PUTpatientResponse=nil;
                //URL properties: expectedContentLength, MIMEType, textEncodingName
                //HTTP properties: statusCode, allHeaderFields
                NSData *PUTpatientResponseData=[NSURLSessionDataTask sendSynchronousRequest:PUTpatientRequest returningResponse:&PUTpatientResponse error:&error];
                NSString *PUTpatientResponseString=[[NSString alloc]initWithData:PUTpatientResponseData encoding:NSUTF8StringEncoding];
                LOG_VERBOSE(@"[pdf] <Patient> PUT response %ld HTTPBody: %@",(long)PUTpatientResponse.statusCode,PUTpatientResponseString);
                if ( error || PUTpatientResponse.statusCode>299)
                {
                   LOG_WARNING(@"[pdf]<Patient> <-404:  PUT response: %@",[error description]);
                   return [RSErrorResponse responseWithClientError:404 message:@"[pdf] can not PUT patient %@. Error: %@",PatientName1,[error description]];
                }
                //check patient created and get the metadata
                if (![NSURLSessionDataTask existsInPacs:pacs pid:PatientID1 issuer:IssuerOfPatientID1 returnAttributes:false])
                {
                   LOG_WARNING(@"[pdf]<request> <-404:  could not create in pacs patient with pid:%@ and issuer:%@",PatientID1,IssuerOfPatientID1);
                   return [RSErrorResponse responseWithClientError:404 message:@"[pdf] <request> <-404:  could not create in pacs patient with pid:%@ and issuer:%@",PatientID1,IssuerOfPatientID1];
                }
             }
             
#pragma mark create a new study with the report
             
#pragma mark validation StudyDescription
             
             NSDictionary *pacsProcedureDict=nil;
             NSInteger procedureIndex=NSNotFound;
             //K.schemeindexes
             NSUInteger schemeIndex=NSNotFound;//depending on the usage (dicom, CDA, etc) the scheme may have diferent name !
             
             NSUInteger StudyDescriptionIndex=[names indexOfObject:@"StudyDescription"];
             NSString *StudyDescription1=nil;
             NSArray *StudyDescription1Array=nil;
             if (StudyDescriptionIndex==NSNotFound)
             {
                LOG_WARNING(@"[pdf]<Request> <-404:  studyDescription required");
                return [RSErrorResponse responseWithClientError:404 message:@"[pdf] studyDescription required"];
             }
             else
             {
                StudyDescription1=[values[StudyDescriptionIndex]spaceNormalize];
                StudyDescription1Array=[StudyDescription1 componentsSeparatedByString:@"^"];
                if ([StudyDescription1Array count]!=3) LOG_WARNING(@"[pdf] <title> outside catalog: %@",StudyDescription1);
                else
                {
                   //scheme
                   NSString *filter=StudyDescription1Array[1];
                   schemeIndex=[K.schemeindexes[@"key"] indexOfObject:filter];
                   if (schemeIndex==NSNotFound)
                   {
                      schemeIndex=[K.schemeindexes[@"oid"] indexOfObject:filter];
                      if (schemeIndex==NSNotFound)
                      {
                         schemeIndex=[K.schemeindexes[@"shortname"] indexOfObject:filter];
                         if (schemeIndex==NSNotFound)
                         {
                            schemeIndex=[K.schemeindexes[@"dcm"] indexOfObject:filter];
                            if (schemeIndex==NSNotFound)
                            {
                               schemeIndex=[K.schemeindexes[@"hl7v2"] indexOfObject:filter];
                               if (schemeIndex==NSNotFound)
                               {
                                  LOG_WARNING(@"[pdf]<Request> <-404:  code scheme '%@' not known",filter);
                                  return [RSErrorResponse responseWithClientError:404 message:@"[pdf] code scheme '%@' not known",filter];
                               }
                            }
                         }
                      }
                   }
                   //schemeIndex found
                   
                   
                   pacsProcedureDict=K.procedureindexes[pacsOID];
                   NSString *thisCode=StudyDescription1Array[0];
                   
                   //try with key (=code)
                   procedureIndex=[pacsProcedureDict[@"key"] indexOfObject:thisCode];
                   if (procedureIndex==NSNotFound)
                   {
                      //try with shortname
                      procedureIndex=[pacsProcedureDict[@"shortname"] indexOfObject:thisCode];
                      if (procedureIndex==NSNotFound)
                      {
                         //try with fullname
                         procedureIndex=[pacsProcedureDict[@"fullname"] indexOfObject:StudyDescription1Array[2]];
                         if (procedureIndex==NSNotFound)
                         {
                            //try with corresponding code and select if there is one correspondance only
                            NSUInteger codesCount=[pacsProcedureDict[@"codes"] count];
                            for (NSUInteger i=0;i<codesCount;i++)
                            {
                               NSArray *theseCorrespondingCodes=[(pacsProcedureDict[@"codes"])[i] allValues];
                               if ((procedureIndex==NSNotFound)&&([theseCorrespondingCodes indexOfObject:thisCode]!=NSNotFound)) procedureIndex=i;
                               else if ([theseCorrespondingCodes indexOfObject:thisCode]!=NSNotFound)
                               {
                                  procedureIndex=NSNotFound;
                                  LOG_WARNING(@"[pdf] study description includes an ambiguous code which belongs to various procedures: %@",StudyDescription1);
                                  break;
                               }
                            }
                            
                            procedureIndex=[pacsProcedureDict[@"fullname"] indexOfObject:thisCode];
                         }
                      }
                   }
                   //no match at all
                   if (procedureIndex==NSNotFound)
                   {
                      LOG_WARNING(@"[pdf]<Request> <-404:  code '%@' not known in pacs %@",StudyDescription1Array[0], pacsOID);
                      return [RSErrorResponse responseWithClientError:404 message:@"[pdf] code '%@' not known in pacs %@",StudyDescription1Array[0], pacsOID];
                   }
                   LOG_INFO(@"[pdf] <procedure> %@",StudyDescription1Array[0]);
                }
             }
             
             
#pragma mark <recordTarget> +
             
             [dscd appendCDARecordTargetWithPid:PatientID1
                                         issuer:IssuerOfPatientID1
                                      apellido1:patientFamily1
                                      apellido2:patientFamily2
                                        nombres:patientNames
                                            sex:PatientSexValue1
                                      birthdate:PatientBirthdate1];
             
#pragma mark <author> +
             if (NameofPhysicianReadingStudy1 && [NameofPhysicianReadingStudy1 length])
             {
                NSArray  *readingInstServProf=[NameofPhysicianReadingStudy1 componentsSeparatedByString:@"^"];
                NSString* institution=readingInstServProf[0];
                NSString* service=nil;
                NSString* user=nil;
                if ([readingInstServProf count]>1) service=readingInstServProf[1];
                if ([readingInstServProf count]>2) user=readingInstServProf[2];
                
                [dscd appendCDAAuthorInstitution:institution
                                         service:service
                                            user:user];
             }
             else [dscd appendCDAAuthorAnonymousOrgid:pacsOID orgname:pacs[@"custodiantitle"]];
             
#pragma mark <dataEnterer> ?
#pragma mark <informant> *
             
#pragma mark <custodian> 1
             [dscd appendCDACustodianOid:pacs[@"custodianoid"]
                                    name:pacs[@"custodiantitle"]];
             
#pragma mark <informationRecipient> *
             //(=ReferringPhysiciansName)
             NSUInteger ReferringPhysiciansNameIndex=[names indexOfObject:@"ReferringPhysiciansName"];
             if (ReferringPhysiciansNameIndex!=NSNotFound) ReferringPhysiciansName1=[values[ReferringPhysiciansNameIndex] spaceNormalize];
             if (ReferringPhysiciansName1) [dscd appendCDAInformationRecipient:ReferringPhysiciansName1];
             
#pragma mark <legalAuthenticator> ?
#pragma mark <authenticator> *
#pragma mark <participant> *
             
             
#pragma mark <inFulfillentOf> * <Order>
             //(=AccessionNumber)
             
#pragma mark <documentationOf> * <serviceEvent>
             //(=Procedimiento)
             if (procedureIndex!=NSNotFound)
             {
                if ([(pacsProcedureDict[@"codes"])[procedureIndex] count]==0) [dscd appendCDADocumentationOfNotCoded:StudyDescription1];
                else [dscd appendCDADocumentationOf:StudyDescription1 fromPacsProcedureDict:pacsProcedureDict procedureIndex:procedureIndex schemeIndex:schemeIndex];
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
             
             [dscd appendCDAsuffix];
             [dscd appendSCDsuffix];
             [dscd appendDSCDsuffix];
             
#pragma mark request to CREATE new study
             
             studyUID=[[NSUUID UUID]ITUTX667UIDString];
             seriesUID=[[NSUUID UUID]ITUTX667UIDString];
             SOPIUID=[[NSUUID UUID]ITUTX667UIDString];
             
             
             //dicom object
             if (isDOC)
             {
                POSTencapsulatedRequest=
                [NSMutableURLRequest
                 POSTencapsulatedToPacs:pacs
                 CS:@"ISO_IR 192"
                 DA:[DICMTypes DAStringFromDate:now]
                 TM:[DICMTypes TMStringFromDate:now]
                 TZ:K.defaultTimezone
                 AN:AccessionNumber1
                 ANLocal:pacs[@"pacsaet"]
                 ANUniversal:pacs[@"custodianoid"]
                 ANUniversalType:@"ISO"
                 modality:@"DOC"
                 studyDescription:StudyDescription1
                 procedureCodes:@[]
                 referring:ReferringPhysiciansName1
                 reading:NameofPhysicianReadingStudy1
                 name:PatientName1
                 pid:PatientID1
                 issuer:IssuerOfPatientID1
                 birthdate:PatientBirthdate1
                 sex:PatientSexValue1
                 instanceUID:SOPIUID
                 seriesUID:seriesUID
                 studyUID:studyUID
                 studyID:nil
                 seriesNumber:@"-16"
                 seriesDescription:@"Informe imagenológico"
                 enclosureHL7II:CDAID
                 enclosureTitle:enclosureTextarea
                 enclosureTransferSyntax:@"1.2.840.10008.5.1.4.1.1.104.2"
                 enclosureData:[dscd dataUsingEncoding:NSUTF8StringEncoding]
                 contentType:@"application/dicom"
                 ];
             }
             else //pdf document which is not a report
             {
                POSTencapsulatedRequest=
                [NSMutableURLRequest
                 POSTencapsulatedToPacs:pacs
                 CS:@"ISO_IR 192"
                 DA:[DICMTypes DAStringFromDate:now]
                 TM:[DICMTypes TMStringFromDate:now]
                 TZ:K.defaultTimezone
                 AN:AccessionNumber1
                 ANLocal:pacs[@"pacsaet"]
                 ANUniversal:pacs[@"custodianoid"]
                 ANUniversalType:@"ISO"
                 modality:@"OT"
                 studyDescription:StudyDescription1
                 procedureCodes:@[]
                 referring:ReferringPhysiciansName1
                 reading:NameofPhysicianReadingStudy1
                 name:PatientName1
                 pid:PatientID1
                 issuer:IssuerOfPatientID1
                 birthdate:PatientBirthdate1
                 sex:PatientSexValue1
                 instanceUID:SOPIUID
                 seriesUID:seriesUID
                 studyUID:studyUID
                 studyID:nil
                 seriesNumber:@"-31"
                 seriesDescription:@"documento PDF"
                 enclosureHL7II:CDAID
                 enclosureTitle:enclosureTextarea
                 enclosureTransferSyntax:@"1.2.840.10008.5.1.4.1.1.104.2"
                 enclosureData:[dscd dataUsingEncoding:NSUTF8StringEncoding]
                 contentType:@"application/dicom"
                 ];
             }
          }
          
#pragma mark - POST request
          
          NSHTTPURLResponse *POSTencapsulatedResponse=nil;
          //URL properties: expectedContentLength, MIMEType, textEncodingName
          //HTTP properties: statusCode, allHeaderFields
          
          NSData *POSTencapsulatedResponseData=[NSURLConnection sendSynchronousRequest:POSTencapsulatedRequest returningResponse:&POSTencapsulatedResponse error:&error];
          
          NSString *POSTencapsulatedResponseString=[[NSString alloc]initWithData:POSTencapsulatedResponseData encoding:NSUTF8StringEncoding];
          LOG_INFO(@"[pdf]<cda> POST %@ (body length:%ld) <-%ld",
                   [POSTencapsulatedRequest.URL absoluteURL],
                   (long)[POSTencapsulatedRequest.HTTPBody length],
                   (long)POSTencapsulatedResponse.statusCode);
          
          if (error || POSTencapsulatedResponse.statusCode>299)
          {
             
             
             //Failure
             //=======
             //400 - Bad Request (bad syntax)
             //401 - Unauthorized
             //403 - Forbidden (insufficient priviledges)
             //409 - Conflict (formed correctly - system unable to store due to a conclict in the request
             //(e.g., unsupported SOP Class or StudyInstance UID mismatch)
             //additional information can be found in teh xml response body
             //415 - unsopported media type (e.g. not supporting JSON)
             //500 (instance already exists in db - delete file)
             //503 - Busy (out of resource)
             
             //Warning
             //=======
             //202 - Accepted (stored some - not all)
             //additional information can be found in teh xml response body
             
             //Success
             //=======
             //200 - OK (successfully stored all the instances)
             
             
             LOG_ERROR(@"[pdf]<stow dicom> can not send to pacs for patient: %@.\r\n%@\r\n%@",PatientName1,[error description], POSTencapsulatedResponseString);
             return [RSErrorResponse responseWithClientError:404 message:@"[pdf] can not send to pacs for patient: %@\r\n%@\r\n%@",PatientName1,[error description], POSTencapsulatedResponseString];
          }
          
          NSMutableString* html = [NSMutableString stringWithString:@"<html><body>"];
          [html appendFormat:@"<p>solicitud dicom cda sent to %@</p>",pacs[@"dcm4cheelocaluri"]];
          
          
#pragma mark - qido of the stow, in order to actualize metadata in pacs
          if (![NSURLSessionDataTask existsInPacs:(NSDictionary*)pacs
                                         studyUID:(NSString*)studyUID
                                        seriesUID:(NSString*)seriesUID
                                           sopUID:(NSString*)SOPIUID
                                 returnAttributes:false]) [html appendString:@"<p>qido failed</p>"];
          else
          {
             [html appendString:@"<p>qido OK</p>"];
#pragma mark - create user in html5dicom
             
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
              
              
              
              POSThtml5dicomuserRequest:(NSString*)URLString
              institution:(NSString*)institution
              username:(NSString*)username
              password:(NSString*)password
              firstname:(NSString*)firstname
              lastname:(NSString*)lastname
              isactive:(BOOL)isactive
              timeout:(NSTimeInterval)timeout
              */
             
             NSString *clave1String=nil;
             NSUInteger clave1Index=[names indexOfObject:@"clave"];
             if ((clave1Index!=NSNotFound) && [values[clave1Index] length])
                clave1String=values[clave1Index];
             
             NSMutableURLRequest *POSThtml5dicomuserRequest=[NSMutableURLRequest
                                                             POSThtml5dicomuserRequest:pacs[@"html5dicomuserserviceuri"]
                                                             institution:pacs[@"custodiantitle"]
                                                             username:PatientID1
                                                             password:clave1String
                                                             firstname:patientNames
                                                             lastname:[NSString stringWithFormat:@"%@ %@",patientFamily1, patientFamily2]
                                                             isactive:true
                                                             timeout:[pacs[@"timeoutinterval"] integerValue]
                                                             ];
             
             NSString *POSThtml5dicomuserRequestBodyString=[[NSString alloc]initWithData:POSThtml5dicomuserRequest.HTTPBody encoding:NSUTF8StringEncoding];
             
             NSHTTPURLResponse *POSThtml5dicomuserResponse=nil;
             NSData *POSThtml5dicomuserRequestResponseData=[NSURLConnection sendSynchronousRequest:POSThtml5dicomuserRequest    returningResponse:&POSThtml5dicomuserResponse error:&error];
             
             NSString *POSThtml5dicomuserRequestResponseString=[[NSString alloc]initWithData:POSThtml5dicomuserRequestResponseData encoding:NSUTF8StringEncoding];
             
             if (POSThtml5dicomuserResponse.statusCode==201) [html appendFormat:@"<p>patient %@ created in %@ %@</p>",PatientID1,pacs[@"html5dicomuserserviceuri"],POSThtml5dicomuserRequestBodyString];
             else
             {
                NSString *POSThtml5dicomuserRequestResponseString=[[NSString alloc]initWithData:POSThtml5dicomuserRequestResponseData encoding:NSUTF8StringEncoding];
                
                LOG_ERROR(@"[pdf] %@\r\n%@", POSThtml5dicomuserRequestBodyString, POSThtml5dicomuserRequestResponseString);
                
                [html appendFormat:@"<p>patient %@ NOT created in %@</p>",PatientID1,pacs[@"html5dicomuserserviceuri"]];
             }
          }
          /*
           
           // TODO create array procedureCode {code, scheme meaning, traduction}
           NSMutableArray *mutableArray=[NSMutableArray array];
           NSDictionary *standarizedSchemesCodes=(pacsProcedureDict[@"codes"])[procedureIndex];
           for (NSString *standarizedScheme in standarizedSchemesCodes)
           {
           NSString *standarizedCode=standarizedSchemesCodes[standarizedScheme];
           NSDictionary *standarizedCodeDict=(K.code[standarizedScheme])[standarizedCode];
           
           [mutableArray addObject:@{
           @"code":standarizedCode,
           @"scheme":(K.scheme[standarizedScheme])[@"dcm"],
           @"meaning":standarizedCodeDict[@"meaning"]
           }];
           
           if ([standarizedCodeDict[@"translation"] count])
           {
           // TOOD translation
           }
           }
           
           
           
           
           
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


/////////////////////////////////////////////////////////////////////////////



-(void)GETencapsulated
{
   [self addHandler:@"GET" regex:encapsulatedRegex() processBlock:
    ^(RSRequest* request, RSCompletionBlock completionBlock){completionBlock(^RSResponse* (RSRequest* request)
                                                                             {
                                                                                //LOG_DEBUG(@"client: %@",request.remoteAddressString);
                                                                                
                                                                                NSURLComponents * urlComponents=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
                                                                                
                                                                                NSArray * pathComponents=[request.URL pathComponents];
                                                                                NSString *modality=pathComponents[0];
                                                                                BOOL isDOC=[modality isEqualToString:@"DOC"];
                                                                                BOOL isOT=[modality isEqualToString:@"OT"];
                                                                                NSString * objectType=pathComponents[1];
                                                                                
                                                                                
#pragma mark params
                                                                                NSMutableArray *names=[NSMutableArray array];
                                                                                NSMutableArray *values=[NSMutableArray array];
                                                                                NSMutableArray *types=[NSMutableArray array];
                                                                                NSMutableString *jsonString=[NSMutableString string];
                                                                                NSMutableString *errorString=[NSMutableString string];
                                                                                if (!parseRequestParams(request, names, values, types, jsonString, errorString)) return [RSErrorResponse responseWithClientError:404 message:@"%@",errorString];
                                                                                
                                                                                
                                                                                NSMutableString *pacsOID=[NSMutableString string];
                                                                                NSDictionary * destPacs=pacsParam(names, values, pacsOID, errorString);
                                                                                if (!destPacs) return [RSErrorResponse responseWithClientError:404 message:@"%@",errorString];
                                                                                
                                                                                
                                                                                //find first instance of any of this identifiers
                                                                                NSString *valueAccessionNumber=nil;
                                                                                NSString *valueStudyInstanceUID=nil;
                                                                                NSString *valueSeriesInstanceUID=nil;
                                                                                NSString *valueSOPInstanceUID=nil;
                                                                                NSMutableData *qidoResponseData;
                                                                                NSArray *qidoResponseArray=nil;
                                                                                NSUInteger qidoResponseIndex=NSNotFound;
                                                                                
                                                                                for (NSURLQueryItem *qi in urlComponents.queryItems)
                                                                                {
                                                                                   NSString *key=K.key[[K.tag indexOfObject:@"qi.name"]];
                                                                                   if (!key) key=@"qi.name";
                                                                                   
                                                                                   if      (!valueAccessionNumber && [key isEqualToString:@"AccessionNumber"]) valueAccessionNumber=[NSString stringWithString:qi.value];
                                                                                   else if (!valueStudyInstanceUID && [key isEqualToString:@"StudyInstanceUID"]) valueStudyInstanceUID=[NSString stringWithString:qi.value];
                                                                                   else if (!valueSeriesInstanceUID && [key isEqualToString:@"SeriesInstanceUID"])
                                                                                      valueSeriesInstanceUID=[NSString stringWithString:qi.value];
                                                                                   else if (!valueSOPInstanceUID && [key isEqualToString:@"SOPInstanceUID"])
                                                                                      valueSOPInstanceUID=[NSString stringWithString:qi.value];
                                                                                }
                                                                                
                                                                                if (   !valueAccessionNumber
                                                                                    && !valueSeriesInstanceUID
                                                                                    && !valueSOPInstanceUID
                                                                                    && !valueStudyInstanceUID
                                                                                    ) return [RSErrorResponse responseWithClientError:404 message:@"%@ [{enclosed} AccessionNumber, Study,Series or SOP Instance UID required]",urlComponents.path];
                                                                                
                                                                                //incomplete for a wado uri
                                                                                if (   !valueStudyInstanceUID
                                                                                    || !valueSeriesInstanceUID
                                                                                    || !valueSOPInstanceUID
                                                                                    )
                                                                                {
                                                                                   //getting StudyInstanceUID, SeriesInstanceUID, SOPInstanceUID of encapsulated
                                                                                   
                                                                                   
                                                                                   //select engine
                                                                                   if ([destPacs[@"select"] isEqualToString:@"sql"])
                                                                                   {
                                                                                      /*
                                                                                       NSMutableString *sqlselect=[NSMutableString stringWithString:@" SELECT "];
                                                                                       for (NSString* key in wadouris[@"select"])
                                                                                       {
                                                                                       [sqlselect appendFormat:@"%@,",(sqlobjectmodel[@"attribute"])[key]];
                                                                                       }
                                                                                       [sqlselect deleteCharactersInRange:NSMakeRange([sqlselect length]-1,1)];
                                                                                       
                                                                                       if (valueAccessionNumber)
                                                                                       {
                                                                                       sqlScriptString=[NSString stringWithFormat:@"%@%@%@ WHERE %@='%@'\" %@",
                                                                                       destPacs[@"sqlprolog"],
                                                                                       sqlselect,
                                                                                       (sqlobjectmodel[@"from"])[@"instancesofstudy"],
                                                                                       (sqlobjectmodel[@"attribute"])[@"AccessionNumber"],
                                                                                       valueAccessionNumber,
                                                                                       wadouris[@"format"]
                                                                                       ];
                                                                                       }
                                                                                       else if (valueStudyInstanceUID)
                                                                                       {
                                                                                       sqlScriptString=[NSString stringWithFormat:@"%@%@%@ WHERE %@='%@'\" %@",
                                                                                       destPacs[@"sqlprolog"],
                                                                                       sqlselect,
                                                                                       (sqlobjectmodel[@"from"])[@"instancesofstudy"],
                                                                                       (sqlobjectmodel[@"attribute"])[@"StudyInstanceUID"],
                                                                                       valueStudyInstanceUID,
                                                                                       wadouris[@"format"]
                                                                                       ];
                                                                                       }
                                                                                       else if (valueSeriesInstanceUID)
                                                                                       {
                                                                                       sqlScriptString=[NSString stringWithFormat:@"%@%@%@ WHERE %@='%@'\" %@",
                                                                                       destPacs[@"sqlprolog"],
                                                                                       sqlselect,
                                                                                       (sqlobjectmodel[@"from"])[@"instancesofstudy"],
                                                                                       (sqlobjectmodel[@"attribute"])[@"SeriesInstanceUID"],
                                                                                       valueSeriesInstanceUID,
                                                                                       wadouris[@"format"]
                                                                                       ];
                                                                                       }
                                                                                       else return [RSErrorResponse responseWithClientError:404 message:
                                                                                       @"shouldn´t be here..."];
                                                                                       
                                                                                       
                                                                                       //NSData *instanceData=[NSData dataWithContentsOfURL:[NSURL URLWithString:wadoRsString]];
                                                                                       */
                                                                                   }
                                                                                   else if ([destPacs[@"select"] isEqualToString:@"qido"])
                                                                                   {
                                                                                      NSMutableString *qidoString=[NSMutableString stringWithFormat:@"%@/instances?Modality=%@",
                                                                                                                   destPacs[@"qido"],modality];
                                                                                      
                                                                                      if (valueStudyInstanceUID) [qidoString appendFormat:@"&StudyInstanceUID=%@",valueStudyInstanceUID];
                                                                                      
                                                                                      if (valueSeriesInstanceUID) [qidoString appendFormat:@"&SeriesInstanceUID=%@",valueSeriesInstanceUID];
                                                                                      
                                                                                      if (valueSOPInstanceUID) [qidoString appendFormat:@"&SOPInstanceUID=%@",valueSOPInstanceUID];
                                                                                      
                                                                                      if (valueAccessionNumber) [qidoString appendFormat:@"&AccessionNumber=%@",valueAccessionNumber];
                                                                                      
#pragma mark TODO replace qido url direct
                                                                                      qidoResponseData=[NSMutableData dataWithContentsOfURL:
                                                                                                        [NSURL URLWithString:qidoString]];
                                                                                      
                                                                                      
                                                                                      //applicable, latest doc
                                                                                      //6.7.1.2.3.2 JSON Results
                                                                                      //If there are no matching results,the JSON message is empty.
                                                                                      if (!qidoResponseData || ![qidoResponseData length]) [RSErrorResponse responseWithClientError:404 message:@"{encapsulated} no match"];
                                                                                      
                                                                                      //eventual conversion to UTF-8
#pragma mark TODO check if necesary
                                                                                      if ([destPacs[@"sqlstringencoding"]intValue]==5) //latin1
                                                                                      {
                                                                                         NSString *latin1String=[[NSString alloc]initWithData:qidoResponseData encoding:NSISOLatin1StringEncoding];
                                                                                         [qidoResponseData setData:[latin1String dataUsingEncoding:NSUTF8StringEncoding]];
                                                                                      }
                                                                                      
                                                                                      qidoResponseArray=[NSJSONSerialization JSONObjectWithData:qidoResponseData options:0 error:nil];
                                                                                      NSUInteger qidoResponseArrayCount=[qidoResponseArray count];
                                                                                      if (qidoResponseArrayCount==0) [RSErrorResponse responseWithClientError:404 message:@"no match"];
                                                                                      
                                                                                      //Find latest matching
                                                                                      NSDictionary *instance;
                                                                                      long date=0;
                                                                                      long time=0;
                                                                                      if (qidoResponseArrayCount==1) instance=qidoResponseArray[0];
                                                                                      else
                                                                                      {
                                                                                         for (NSInteger i=0;  i<qidoResponseArrayCount; i++)
                                                                                         {
                                                                                            NSInteger PPSSD=[(((qidoResponseArray[i])[@"00400244"])[@"Value"])[0] longValue];
                                                                                            NSInteger PPSST=[(((qidoResponseArray[i])[@"00400245"])[@"Value"])[0] longValue];
                                                                                            if ((PPSSD > date) || ((PPSSD==date)&&(PPSST>time)))
                                                                                            {
                                                                                               date=PPSSD;
                                                                                               time=PPSST;
                                                                                               qidoResponseIndex=i;
                                                                                            }
                                                                                         }
                                                                                         instance=qidoResponseArray[qidoResponseIndex];
                                                                                      }
                                                                                      
                                                                                      //parse Study, Series and SOP Instance UID from Instance dictionary
                                                                                      if (!valueStudyInstanceUID) valueStudyInstanceUID=((instance[@"0020000D"])[@"Value"])[0];
                                                                                      if (!valueSeriesInstanceUID) valueSeriesInstanceUID=((instance[@"0020000E"])[@"Value"])[0];
                                                                                      if (!valueSOPInstanceUID) valueSOPInstanceUID=((instance[@"00080018"])[@"Value"])[0];
                                                                                   }
                                                                                   else if ([destPacs[@"select"] isEqualToString:@"cfind"])
                                                                                   {
                                                                                      return [RSErrorResponse responseWithClientError:404 message:@"%@ [{encapsulted} cfind not implemented]",urlComponents.path];
                                                                                   }
                                                                                   else return [RSErrorResponse responseWithClientError:404 message:@"%@ [{encapsulated} sql or qido needed and not available]",urlComponents.path];
                                                                                   
                                                                                   
                                                                                }
                                                                                //StudyInstanceUID, SeriesInstanceUID and SOPInstanceUID were defined
                                                                                
#pragma mark request for the object
                                                                                
                                                                                NSMutableURLRequest *wadoRequest=nil;
                                                                                if ([destPacs[@"wadouri"] length])
                                                                                   wadoRequest=[NSMutableURLRequest wadouritextxml:destPacs[@"wadouri"]
                                                                                                                         studyIUID:valueStudyInstanceUID
                                                                                                                        seriesIUID:valueSeriesInstanceUID SOPIUID:valueSOPInstanceUID];
                                                                                else if ([destPacs[@"wadors"] length])
                                                                                {
                                                                                   //wadoRequest=[NSMutableURLRequest wadoursinstance:(((qidoResponseArray[qidoResponseIndex])[@"00081190"])[@"Value"])[0]]; //add header for content type and bulkdatauri
                                                                                   [RSErrorResponse responseWithClientError:404 message:@"%@ [wadors not soported]",urlComponents.path];
                                                                                }
                                                                                else return [RSErrorResponse responseWithClientError:404 message:@"%@ [wadouri needed]",urlComponents.path];
                                                                                
                                                                                
                                                                                //for both wadouri y wadors !!!
                                                                                NSHTTPURLResponse *wadoResponse=nil;
                                                                                NSError *wadoError=nil;
                                                                                NSUInteger wadoDataLength=0;
                                                                                NSData *wadoData=[NSURLConnection sendSynchronousRequest:wadoRequest
                                                                                                                       returningResponse:&wadoResponse
                                                                                                                                   error:&wadoError];
                                                                                wadoDataLength=[wadoData length];
                                                                                if ((wadoResponse.statusCode!=200) || (wadoDataLength==0))
                                                                                {
                                                                                   LOG_VERBOSE(@"[encapsulted] wado %@ unsuccessfull",urlComponents.query);
                                                                                   [RSErrorResponse responseWithClientError:404 message:@"unsuccessfull wadouri %@",urlComponents.string];
                                                                                }
                                                                                
                                                                                
                                                                                
#pragma mark format output
                                                                                if ([objectType isEqualToString:@"pdf"])
                                                                                {
                                                                                   return [RSDataResponse
                                                                                           responseWithData:wadoData
                                                                                           contentType:@"application/pdf"];
                                                                                }
                                                                                else if ([objectType isEqualToString:@"xml"])
                                                                                {
                                                                                   return [RSDataResponse
                                                                                           responseWithData:wadoData
                                                                                           contentType:@"text/xml"];
                                                                                }
                                                                                else if ([objectType isEqualToString:@"dscd"])
                                                                                {
                                                                                   
                                                                                }
                                                                                else if ([objectType isEqualToString:@"scd"])
                                                                                {
                                                                                   
                                                                                }
                                                                                else if ([objectType isEqualToString:@"cda"])
                                                                                {
                                                                                   NSRange CDAOpeningTagRange=[wadoData rangeOfData:cdaPrefixData options:0 range:NSMakeRange(0, wadoData.length)];
                                                                                   if (CDAOpeningTagRange.location != NSNotFound)
                                                                                   {
                                                                                      NSRange CDAClosingTagRange=[wadoData rangeOfData:CDAClosingTag options:0 range:NSMakeRange(0, encapsulatedData.length)];
                                                                                      NSData *cdaData=[wadoData subdataWithRange:NSMakeRange(CDAOpeningTagRange.location, CDAClosingTagRange.location+CDAClosingTagRange.length-CDAOpeningTagRange.location)];
                                                                                      return [RSDataResponse
                                                                                              responseWithData:cdaData
                                                                                              contentType:ctString];
                                                                                   }
                                                                                   
                                                                                }
                                                                                else return [RSErrorResponse responseWithClientError:404 message:@"response Content-Type '%@' not implemented",responseContentType];
                                                                             }(request));}];
   
}

                                                                             
@end
