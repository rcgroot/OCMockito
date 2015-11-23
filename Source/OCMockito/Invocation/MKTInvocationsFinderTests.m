//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTInvocationsFinder.h"

#import "MKTInvocationMatcher.h"

#import <OCHamcrest/OCHamcrest.h>
#import <XCTest/XCTest.h>


@interface MKTInvocationsFinderTests : XCTestCase
@end

@implementation MKTInvocationsFinderTests

- (NSInvocation *)invocationOnTarget:(id)target withSelector:(SEL)selector
{
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    return invocation;
}

- (void)testFindInvocationsInList
{
    NSArray *target = [[NSArray alloc] init];
    NSInvocation *simpleMethodInvocation = [self invocationOnTarget:target withSelector:@selector(count)];
    NSInvocation *simpleMethodInvocationTwo = [self invocationOnTarget:target withSelector:@selector(count)];
    NSInvocation *differentMethodInvocation = [self invocationOnTarget:target withSelector:@selector(lastObject)];
    NSArray *invocations = @[ simpleMethodInvocation, simpleMethodInvocationTwo, differentMethodInvocation ];
    MKTInvocationMatcher *wanted = [[MKTInvocationMatcher alloc] init];
    [wanted setExpectedInvocation:simpleMethodInvocation];

    NSArray *actual = [MKTInvocationsFinder findInvocationsInList:invocations matching:wanted];

    assertThat(actual, containsIn(@[ simpleMethodInvocation, simpleMethodInvocationTwo ]));
}

@end
