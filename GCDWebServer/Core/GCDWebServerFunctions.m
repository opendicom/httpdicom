#import <SystemConfiguration/SystemConfiguration.h>
#import <CommonCrypto/CommonDigest.h>

#import <ifaddrs.h>
#import <net/if.h>
#import <netdb.h>

#import "GCDWebServerPrivate.h"
#import "ODLog.h"

/*
 Copyright (c) 2012-2015, Pierre-Olivier Latour
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * The name of Pierre-Olivier Latour may not be used to endorse
 or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */



static NSDateFormatter* _dateFormatterRFC822 = nil;
static dispatch_queue_t _dateFormatterQueue = NULL;

// TODO: Handle RFC 850 and ANSI C's asctime() format
void GCDWebServerInitializeFunctions() {
  if (_dateFormatterRFC822 == nil) {
    _dateFormatterRFC822 = [[NSDateFormatter alloc] init];
    _dateFormatterRFC822.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    _dateFormatterRFC822.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    _dateFormatterRFC822.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  }
  if (_dateFormatterQueue == NULL) {
    _dateFormatterQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
  }
}

NSString* GCDWebServerNormalizeHeaderValue(NSString* value) {
  if (value) {
    NSRange range = [value rangeOfString:@";"];  // Assume part before ";" separator is case-insensitive
    if (range.location != NSNotFound) {
      value = [[[value substringToIndex:range.location] lowercaseString] stringByAppendingString:[value substringFromIndex:range.location]];
    } else {
      value = [value lowercaseString];
    }
  }
  return value;
}


NSString* GCDWebServerExtractHeaderValueParameter(NSString* value, NSString* name) {
  NSString* parameter = nil;
  NSScanner* scanner = [[NSScanner alloc] initWithString:value];
  [scanner setCaseSensitive:NO];  // Assume parameter names are case-insensitive
  NSString* string = [NSString stringWithFormat:@"%@=", name];
  if ([scanner scanUpToString:string intoString:NULL]) {
    [scanner scanString:string intoString:NULL];
    if ([scanner scanString:@"\"" intoString:NULL]) {
      [scanner scanUpToString:@"\"" intoString:&parameter];
    } else {
      [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&parameter];
    }
  }
  return parameter;
}

NSString* GCDWebServerFormatRFC822(NSDate* date) {
  __block NSString* string;
  dispatch_sync(_dateFormatterQueue, ^{
    string = [_dateFormatterRFC822 stringFromDate:date];
  });
  return string;
}


NSDictionary* GCDWebServerParseURLEncodedForm(NSString* form) {
  NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
  NSScanner* scanner = [[NSScanner alloc] initWithString:form];
  [scanner setCharactersToBeSkipped:nil];
  while (1) {
    NSString* key = nil;
    if (![scanner scanUpToString:@"=" intoString:&key] || [scanner isAtEnd]) {
      break;
    }
    [scanner setScanLocation:([scanner scanLocation] + 1)];
    
    NSString* value = nil;
    [scanner scanUpToString:@"&" intoString:&value];
    if (value == nil) {
      value = @"";
    }
    
    key = [key stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    NSString* unescapedKey = [key stringByRemovingPercentEncoding];
    value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    NSString* unescapedValue = [value stringByRemovingPercentEncoding];
    if (unescapedKey && unescapedValue) {
      [parameters setObject:unescapedValue forKey:unescapedKey];
    } else {
      LOG_WARNING(@"Failed parsing URL encoded form for key \"%@\" and value \"%@\"", key, value);
    }
    
    if ([scanner isAtEnd]) {
      break;
    }
    [scanner setScanLocation:([scanner scanLocation] + 1)];
  }
  return parameters;
}

NSString* GCDWebServerStringFromSockAddr(const struct sockaddr* addr, BOOL includeService) {
  NSString* string = nil;
  char hostBuffer[NI_MAXHOST];
  char serviceBuffer[NI_MAXSERV];
  if (getnameinfo(addr, addr->sa_len, hostBuffer, sizeof(hostBuffer), serviceBuffer, sizeof(serviceBuffer), NI_NUMERICHOST | NI_NUMERICSERV | NI_NOFQDN) >= 0) {
    string = includeService ? [NSString stringWithFormat:@"%s:%s", hostBuffer, serviceBuffer] : [NSString stringWithUTF8String:hostBuffer];
  }
  return string;
}


NSString* GCDWebServerComputeMD5Digest(NSString* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  const char* string = [[[NSString alloc] initWithFormat:format arguments:arguments] UTF8String];
  va_end(arguments);
  unsigned char md5[CC_MD5_DIGEST_LENGTH];
  CC_MD5(string, (CC_LONG)strlen(string), md5);
  char buffer[2 * CC_MD5_DIGEST_LENGTH + 1];
  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
    unsigned char byte = md5[i];
    unsigned char byteHi = (byte & 0xF0) >> 4;
    buffer[2 * i + 0] = byteHi >= 10 ? 'a' + byteHi - 10 : '0' + byteHi;
    unsigned char byteLo = byte & 0x0F;
    buffer[2 * i + 1] = byteLo >= 10 ? 'a' + byteLo - 10 : '0' + byteLo;
  }
  buffer[2 * CC_MD5_DIGEST_LENGTH] = 0;
  return [NSString stringWithUTF8String:buffer];
}
