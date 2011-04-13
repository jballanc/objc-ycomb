# y.h

A Y-combinator for Objective-C


## What is this?

A [Fixed Point Combinator](http://en.wikipedia.org/wiki/Fixed-point_combinator) is a mathematical device from lambda calculus. It is
a higher-order function that computes the fixed point of another function. The most well known fixed-point combinator is the Y-Combinator,
which has the form: Y = λf.(λx.f (x x)) (λx.f (x x))
<br/>
### Uhhh...ok... What?

Right, so practically speaking the Y-Combinator allows you to call an anonymous function (sometimes called lambdas, procs, or
blocks) recursively. This allows you to do stuff like this (where <code>this_block</code> is the means of calling the enclosing
block recursively; see [fun.m](/jballanc/objc-ycomb/blob/master/fun.m) for the full source):

    static int count = 0;
    
    RecurBlock count_until = YComb(^{
                                      if (count < limit) {
                                        printf("%i\n", ++count);
                                        this_block(NULL);
                                      }
                                      return;
                                    });
<br/>
### Um, but why do I need a Y-Combinator to do that?

Well, you don't always. In languages where symbols are late-bound, you can accomplish the same sort of thing by assigning the
anonymous function to a symbol, and then use that symbol to achieve recursion. For example, in Ruby you could do the above quite
simply:

    count = 0
    count_until = lambda do
                    if count < limit
                      puts count += 1
                      count_until.call
                    end
                  end

This is because Ruby doesn't try to figure out what <code>count_until</code> means in the body of the block until after you call
<code>count_until</code> the first time. Since symbols in Ruby are late-bound, by the time <code>count_until.call</code> is
encountered, <code>count_until</code> has a value (it's a lambda). If you tried to do something similar in Objective-C (see
[nofun.m](/jballanc/objc-ycomb/blob/master/nofun.m) for the full source):

    static int count = 0;
    
    void (^count_until)(void) = ^{
                                   if (count < limit) {
                                     printf("%i\n", ++count);
                                     count_until();
                                   }
                                   return;
                                 };

you would find, after compiling and executing it, that you get a segmentation fault. This is because Objective-C is early-bound. It
attempts to figure out what <code>count_until</code> is before <code>count_until</code> has been completely defined.

<br/>
### Great! What else can I do with this?

Well, the Y-Combinator allows you to call any block recursively. For example, you could write a factorial block like so (see
[fact.m](/jballanc/objc-ycomb/blob/master/fact.m) for the full source):

    RecurBlock factorial = YComb((NSNumber *) ^(NSNumber *val) {
                                   if([val compare: [NSNumber numberWithInt: 0]] == NSOrderedSame) {
                                     return [NSNumber numberWithInt:1];
                                   } else {
                                     NSNumber *next_val = this_block([NSNumber numberWithInt:([val intValue] - 1)]);
                                     return [NSNumber numberWithInt:([val intValue] * [next_val intValue])];
                                   }
                                 });


Because of the limitations of C/Objective-C, the form of the Y-Combinator contained in y.h only works with blocks that take one
argument. However, this argument is defined as type <code>id</code> (which is really just an Objective-C typedef for a <code>void
*</code>), so a simple way to handle multiple arguments is to use an <code>NSArray</code> or <code>NSDictionary</code> to
pack/unpack the arguments.

<br/>
### Ok, fun...but I'm a serious programmer. Can I do anything serious with this?

Why, I'm glad you asked! The motivation for creating a Y-Combinator for Objective-C originated with a useful, but somewhat
confusing, feature of [Grand Central
Dispatch](http://developer.apple.com/library/mac/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html):
VNODE dispatch sources. Let's look briefly at what these are, how they're useful, and how using a Y-Combinator in Objective-C makes
working with them ever so slightly easier.

First, dispatch sources are a means of setting a block of code to be enqueued on one of GCD's queues whenever a certain OS event
happens. There are a number of different types of dispatch sources (you can read all about them
[here](http://developer.apple.com/library/mac/#documentation/General/Conceptual/ConcurrencyProgrammingGuide/GCDWorkQueues/GCDWorkQueues.html)),
but the one we're concerned with here is the VNODE source. The VNODE dispatch source monitors a filesystem object for changes, such
as writes to the file, or renames. Seems like something you might want to do, right? Well sure...but...

There's a difficulty with using VNODE dispatch sources because of the way that most file writes happen in OS X. You see, almost
every time you *save* a file in OS X, what actually happens under the covers is that a whole new file is written in some new
location, then after that write is done, the new file is swapped, atomically, with the old file. So, for example, if you have
"foo.txt" that you're working on, then you go to save your new work, that save operation will create ".foo.txt.SOMERANDOMESTRING"
and finally swap that with "foo.txt", so that the next time you go to open "foo.txt" you'll get the new file.

Now, normally this detail of saving a file is not something you need to know about. Most of the system libraries know about it and
deal with it on their own. Unfortunately, you do need to worry about this detail if you're going to use a VNODE dispatch source.
Because dispatch sources watch *filesystem objects*, not file names, the first time somebody *saves* the file you're watching,
you'll end up watching some orphaned filesystem object instead of the file you thought you were watching.

So, if we want to watch a file using a dispatch source, we need to account for this behavior. To do this, we need to create a
dispatch source that watches for renames and deletes in addition to file writes. We then need to create a block, to use as the
handler for this source, that does the following:

  - cancels the original dispatch source (the one that would, otherwise, be watching the orphan instead of the new file)
  - creates a new dispatch source to watch the new filesystem object
  - creates a block, to use as the handler for the new dispatch source, that does the following:
    - cancels the dispatch source we just created
    - creates a new dispatch source to watch the new filesystem object
    - creates a block, to use as the handler for the new dispatch source, that does the following:
      - ...

I think you get the point. This is a prime example of where a Y-Combinator can be tremendously useful. So, if you look at
[watch.m](/jballanc/objc-ycomb/blob/master/watch.m), you'll find just that: a VNODE dispatch source that has, as its handler, a
block that can call itself recursively using the Y-Combinator so that it can monitor a file across atomic saves. You can try it out
by running "./watch foo.txt", where "foo.txt" is some file you have open in TextEdit. Now try editing the file and saving. Magic!


## The Details

### The Header File

The actual Y-Combinator is implemented as a C macro in a single header file: y.h. To use the Y-Combinator, just copy the
header into your project directory and <code>#import</code> it. That's it!

### The Type Def

Probably the most complicated part of implementing a Y-Combinator in Objective-C is getting the type signature right. To aid in
this, the header includes a typedef: <code>RecurBlock</code>. This is the type of the block created by the Y-Combinator, but you can
cast this block to another type fairly easily (<code>RecurBlock</code> is just a block that takes a single <code>id</code> argument
and returns an <code>id</code>).

### The Macro

You can use the YComb macro just like you would use a method call. Just be sure you don't do anything too tricky; this macro is not
wrapped in a <code>do {...} while(false)</code> guard.

### The Block

The argument to the macro should be a block that takes one argument. Inside this block, when you are ready to call have it call
itself recursively, use the <code>this_block</code> magic word. Actually, <code>this_block</code> is a block defined as one of the
block arguments inside the Y-Combinator. It has the type <code>RecurBlock</code>, so you might need to cast it to something else,
depending on how you're using it.

### The Caveat

You knew there had to be a catch, right?

To make the Y-Combinator work requires using <code>Block_copy</code>. <code>Block_copy</code> does an implicit
<code>Block_retain</code> which must normally be balanced by a <code>Block_release</code>. However, because of the way the
Y-Combinator works, there's no good way to keep around references to each block being copied, so there's no way to do the proper
releasing. This means that all those blocks would leak. So, the Y-Combinator **ONLY** works under Objective-C with Garbage
Collection enabled! Also, this has only been tested with clang 2.0 (from LLVM 2.9) under OS X. If you get it to work under any other
combination of OS/Compiler, please let me know and I'll add a note here.

### The Examples

This repository contains the full source of the four examples mentioned above in addition to the y.h header file. You can make all
of these by checking out the repository and running <code>make</code>, but you must have clang installed first.


## Contributing

There's not much to y.h, but if you have an idea on how it could be made better, please let me know. Specifically, I'd love it if
you could figure out how to make it work under non-GC conditions without leaking. I'm also very much open to any corrections to this
README or the examples. Finally, if you have any creative examples using the Y-Combinator, I'd love to see them!

## Copyright & License

Copyright (C) 2011 by Joshua Ballanco.

This project is released under the MIT License. See COPYING for details.
