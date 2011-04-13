//
//  watch.m
//
//  A simple utility that watches a file, and logs a simple message when the file has been updated.
//
//  Copyright Joshua Ballanco, 20011. See COPYING for license information.
//

#import <fcntl.h>
#import "y.h"

typedef void (^VoidBlock)(void);
dispatch_source_t watch_source(int);

dispatch_source_t
watch_source_create(int fd)
{
  dispatch_queue_t  queue  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                    fd,
                                                    DISPATCH_VNODE_RENAME | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE,
                                                    queue);
  return source;
}

int
main(int argc, const char *argv[])
{
  if (argc != 2) {
    NSLog(@"Usage: watch <filename>");
    exit(1);
  }

  const char *filename = argv[1];
  int fd = open(filename, O_EVTONLY);
  if (fd == -1) {
    NSLog(@"Couldn't find file %s", filename);
    exit(2);
  }

  dispatch_group_t watch_group = dispatch_group_create();
  __block dispatch_source_t watch_source = watch_source_create(fd);

  RecurBlock watch_file = YComb(^{
                                  NSLog(@"File %s has been modified or moved!", filename);
                                  dispatch_source_cancel(watch_source);
                                  int block_fd = 0;
                                  for (int i = 0 ; i < 10 ; i++) {
                                    block_fd = open(filename, O_EVTONLY);
                                    if (block_fd > 0)
                                      break;
                                    usleep(10);
                                  }
                                  if (block_fd <= 0) {
                                    NSLog(@"File %s can no longer be found", filename);
                                    dispatch_group_leave(watch_group);
                                    return;
                                  }

                                  watch_source = watch_source_create(block_fd);
                                  dispatch_source_set_event_handler(watch_source, (VoidBlock)this_block);
                                  dispatch_source_set_cancel_handler(watch_source, ^{ close(block_fd); });
                                  dispatch_resume(watch_source);

                                  return;
                                });

  if (watch_source)
  {
    dispatch_group_enter(watch_group);
    dispatch_source_set_event_handler(watch_source, (VoidBlock)watch_file);
    dispatch_source_set_cancel_handler(watch_source, ^{ close(fd); });
    dispatch_resume(watch_source);
  }
  else
    close(fd);

  dispatch_group_wait(watch_group, DISPATCH_TIME_FOREVER);
  return 0;
}
