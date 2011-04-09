//
//  y.h
//
//  A Y-combinator for Objive-C
//
//  Copyright Joshua Ballanco, 2011. See COPYING for license information.
//

#import <Foundation/Foundation.h>


typedef id (^YComb)(id);
#define RecursiveBlock(function_block) (YComb) ^(YComb f) {\
                                         return (YComb) ^(YComb x) {\
                                           return Block_copy(^(id args) {\
                                             ((YComb)f((id)x((id)x)))(args);\
                                           });\
                                         }((YComb) ^(YComb x) {\
                                           return Block_copy(^(id args) {\
                                             ((YComb)f((id)x((id)x)))(args);\
                                           });\
                                         });\
                                       }((YComb) ^(YComb this_block) {\
                                         return Block_copy(function_block);\
                                        });\
