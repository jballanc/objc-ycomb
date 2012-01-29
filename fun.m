//
// fun.m
//
// A little fun test for interacting with static variables.
//
// © Copyright 2011 Joshua Ballanco. See COPYING for license information.
//

#import <Foundation/Foundation.h>
#import "y.h"


int main(int argc, const char *argv[])
{
  if (argc < 2) {
    printf("Usage: fun <num>\n");
    exit(1);
  }

  __block int limit = atoi(argv[1]);
  static int count = 0;

  RecurBlock count_until = YComb(^{
                                    if (count < limit) {
                                      printf("%i\n", ++count);
                                      this_block(NULL);
                                    }
                                    return;
                                  });

  printf("I can count to %d!\n", limit);
  count_until(NULL);
  return 0;
}
