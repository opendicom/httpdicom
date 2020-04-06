#import <Foundation/Foundation.h>

//? = optional (nil accepted)
//NS_ASSUME_NONNULL_BEGIN
@interface NSString(ORC)

//https://dcm4chee-arc-hl7cs.readthedocs.io/en/latest/orm/inbound.html#tab-pv1-orm-omg

//1  OrderControl (NW, XO, CA, ...)
//2  PlacerOrderNumber now (date time of the order)
//3  FillerOrderNumber (date time of the scheduled visit)

//4  OrderStatus
//http://ihewiki.wustl.edu/wiki/index.php/HL7_Tables#Order_Status
//Order status is sent by an Order Filler but not by an Order Placer.

//    http://www.hl7.eu/refactored/tab0038.html
//    https://dcm4che.atlassian.net/wiki/spaces/ee2/pages/311689217/HL7+ORM+Service+Order+Control+Operation+Mapping
      //    A=ARRIVED
      //    CA=CANCELED
//    CM=COMPLETED
//    DC=DISCONTINUED
      //    ER=ERROR
      //    HD=ON HOLD
//    IP=IN PROCESS, unspecified
      //    RP=REPLACED
      //    SC=IN PROCESS, SCHEDULED

//7  Quantity/Timing (^^^201304242036^^MEDIUM)
//http://ihewiki.wustl.edu/wiki/index.php/HL7_Tables#Quantity.2FTiming
//    S=STAT
//    A=ASAP
//    R=ROUTINE
//    P=PRE-OP
//    C=CALL-BACK
//    T=TIMING

//18 EnteringDevice ( This field may contain multiple values encoded as HL7 repeating field despite current HL7v2 not allowing multiple values for this field.)
//we define it with IP of the sender (as in sending facility MSH-4)

+(NSString*)
   orderControl   :(NSString*)ORC_1
   isrPlacerNumber:(NSString*)ORC_2
   isrFillerNumber:(NSString*)ORC_3
   reqPriority    :(NSString*)ORC_7_
   spsOrderStatus :(NSString*)ORC_5
   spsDateTime    :(NSString*)ORC_7
;

@end

//NS_ASSUME_NONNULL_END
