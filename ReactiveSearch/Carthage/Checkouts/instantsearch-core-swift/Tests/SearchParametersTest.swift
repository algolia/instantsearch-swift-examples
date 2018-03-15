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

@testable import InstantSearchCore
import Foundation
import XCTest


class SearchParametersTest: XCTestCase {
    
    func testCopy() {
        let params1 = SearchParameters()
        params1.addFacetRefinement(name: "foo", value: "bar")
        let params2 = SearchParameters(from: params1)
        XCTAssertEqual(params1, params2)
        params2.addFacetRefinement(name: "foo", value: "baz")
        XCTAssertNotEqual(params1, params2)
    }
    
    func testEquality() {
        let params1 = SearchParameters()
        params1.addFacetRefinement(name: "foo", value: "bar")
        let params2 = SearchParameters()
        params2.addFacetRefinement(name: "foo", value: "bar")
        XCTAssertEqual(params1, params2)
    }
    
    func testFacetFilters() {
        let params = SearchParameters()
        
        // Empty params should produce empty string.
        XCTAssertNil(params.buildFilters())
        XCTAssertNil(params.buildFiltersFromFacets())
        
        // One conjunctive facet with one refinement.
        params.addFacetRefinement(name: "foo", value: "bar1")
        XCTAssertEqual(params.buildFilters(), "\"foo\":\"bar1\"")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromFacets())
        
