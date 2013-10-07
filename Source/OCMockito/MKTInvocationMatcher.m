//
//  OCMockito - MKTInvocationMatcher.m
//  Copyright 2013 Jonathan M. Reid. See LICENSE.txt
//
//  Created by: Jon Reid, http://qualitycoding.org/
//  Source: https://github.com/jonreid/OCMockito
//

#import "MKTInvocationMatcher.h"

#import "MKTCapturingMatcher.h"
#import "NSInvocation+TKAdditions.h"

#define HC_SHORTHAND
#if TARGET_OS_MAC
    #import <OCHamcrest/OCHamcrest.h>
    #import <OCHamcrest/HCWrapInMatcher.h>
#else
    #import <OCHamcrestIOS/OCHamcrestIOS.h>
    #import <OCHamcrestIOS/HCWrapInMatcher.h>
#endif


static inline BOOL typeIsObjectOrClassOrBlock(const char *type)
{
    return *type == @encode(id)[0] || *type == @encode(Class)[0];
}


@implementation MKTInvocationMatcher

- (instancetype)init
{
    self = [super init];
    if (self)
        _argumentMatchers = [[NSMutableArray alloc] init];
    return self;
}

- (void)setMatcher:(id <HCMatcher>)matcher atIndex:(NSUInteger)index
{
    if ([self.argumentMatchers count] <= index)
    {
        [self trueUpArgumentMatchersToCount:index];
        [self.argumentMatchers addObject:matcher];
    }
    else
        [self.argumentMatchers replaceObjectAtIndex:index withObject:matcher];
}

- (NSUInteger)argumentMatchersCount
{
    return [self.argumentMatchers count];
}

- (void)trueUpArgumentMatchersToCount:(NSUInteger)desiredCount
{
    NSUInteger matchersCount = [self.argumentMatchers count];
    while (matchersCount < desiredCount)
    {
        [self.argumentMatchers addObject:[NSNull null]];
        ++matchersCount;
    } 
}

- (void)setExpectedInvocation:(NSInvocation *)expectedInvocation
{
    self.expected = expectedInvocation;
    [self.expected retainArguments];

    self.numberOfArguments = [[self.expected methodSignature] numberOfArguments] - 2;
    [self trueUpArgumentMatchersToCount:self.numberOfArguments];

    NSMethodSignature *signature = [self.expected methodSignature];
    for (NSUInteger index = 0; index < self.numberOfArguments; ++index)
        [self setObjectMatcherAtArgumentIndex:index forSignature:signature];
}

- (void)setObjectMatcherAtArgumentIndex:(NSUInteger)index forSignature:(NSMethodSignature *)signature
{
    NSUInteger indexWithHiddenArgs = index + 2;
    const char *argType = [signature getArgumentTypeAtIndex:indexWithHiddenArgs];
    if (typeIsObjectOrClassOrBlock(argType))
    {
        __unsafe_unretained id arg = nil;
        [self.expected getArgument:&arg atIndex:indexWithHiddenArgs];
        [self setMatcher:[self matcherForArgument:arg] atIndex:index];
    }
}

- (id <HCMatcher>)matcherForArgument:(id)arg
{
    if (arg != nil)
        return HCWrapInMatcher(arg);
    else
        return nilValue();
}

- (BOOL)matches:(NSInvocation *)actual
{
    if ([self.expected selector] != [actual selector])
        return NO;

    NSArray *expectedArgs = [self.expected tk_arrayArguments];
    NSArray *actualArgs = [actual tk_arrayArguments];
    for (NSUInteger index = 0; index < self.numberOfArguments; ++index)
    {
        id <HCMatcher> matcher = self.argumentMatchers[index];
        if ([matcher isEqual:[NSNull null]])
            return [expectedArgs[index] isEqual:actualArgs[index]];
        else if ([self argument:actualArgs[index] isMismatchForMatcher:matcher])
            return NO;
    }
    return YES;
}

- (BOOL)argument:(id)arg isMismatchForMatcher:(id <HCMatcher>)matcher
{
    if (arg == [NSNull null])
        arg = nil;
    return ![matcher matches:arg];
}

- (void)captureArgumentsFromInvocations:(NSArray *)invocations
{
    for (NSUInteger index = 0; index < self.numberOfArguments; ++index)
    {
        id <HCMatcher> matcher = self.argumentMatchers[index];
        if ([matcher respondsToSelector:@selector(captureArgument:)])
        {
            NSUInteger indexWithHiddenArgs = index + 2;
            for (NSInvocation *inv in invocations)
            {
                __unsafe_unretained id actualArg;
                [inv getArgument:&actualArg atIndex:indexWithHiddenArgs];
                [matcher performSelector:@selector(captureArgument:) withObject:actualArg];
            }
        }
    }
}

@end
