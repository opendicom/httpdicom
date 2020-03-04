#import "DRS.h"

NS_ASSUME_NONNULL_BEGIN
enum P {
   PKey,
   PID,
   PName,
   PIssuer,
   PBirthDate,
   PSex
};

@interface DRS (datatablesPatient)

+(void)datateblesPatientSql4dictionary:(NSDictionary*)d;

@end

NS_ASSUME_NONNULL_END
