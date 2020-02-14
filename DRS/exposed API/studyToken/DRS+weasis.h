//
//  weasis.h
//  httpdicom
//
//  Created by jacquesfauquex on 2020-02-12.
//  Copyright © 2020 opendicom.com. All rights reserved.
//

#import "DRS.h"

NS_ASSUME_NONNULL_BEGIN

@interface DRS (weasis)

+(void)weasisSql4dictionary:(NSDictionary*)d;

@end

NS_ASSUME_NONNULL_END
