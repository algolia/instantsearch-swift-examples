//
//  Copyright (c) 2016 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <XCTest/XCTest.h>

@import AlgoliaSearch;
@import InstantSearchCore;


/// Check Objective-C bridging.
///
/// + Note: This tests mostly **compilation** and **naming**. Behavior is already tested in Swift.
///
@interface ObjcBridgingTest : XCTestCase <SearchProgressDelegate>

@end


@implementation ObjcBridgingTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDebouncer {
    Debouncer* debouncer = [[Debouncer alloc] initWithDelay:0.1];
    [debouncer call:^{
        // Nothing to do.
    }];
}

- (void)testHighlightRenderer {
    Highlighter* renderer = [[Highlighter alloc] initWithHighlightAttrs:@{ @"foo": @"bar" }];
    renderer.preTag = @"<mark>";
    renderer.postTag = @"</mark>";
    renderer.caseSensitive = false;
    NSAttributedString* attributedString = [renderer renderText:@"Snoopy is <MARK>Woodstock</MARK>'s friend"];
    NSLog(@"%@", attributedString);
}

- (void)testSearcher {
    Client* client = [[Client alloc] initWithAppID:@"APPID" apiKey:@"APIKEY"];
    Index* index = [client indexWithName:@"INDEX_NAME"];
    Searcher* searcher = [[Searcher alloc] initWithIndex:index];
    [searcher addResultHandler:^(SearchResults* results, NSError* error, NSDictionary* userInfo) {
        // Nothing to do.
    }];
    searcher.params.query = @"text";
    [searcher search];
    XCTAssertTrue(searcher.hasPendingRequests);
    [searcher loadMore];
    [searcher cancelRequestWithSeqNo:1];
    [searcher cancelPendingRequests];
}

- (void)testSearchProgressController {
    Client* client = [[Client alloc] initWithAppID:@"APPID" apiKey:@"APIKEY"];
    Index* index = [client indexWithName:@"INDEX_NAME"];
    Searcher* searcher = [[Searcher alloc] initWithIndex:index];
    SearchProgressController* spc = [[SearchProgressController alloc] initWithSearcher:searcher];
    spc.delegate = self;
}

- (void)searchDidStart:(SearchProgressController*)spc {
    // Nothing to do.
}

- (void)searchDidStop:(SearchProgressController*)spc {
    // Nothing to do.
}

- (void)testSearchResults {
    NSDictionary<NSString*, id>* const JSON = @{
        @"hits": @[
            @{ @"foo": @"bar" }
        ],
        @"nbHits": @66,
        @"page": @1,
        @"hitsPerPage": @6,
        @"nbPages": @11,
        @"query": @"",
        @"params": @""
    };

    NSError* error = nil;
    SearchResults* results = [[SearchResults alloc] initWithContent:JSON disjunctiveFacets:@[] error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(results);
    XCTAssertEqual(66, results.nbHits);
    XCTAssertEqual(1, results.page);
    XCTAssertEqual(6, results.hitsPerPage);
    XCTAssertEqual(11, results.nbPages);
    XCTAssertEqual(0, results.processingTimeMS);
    XCTAssertEqualObjects(@"", results.query);
    XCTAssertEqualObjects([Query new], results.params);
    XCTAssertEqual(false, results.exhaustiveFacetsCount);
    XCTAssertNil(results.message);
    XCTAssertNil(results.queryAfterRemoval);
    XCTAssertNil(results.aroundLatLng);
    XCTAssertEqual(0, results.automaticRadius);
    XCTAssertNil(results.serverUsed);
    XCTAssertNil(results.parsedQuery);
    XCTAssertEqual(false, results.timeoutCounts);
    XCTAssertEqual(false, results.timeoutHits);
    XCTAssertNil([results facetsWithName:@"foo"]);
    XCTAssertNil([results facetStatsWithName:@"foo"]);
    XCTAssertNil([results highlightResultAt:0 path:@"foo"]);
    XCTAssertNil([results snippetResultAt:0 path:@"foo"]);
    XCTAssertNil([results rankingInfoAt:0]);
    XCTAssertNil([SearchResults highlightResultWithHit:JSON[@"hits"][0] path:@"foo"]);
    XCTAssertNil([SearchResults snippetResultWithHit:JSON[@"hits"][0] path:@"foo"]);
}

- (void)testSearchParameters {
    SearchParameters* queryFilters = [[SearchParameters alloc] init];

    [queryFilters clear];

    [queryFilters setFacetWithName:@"name" disjunctive:YES];
    XCTAssertTrue([queryFilters isDisjunctiveFacetWithName:@"name"]);
    [queryFilters addFacetRefinementWithName:@"name" value:@"value" inclusive:YES];
    [queryFilters removeFacetRefinementWithName:@"name" value:@"value"];
    XCTAssertFalse([queryFilters hasFacetRefinementWithName:@"name" value:@"value"]);
    XCTAssertFalse([queryFilters hasFacetRefinementsWithName:@"name"]);
    [queryFilters toggleFacetRefinementWithName:@"name" value:@"value"];
    [queryFilters clearFacetRefinements];
    [queryFilters clearFacetRefinementsWithName:@"name"];

    [queryFilters setNumericWithName:@"name" disjunctive:YES];
    XCTAssertTrue([queryFilters isDisjunctiveNumericWithName:@"name"]);
    [queryFilters addNumericRefinementWithName:@"name" op:OperatorLessThan numberValue:@3 inclusive:YES];
    [queryFilters addNumericRefinementWithName:@"name" op:OperatorLessThan intValue:3 inclusive:YES];
    [queryFilters addNumericRefinementWithName:@"name" op:OperatorLessThan doubleValue:3.0 inclusive:YES];
    [queryFilters removeNumericRefinementWithName:@"name" op:OperatorGreaterThanOrEqual value:@123.456 inclusive:NO];
    [queryFilters updateNumericRefinementWithName:@"name" op:OperatorLessThan value:@3 inclusive:YES];
  
    XCTAssertTrue([queryFilters hasNumericRefinementsWithName:@"name"]);
    [queryFilters toggleFacetRefinementWithName:@"name" value:@"value"];
    [queryFilters clearNumericRefinements];
    [queryFilters clearNumericRefinementsWithName:@"name"];
}

- (void)testThrottler {
    Throttler* throttler = [[Throttler alloc] initWithDelay:0.1];
    [throttler call:^{
        // Nothing to do.
    }];
}

@end
