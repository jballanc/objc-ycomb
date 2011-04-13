//
//  fact.m
//
//  A simple demonstration of using the Y-combinator to calculated the factorial of a number.
//
//  Copyright Joshua Ballanco, 2011. See COPYING for license information.
//

#import <Foundation/Foundation.h>
#import "y.h"

int main(int argc, char *argv[])
{
  NSNumber *val;
  RecurBlock factorial = YComb((NSNumber *) ^(NSNumber *val) {
                                 if([val compare: [NSNumber numberWithInt: 0]] == NSOrderedSame) {
                                   return [NSNumber numberWithInt:1];
                                 } else {
                                   NSNumber *next_val = this_block([NSNumber numberWithInt:([val intValue] - 1)]);
                                   return [NSNumber numberWithInt:([val intValue] * [next_val intValue])];
                                 }
                               });

  printf("Factorial of %s: %li\n", argv[1], [factorial([NSNumber numberWithInt:atoi(argv[1])]) longValue]);
  return 0;
}
