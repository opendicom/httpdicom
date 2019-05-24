#import "RequestQido.h"
#import "NSMutableURLRequest+DRS.h"

/*
 Funciones de complementación del URL para casos de uso de qido frecuentes.
 El código que invoca la función recibe el resultado por modificación de NSMutableString URLString.
 La función recibe la base del URL y la complementa
 Si los otros parametros no son válidos la función vacía URLString.
 El código que invoca la función es responsable de verificar que el tamaño de URLString resultante no sea cero.
 */
void qidoUID(
             NSMutableString* URLString,
             NSString* studyUID,
             NSString* seriesUID,
             NSString* sopUID
             )
{
   if (sopUID && [sopUID length])
   {
      [URLString appendString:@"instances?SOPInstanceUID="];
      [URLString appendString:sopUID];
      
      if (seriesUID && [seriesUID length])
      {
         [URLString appendString:@"&SeriesInstanceUID="];
         [URLString appendString:seriesUID];
      }
      
      if (studyUID && [studyUID length])
      {
         [URLString appendString:@"&StudyInstanceUID="];
         [URLString appendString:studyUID];
      }

      [URLString appendString:@"&includefield=00100021"];
   }
   else if (seriesUID && [seriesUID length])
   {
      [URLString appendString:@"series?SeriesInstanceUID="];
      [URLString appendString:seriesUID];
      
      if (studyUID && [studyUID length])
      {
         [URLString appendString:@"&StudyInstanceUID="];
         [URLString appendString:studyUID];
      }
      
      [URLString appendString:@"&includefield=00100021"];
   }
   else if (studyUID && [studyUID length])
   {
      [URLString appendString:@"studies?StudyInstanceUID="];
      [URLString appendString:studyUID];
      [URLString appendString:@"&includefield=00100021"];
   }
   else //no level
   {
      [URLString setString:@""];//error to be dealt with with return nil
   }
}


void qidoAccession(
                   NSMutableString* URLString,
                   NSString* accessionNumber,
                   NSString* accessionIssuer,
                   NSString* accessionType
)
{
   if (accessionType && [accessionType length])
   {
      if (accessionIssuer && accessionNumber && [accessionIssuer length] && [accessionNumber length])
         [URLString appendFormat:@"/rs/studies?AccessionNumber=%@&00080051.00400032=%@&00080051.00400033=%@&includefield=00100021",
            accessionNumber,
            accessionIssuer,
            accessionType
         ];
      else
         [URLString setString:@""];//error to be dealt with with return nil
   }
   else if (accessionType && [accessionType length])
   {
      if (accessionNumber && [accessionNumber length])
         [URLString appendFormat:@"/rs/studies?AccessionNumber=%@&00080051.00400031=%@&includefield=00100021",
          accessionNumber,
          accessionIssuer
          ];
      else
         [URLString setString:@""];//error to be dealt with with return nil
   }
   else if (accessionNumber && [accessionNumber length])
   {
      [URLString appendFormat:@"/rs/studies?AccessionNumber=%@&includefield=00100021",
         accessionNumber
       ];
   }
   else
      [URLString setString:@""];//error to be dealt with with return nil
}

#pragma mark - qido generico

@implementation RequestQido

//full (URLString ya contiene todos los filtros
+(NSMutableURLRequest*)foundInPacs:(NSDictionary*)pacs
                         URLString:(NSMutableString*)URLString
                     fuzzymatching:(BOOL)fuzzymatching
                             limit:(unsigned int)limit
                            offset:(unsigned int)offset
                            accept:(qidoAccept)accept
{
   if (fuzzymatching) [URLString appendString:@"&fuzzymatching=true"];
   if (limit!=UINT_MAX) [URLString appendFormat:@"&limit=%d",limit];
   if (limit!=0) [URLString appendFormat:@"&offset=%d",offset];
   
   switch (accept) {
      case qidoDefault:
         return [NSMutableURLRequest
                 DRSRequestPacs:pacs
                 URLString:URLString
                 method:GET
                 ];
      case qidoJSON:
         return [NSMutableURLRequest
                 DRSRequestPacs:pacs
                 URLString:URLString
                 method:GET
                 accept:@"application/dicom+json"
                 ];
      case qidoXML:
         return [NSMutableURLRequest
                 DRSRequestPacs:pacs
                 URLString:URLString
                 method:GET
                 accept:@"multipart/related; type=\"application/dicom+xml\""
                 ];
      default:
         return nil;
   }
}

//basic (invoca full con valores por defecto para los parametros avanzados
+(NSMutableURLRequest*)foundInPacs:(NSDictionary*)pacs
                         URLString:(NSMutableString*)URLString
{
   return [RequestQido foundInPacs:pacs
                         URLString:URLString
                     fuzzymatching:false
                             limit:UINT_MAX
                            offset:0
                            accept:qidoDefault
           ];
}

#pragma mark - requests específicos

+(NSMutableURLRequest*)studiesFoundInPacs:(NSDictionary*)pacs
                          accessionNumber:(NSString*)accessionNumber
                          accessionIssuer:(NSString*)accessionIssuer
                            accessionType:(NSString*)accessionType
{
   if (!pacs[@"qido"] || ![pacs[@"qido"] length]) return nil;
   
   NSMutableString *URLString=[NSMutableString stringWithString:pacs[@"qido"]];
   qidoAccession(URLString,accessionNumber,accessionIssuer,accessionType);
   if ([URLString length])
      return [RequestQido
              foundInPacs:pacs
              URLString:URLString
              fuzzymatching:false
              limit:UINT_MAX
              offset:0
              accept:qidoDefault
              ];
   return nil;
}


+(NSMutableURLRequest*)objectsFoundInPacs:(NSDictionary*)pacs
                                 studyUID:(NSString*)studyUID
                                seriesUID:(NSString*)seriesUID
                                   sopUID:(NSString*)sopUID
{
   if (!pacs[@"qido"] || ![pacs[@"qido"] length]) return nil;

   NSMutableString *URLString=[NSMutableString stringWithString:pacs[@"qido"]];
   qidoUID(URLString,studyUID,seriesUID,sopUID);
   if ([URLString length])
      return [RequestQido
              foundInPacs:pacs
              URLString:URLString
              fuzzymatching:false
              limit:UINT_MAX
              offset:0
              accept:qidoDefault
              ];
   return nil;
}

@end
