//
//  SQLOperation.h
//  httpdicom
//
//  Created by jacquesfauquex on 20180316.
//  Copyright © 2018 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DRSOperation : NSOperation

- (void)finish;
//used internally by subclass.
//Externally, use cancel instead which sets the property .cancelled

@end