        // One conjunctive facet with two refinements.
        params.addFacetRefinement(name: "foo", value: "bar2")
        XCTAssertEqual(params.buildFilters(), "\"foo\":\"bar1\" AND \"foo\":\"bar2\"")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromFacets())
        
        // Two conjunctive facets with one refinement.
        params.removeFacetRefinement(name: "foo", value: "bar1")
        params.addFacetRefinement(name: "abc", value: "xyz")
        XCTAssertEqual(params.buildFilters(), "\"abc\":\"xyz\" AND \"foo\":\"bar2\"")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromFacets())
        
        // Two conjunctive facets with two refinements (one negated).
        params.addFacetRefinement(name: "foo", value: "bar3")
        params.addFacetRefinement(name: "abc", value: "tuv", inclusive: false)
        XCTAssertEqual(params.buildFilters(), "\"abc\":\"xyz\" AND NOT \"abc\":\"tuv\" AND \"foo\":\"bar2\" AND \"foo\":\"bar3\"")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromFacets())
        
        // One conjunctive facet and one disjunctive facet.
        params.setFacet(withName: "abc", disjunctive: true)
        XCTAssertEqual(params.buildFilters(), "(\"abc\":\"xyz\" OR NOT \"abc\":\"tuv\") AND \"foo\":\"bar2\" AND \"foo\":\"bar3\"")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromFacets())
        
        // Two disjunctive facets.
        params.setFacet(withName: "foo", disjunctive: true)
        XCTAssertEqual(params.buildFilters(), "(\"abc\":\"xyz\" OR NOT \"abc\":\"tuv\") AND (\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromFacets())
        
        // Disjunctive facet with only one refinement.
        params.removeFacetRefinement(name: "abc", value: "tuv")
        XCTAssertEqual(params.buildFilters(), "(\"abc\":\"xyz\") AND (\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromFacets())
        
        // Remove all refinements: facet should disappear from params.
        params.removeFacetRefinement(name: "abc", value: "xyz")
        XCTAssertEqual(params.buildFilters(), "(\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromFacets())
        params.clearFacetRefinements(name: "foo")
        XCTAssertNil(params.buildFilters())
        XCTAssertNil(params.buildFiltersFromFacets())
    }
    
    func testFacetExistence() {
        let params = SearchParameters()
        XCTAssertFalse(params.hasRefinements())
        XCTAssertFalse(params.hasFacetRefinements())
        XCTAssertFalse(params.hasFacetRefinements(name: "foo"))
        
        params.addFacetRefinement(name: "foo", value: "xxx")
        XCTAssertTrue(params.hasRefinements())
        XCTAssertTrue(params.hasFacetRefinements())
        XCTAssertTrue(params.hasFacetRefinements(name: "foo"))
        XCTAssertFalse(params.hasFacetRefinements(name: "bar"))
        XCTAssertTrue(params.hasFacetRefinement(name: "foo", value: "xxx"))
        XCTAssertFalse(params.hasFacetRefinement(name: "foo", value: "yyy"))
        XCTAssertFalse(params.hasFacetRefinement(name: "bar", value: "baz"))
        
        params.toggleFacetRefinement(name: "foo", value: "xxx")
        XCTAssertFalse(params.hasRefinements())
        XCTAssertFalse(params.hasFacetRefinements())
        XCTAssertFalse(params.hasFacetRefinements(name: "foo"))
        XCTAssertFalse(params.hasFacetRefinement(name: "foo", value: "xxx"))
        
        params.toggleFacetRefinement(name: "bar", value: "baz")
        XCTAssertTrue(params.hasRefinements())
        XCTAssertTrue(params.hasFacetRefinements())
        XCTAssertTrue(params.hasFacetRefinements(name: "bar"))
        XCTAssertTrue(params.hasFacetRefinement(name: "bar", value: "baz"))
    }
    
    func testNumericFilters() {
        let params = SearchParameters()
        
        // Empty params should produce empty string.
        XCTAssertNil(params.buildFilters())
        XCTAssertNil(params.buildFiltersFromNumerics())
        
        // One conjunctive numeric with one refinement.
        params.addNumericRefinement("foo", .greaterThanOrEqual, 2)
        XCTAssertEqual(params.buildFilters(), "\"foo\" >= 2")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())

        // One conjunctive numeric with two refinements.
        params.addNumericRefinement("foo", .lessThan, 3.0)
        XCTAssertEqual(params.buildFilters(), "\"foo\" >= 2 AND \"foo\" < 3")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())
        
        // Update One conjunctive numeric with 2 refinements.
        params.updateNumericRefinement("foo", .greaterThanOrEqual, 3)
        params.updateNumericRefinement("foo", .lessThan, 4.0)
        XCTAssertEqual(params.buildFilters(), "\"foo\" >= 3 AND \"foo\" < 4")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())
        
        // Two conjunctive numeric with one refinement.
        params.removeNumericRefinement(NumericRefinement("foo", .greaterThanOrEqual, 3.0))
        params.addNumericRefinement(NumericRefinement("bar", .greaterThan, 456.789))
        XCTAssertEqual(params.buildFilters(), "\"bar\" > 456.789 AND \"foo\" < 4")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())
        
        // Two conjunctive numerics with two refinements (one negated).
        params.addNumericRefinement("foo", .notEqual, 0)
        params.addNumericRefinement("bar", .equal, 0, inclusive: false)
        XCTAssertEqual(params.buildFilters(), "\"bar\" > 456.789 AND NOT \"bar\" = 0 AND \"foo\" < 4 AND \"foo\" != 0")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())
        
        // One conjunctive numeric and one disjunctive.
        params.setNumeric(withName: "foo", disjunctive: true)
        XCTAssertEqual(params.buildFilters(), "\"bar\" > 456.789 AND NOT \"bar\" = 0 AND (\"foo\" < 4 OR \"foo\" != 0)")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())
        
        // Two disjunctive numeric.
        params.setNumeric(withName: "bar", disjunctive: true)
        XCTAssertEqual(params.buildFilters(), "(\"bar\" > 456.789 OR NOT \"bar\" = 0) AND (\"foo\" < 4 OR \"foo\" != 0)")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())
        
        // Disjunctive numeric with only one refinement.
        params.removeNumericRefinement("foo", .lessThan, 4)
        XCTAssertEqual(params.buildFilters(), "(\"bar\" > 456.789 OR NOT \"bar\" = 0) AND (\"foo\" != 0)")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())
        
        // Remove all refinements: numerics should disappear from params.
        params.removeNumericRefinement("foo", .notEqual, 0.0)
        XCTAssertEqual(params.buildFilters(), "(\"bar\" > 456.789 OR NOT \"bar\" = 0)")
        XCTAssertEqual(params.buildFilters(), params.buildFiltersFromNumerics())
        params.clearNumericRefinements(name: "bar")
        XCTAssertNil(params.buildFilters())
        XCTAssertNil(params.buildFiltersFromNumerics())
    }
    
    func testBooleanNumeric() {
        // Boolean numeric params should use numeric values 0 and 1.
        let params = SearchParameters()
        params.addNumericRefinement("boolean", .equal, false)
        XCTAssertEqual(params.buildFilters(), "\"boolean\" = 0")
        params.clear()
        params.addNumericRefinement("boolean", .equal, true)
        XCTAssertEqual(params.buildFilters(), "\"boolean\" = 1")
    }

    func testNumericExistence() {
        let params = SearchParameters()
        XCTAssertFalse(params.hasRefinements())
        XCTAssertFalse(params.hasNumericRefinements())
        XCTAssertFalse(params.hasNumericRefinements(name: "foo"))
        
        params.addNumericRefinement("foo", .greaterThan, -1)
        XCTAssertTrue(params.hasRefinements())
        XCTAssertTrue(params.hasNumericRefinements())
        XCTAssertTrue(params.hasNumericRefinements(name: "foo"))
        XCTAssertFalse(params.hasNumericRefinements(name: "bar"))
        
        params.updateNumericRefinement("foo", .greaterThan, 5)
        params.updateNumericRefinement("baz", .greaterThan, 3)
        XCTAssertTrue(params.hasRefinements())
        XCTAssertTrue(params.hasNumericRefinements())
        XCTAssertTrue(params.hasNumericRefinements(name: "foo"))
        XCTAssertTrue(params.hasNumericRefinements(name: "baz"))
        XCTAssertFalse(params.hasNumericRefinements(name: "bar"))
        
        params.removeNumericRefinement("foo", .greaterThan, 5)
        params.removeNumericRefinements(where: { $0.name == "baz" })
        XCTAssertFalse(params.hasRefinements())
        XCTAssertFalse(params.hasNumericRefinements())
        XCTAssertFalse(params.hasNumericRefinements())
        XCTAssertFalse(params.hasNumericRefinements(name: "foo"))
    }
    
    /// Test combining facet refinements and numeric refinements.
    ///
    func testFacetAndNumeric() {
        let params = SearchParameters()
        params.addNumericRefinement("foo", .greaterThanOrEqual, 123)
        params.addFacetRefinement(name: "abc", value: "something")
        params.addNumericRefinement("bar", .lessThan, 456.789)
        params.addFacetRefinement(name: "xyz", value: "other")
        XCTAssertEqual(params.buildFilters(), "\"abc\":\"something\" AND \"xyz\":\"other\" AND \"bar\" < 456.789 AND \"foo\" >= 123")
        XCTAssertEqual(params.buildFiltersFromFacets(), "\"abc\":\"something\" AND \"xyz\":\"other\"")
        XCTAssertEqual(params.buildFiltersFromNumerics(), "\"bar\" < 456.789 AND \"foo\" >= 123")

        let params2 = SearchParameters(from: params)
        params2.clearNumericRefinements()
        XCTAssertEqual(params2.buildFilters(), "\"abc\":\"something\" AND \"xyz\":\"other\"")
        XCTAssertEqual(params2.buildFiltersFromFacets(), "\"abc\":\"something\" AND \"xyz\":\"other\"")
        XCTAssertNil(params2.buildFiltersFromNumerics())

        let params3 = SearchParameters(from: params)
        params3.clearFacetRefinements()
        XCTAssertEqual(params3.buildFilters(), "\"bar\" < 456.789 AND \"foo\" >= 123")
        XCTAssertEqual(params3.buildFiltersFromNumerics(), "\"bar\" < 456.789 AND \"foo\" >= 123")
        XCTAssertNil(params3.buildFiltersFromFacets())
    }
    
    /// Test updating parameters in place.
    ///
    func testUpdate() {
        let params = SearchParameters()
        params.addNumericRefinement("foo", .greaterThanOrEqual, 123)
        params.addFacetRefinement(name: "abc", value: "something")
        params.addNumericRefinement("bar", .lessThan, 456.789)
        params.addFacetRefinement(name: "xyz", value: "other")
        params.update()
        XCTAssertEqual(params["filters"], "\"abc\":\"something\" AND \"xyz\":\"other\" AND \"bar\" < 456.789 AND \"foo\" >= 123")
        params.updateFromFacets()
        XCTAssertEqual(params["filters"], "\"abc\":\"something\" AND \"xyz\":\"other\"")
        params.updateFromNumerics()
        XCTAssertEqual(params["filters"], "\"bar\" < 456.789 AND \"foo\" >= 123")
        
        let params2 = SearchParameters(from: params)
        params2.clearNumericRefinements()
        params2.update()
        XCTAssertEqual(params2["filters"], "\"abc\":\"something\" AND \"xyz\":\"other\"")
        params2.updateFromFacets()
        XCTAssertEqual(params2["filters"], "\"abc\":\"something\" AND \"xyz\":\"other\"")
        params2.updateFromNumerics()
        XCTAssertNil(params2["filters"])
        
        let params3 = SearchParameters(from: params)
        params3.clearFacetRefinements()
        params3.update()
        XCTAssertEqual(params3["filters"], "\"bar\" < 456.789 AND \"foo\" >= 123")
        params3.updateFromFacets()
        XCTAssertNil(params3["filters"])
        params3.updateFromNumerics()
        XCTAssertEqual(params3["filters"], "\"bar\" < 456.789 AND \"foo\" >= 123")
    }

    /// Test interaction of params with other search parameters.
    ///
    func testOtherParams() {
        let params = SearchParameters()
        
        // Other parameters alone.
        params.query = "text"
        params.removeWordsIfNoResults = .allOptional
        XCTAssertEqual(params.build(), "query=text&removeWordsIfNoResults=allOptional")
        
        // Other parameters plus filters.
        params.addNumericRefinement("foo", .lessThanOrEqual, 666.67)
        params.addFacetRefinement(name: "bar", value: "baz")
        XCTAssertEqual(params.build(), "filters=%22bar%22:%22baz%22%20AND%20%22foo%22%20%3C%3D%20666.67&query=text&removeWordsIfNoResults=allOptional")
        
        // Check that the `filters` parameter is ignored...
        params.filters = "whatever"
        XCTAssertEqual(params.build(), "filters=%22bar%22:%22baz%22%20AND%20%22foo%22%20%3C%3D%20666.67&query=text&removeWordsIfNoResults=allOptional")
    }
}
