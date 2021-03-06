#import <Foundation/Foundation.h>

//? = optional (nil accepted)
//NS_ASSUME_NONNULL_BEGIN

@interface NSString(PV1)

//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/orm/inbound.html#tab-pv1-orm-omg

// 8 ReferringDoctor patientInsuranceShortName -> studyID
//15 AmbultatoryStatus https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&ved=2ahUKEwiQv6XewNngAhU1IrkGHVjSCVYQFjABegQIAhAB&url=http%3A%2F%2Fhl7.org%2Ffhir%2Fv2%2F0009%2F&usg=AOvVaw0_dRQaKF-sg687znpQjkhq
//19 VisitNumber

+(NSString*)
   isrInsurance:(NSString*)PV1_8
   isrReferring:(NSString*)PV1_15
;

@end
//NS_ASSUME_NONNULL_END
