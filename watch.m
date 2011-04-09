//
//  watch.m
//
//  A simple utility that watches a file, and logs a simple message when the file has been updated.
//
//  Copyright Joshua Ballanco, 20011. See COPYING for license information.
//

#import <dispatch/dispatch.h>
#import <fcntl.h>
#import "y.h"


int main(int argc, const char *argv[])
{
  if (argc != 2) {
    NSLog(@"Usage: watch <filename>");
    exit(1);
  }

  int fd = open(argv[1], O_EVTONLY);

  if (fd == -1) {
    NSLog(@"Couldn't find file %s", argv[1]);
    exit(2);
  }

  dispatch_queue_t  queue  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                    fd, DISPATCH_VNODE_RENAME, queue);

  __block__ NSString *filename = [[NSString alloc] initWithCString:argv[1]
                                                          encoding:NSUTF8StringEncoding];

  YComb watch_file = RecursiveBlock(^(NSString *watch_file_name) {
                     });

  if (source) {
    NSLog(@"Do something...\n");
  } else {
    close(fd);
  }

  return 0;
}
