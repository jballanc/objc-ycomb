//
// nofun.m
//
// This doesn't work. :'-(
//
// © Copyright 2011 Joshua Ballanco. See COPYING for license information.
//

#import <Foundation/Foundation.h>
#import "y.h"


int main(int argc, const char *argv[])
{
  if (argc < 2) {
    printf("Usage: nofun <num>\n");
    exit(1);
  }

  __block int limit = atoi(argv[1]);
  static int count = 0;

  void (^count_until)(void) = ^{
                                 if (count < limit) {
                                   printf("%i\n", ++count);
                                   count_until();
                                 }
                                 return;
                               };

  printf("I can count to %d!\n", limit);
  count_until();
  return 0;
}
