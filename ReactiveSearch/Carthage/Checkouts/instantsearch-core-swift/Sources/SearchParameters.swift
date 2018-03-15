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

import AlgoliaSearch
import Foundation


/// A refinement of a facet.
///
@objc public class FacetRefinement: NSObject {
    // MARK: Properties
    
    /// Name of the facet.
    @objc public var name: String
    
    /// Value for the facet.
    @objc public var value: String
    
    /// Whether the refinement is inclusive (default) or exclusive (value prefixed with a dash).
    @objc public var inclusive: Bool = true
    
    // MARK: Initialization

    @objc public init(name: String, value: String, inclusive: Bool = true) {
        self.name = name
        self.value = value
        self.inclusive = inclusive
    }

    @objc public init(copy: FacetRefinement) {
        self.name = copy.name
        self.value = copy.value
        self.inclusive = copy.inclusive
    }
    
    // MARK: Debug
    
    override public var description: String {
        return "FacetRefinement{\(buildFilter())}"
    }
    
    // MARK: Equatable
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? FacetRefinement else {
            return false
        }
        return self.name == rhs.name
            && self.value == rhs.value
            && self.inclusive == rhs.inclusive
    }

    // MARK: Methods

    /// Build a facet filter corresponding to this refinement.
    ///
    /// + Deprecated: Please use `buildFilter()` instead.
    ///
    /// - returns: A string suitable for use in `Query.facetFilters`.
    ///
    @objc public func buildFacetFilter() -> String {
        return "\(name):\(buildFacetRefinement())"
    }
    
    /// Build a facet refinement corresponding to this value.
    ///
    /// - returns: A string suitable for use in `Index.searchDisjunctiveFaceting(...)`.
    ///
    @objc public func buildFacetRefinement() -> String {
        return inclusive ? value : "-" + value
    }
    
    /// Build a filter corresponding to this refinement.
    ///
    /// - returns: An expression suitable for use in `Query.filters`.
    ///
    @objc public func buildFilter() -> String {
        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
        let filter = "\"\(escapedName)\":\"\(escapedValue)\""
        return inclusive ? filter : "NOT " + filter
    }
}


/// A refinement on a numeric attribute.
///
@objc public class NumericRefinement: NSObject {
    // MARK: Types
    
    /// Comparison operator that can be applied to a numeric.
    @objc public enum Operator: Int {
        case lessThan
        case lessThanOrEqual
        case equal
        case notEqual
        case greaterThanOrEqual
        case greaterThan
        
        internal func toString() -> String {
            switch self {
            case .lessThan: return "<"
            case .lessThanOrEqual: return "<="
            case .equal: return "="
            case .notEqual: return "!="
            case .greaterThanOrEqual: return ">="
            case .greaterThan: return ">"
            }
        }
    }
    
    // MARK: Properties
    
    /// Name of the attribute to filter.
    @objc public var name: String
    
    /// Operator to apply on the attribute.
    @objc public var op: Operator
    
    /// Value to compare the attribute to.
    @objc public var value: NSNumber
    
    /// Whether the filter is inclusive (the default) or exclusive (negated with a `NOT`).
    @objc public var inclusive: Bool = true
    
    // MARK: Initialization

    /// Create a numeric refinement with the specified operator and operands.
    ///
    /// - parameter name: Name of the attribute to filter (first operand).
    /// - parameter op: Comparison operator to apply.
    /// - parameter value: Value to compare the attribute to (second operand).
    /// - parameter inclusive: Whether the filter is inclusive (the default) or exclusive (negated with a `NOT`).
    ///
    @objc(initWithName:operator:numberValue:inclusive:)
    public init(_ name: String, _ op: Operator, _ value: NSNumber, inclusive: Bool = true) {
        self.name = name
        self.op = op
        self.value = value
        self.inclusive = inclusive
    }
    
    /// Create a numeric refinement with the specified operator and operands.
    ///
    /// - parameter name: Name of the attribute to filter (first operand).
    /// - parameter op: Comparison operator to apply.
    /// - parameter value: Value to compare the attribute to (second operand).
    /// - parameter inclusive: Whether the filter is inclusive (the default) or exclusive (negated with a `NOT`).
    ///
    @objc(initWithName:operator:intValue:inclusive:)
    public convenience init(_ name: String, _ op: Operator, _ value: Int, inclusive: Bool = true) {
        self.init(name, op, NSNumber(value: value), inclusive: inclusive)
    }
    
    /// Create a numeric refinement with the specified operator and operands.
    ///
    /// - parameter name: Name of the attribute to filter (first operand).
    /// - parameter op: Comparison operator to apply.
    /// - parameter value: Value to compare the attribute to (second operand).
    /// - parameter inclusive: Whether the filter is inclusive (the default) or exclusive (negated with a `NOT`).
    ///
    @objc(initWithName:operator:doubleValue:inclusive:)
    public convenience init(_ name: String, _ op: Operator, _ value: Double, inclusive: Bool = true) {
        self.init(name, op, NSNumber(value: value), inclusive: inclusive)
    }
    
    /// Create a copy of a numeric refinement.
    ///
    /// - parameter copy: Numeric refinement to copy.
    ///
    @objc public init(copy: NumericRefinement) {
        self.name = copy.name
        self.value = copy.value
        self.op = copy.op
        self.inclusive = copy.inclusive
    }
    
    // MARK: Debug
    
    override public var description: String {
        return "NumericRefinement{\(buildFilter())}"
    }
    
    // MARK: Equatable
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? NumericRefinement else {
            return false
        }
        return self.name == rhs.name
            && self.op == rhs.op
            && self.value == rhs.value
            && self.inclusive == rhs.inclusive
    }
    
    // MARK: Methods
    
    /// Build a numeric filter corresponding to this refinement.
    ///
    /// + Deprecated: Please use `buildFilter()` instead.
    ///
    /// - returns: A string suitable for use in `Query.numericFilters`.
    ///
    @objc public func buildNumericFilter() -> String {
        return "\(name) \(op.toString()) \(value))"
    }
    
    /// Build a filter corresponding to this refinement.
    ///
    /// - returns: An expression suitable for use in `Query.filters`.
    ///
    @objc public func buildFilter() -> String {
        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let filter = "\"\(escapedName)\" \(op.toString()) \(value)"
        return inclusive ? filter : "NOT " + filter
    }
}


/// A high-level representation of a query's filter.
///
/// This class allows manipulating facet and numeric filters individually, then combining them into a string
/// suitable for use in `Query.filters`.
///
/// + Note: Tags are not handled. Please use facets instead, as they are more powerful.
///
@objc public class SearchParameters: Query {
    // MARK: - Properties
    
    /// Facets that will be treated as disjunctive.
    @objc public private(set) var disjunctiveFacets: Set<String>

    /// Facet refinements. Maps facet names to a list of refined values.
    /// The format is the same as `Index.searchDisjunctiveFaceting()`.
    ///
    @objc public private(set) var facetRefinements: [String: [FacetRefinement]] {
        didSet {
            notifyRefinementChanges()
        }
    }
    
    /// Numeric attributes that will be treated as disjunctive.
    @objc public private(set) var disjunctiveNumerics: Set<String>
    
    /// Numeric filters. Maps attribute names to a list of filters.
    @objc public private(set) var numericRefinements: [String: [NumericRefinement]] {
        didSet {
            notifyRefinementChanges()
        }
    }

    // MARK: - Initialization
    
    /// Create new, empty search parameters.
    ///
    @objc public override init() {
        self.disjunctiveFacets = Set<String>()
        self.disjunctiveNumerics = Set<String>()
        self.facetRefinements = [:]
        self.numericRefinements = [:]
        super.init()
    }

    /// Create a copy of given search parameters.
    ///
    /// - parameter copy: The parameters to copy from.
    ///
    @objc public init(from copy: SearchParameters) {
        self.disjunctiveFacets = copy.disjunctiveFacets
        self.disjunctiveNumerics = copy.disjunctiveNumerics
        // Deep copy the facet refinements.
        // TODO: Maybe there is an easier way to do it?
        var newFacetRefinements = [String: [FacetRefinement]]()
        for (facetName, refinements) in copy.facetRefinements {
            var newRefinements = [FacetRefinement]()
            for refinement in refinements {
                newRefinements.append(FacetRefinement(copy: refinement))
            }
            newFacetRefinements[facetName] = newRefinements
        }
        self.facetRefinements = newFacetRefinements
        // Deep copy the numeric filters.
        var newNumericFilters = [String: [NumericRefinement]]()
        for (attributeName, filters) in copy.numericRefinements {
            var newFilters = [NumericRefinement]()
            for filter in filters {
                newFilters.append(NumericRefinement(copy: filter))
            }
            newNumericFilters[attributeName] = newFilters
        }
        self.numericRefinements = newNumericFilters
        super.init(parameters: copy.parameters)
    }
    
    /// Support for `NSCopying`.
    ///
    /// + Note: Primarily intended for Objective-C use. Swift coders should use `init(from:)`.
    ///
    @objc override open func copy(with zone: NSZone?) -> Any {
        // NOTE: As per the docs, the zone argument is ignored.
        return SearchParameters(from: self)
    }
    
    // MARK: - Global state management
    
    /// Reset to an empty state.
    ///
    @objc override open func clear() {
        super.clear()
        clearRefinements()
    }

    /// Clear all facet and numeric refinements.
    ///
    @objc public func clearRefinements() {
        clearFacetRefinements()
        clearNumericRefinements()
    }

    /// Test whether at least one refinement (facet or numeric) is defined.
    ///
    /// - returns: true if at least one facet or one numeric refinement is defined, false otherwise.
    ///
    @objc public func hasRefinements() -> Bool {
        return hasFacetRefinements() || hasNumericRefinements()
    }
    
    // MARK: - Equatable
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? SearchParameters else {
            return false
        }
        if !super.isEqual(object) {
            return false
        }
        if self.disjunctiveFacets != rhs.disjunctiveFacets || self.disjunctiveNumerics != rhs.disjunctiveNumerics {
            return false
        }
        // Compare facet refinements.
        let lhsFacets = Array(self.facetRefinements.keys)
        let rhsFacets = Array(rhs.facetRefinements.keys)
        if lhsFacets != rhsFacets {
            return false
        }
        for facetName in lhsFacets {
            if self.facetRefinements[facetName]! != rhs.facetRefinements[facetName]! {
                return false
            }
        }
        // Compare numeric filters.
        let lhsFilters = Array(self.numericRefinements.keys)
        let rhsFilters = Array(rhs.numericRefinements.keys)
        if lhsFilters != rhsFilters {
            return false
        }
        for attributeName in lhsFilters {
            if self.numericRefinements[attributeName]! != rhs.numericRefinements[attributeName]! {
                return false
            }
        }
        return true
    }

    // MARK: - Generate filters
    
    /// Build a URL query string from the current parameters, including numeric and facet refinements.
    ///
    /// - returns: A URL query string.
    ///
    @objc override open func build() -> String {
        var parameters = self.parameters
        parameters["filters"] = buildFilters()
        return AbstractQuery.build(parameters: parameters)
    }
    
    /// Generate a filter expression from the current refinements.
    /// This will combine numeric refinements and facet refinements into the same expression.
    ///
    /// - returns: An expression suitable for use with `Query.filters`. The expression may be `nil` if no refinements
    ///            are currently set.
    ///
    @objc public func buildFilters() -> String? {
        if !hasRefinements() {
            return nil
        }
        let facetExpression = buildFiltersFromFacets()
        let numericExpression = buildFiltersFromNumerics()
        if let facetExpression = facetExpression {
            if let numericExpression = numericExpression {
                return facetExpression + " AND " + numericExpression
            } else {
                return facetExpression
            }
        } else if let numericExpression = numericExpression {
            return numericExpression
        } else {
            assert(false) // should not happen, as per above
            return nil
        }
    }
    
    /// Generate a filter expression from the current numeric refinements.
    ///
    /// - returns: An expression suitable for use with `Query.filters`. The expression may be `nil` if no numeric
    ///            refinements are currently set.
    ///
    @objc public func buildFiltersFromNumerics() -> String? {
        if (!hasNumericRefinements()) {
            return nil
        }
        // NOTE: We sort attribute names to get predictable output.
        let expression = numericRefinements.keys.sorted().flatMap({ (attributeName: String) -> String? in
            let filters = self.numericRefinements[attributeName]!
            if filters.isEmpty {
                return nil
            }
            if self.isDisjunctiveNumeric(name: attributeName) {
                let innerFilters = filters.map({ return $0.buildFilter() }).joined(separator: " OR ")
                return "(\(innerFilters))"
            } else {
                return filters.map({ return $0.buildFilter() }).joined(separator: " AND ")
            }
        }).joined(separator: " AND ")
        assert(!expression.isEmpty)
        return expression
    }

    /// Generate a filter expression from the current facet refinements.
    ///
    /// - returns: An expression suitable for use with `Query.filters`. The expression may be `nil` if no facet
    ///            refinements are currently set.
    ///
    @objc public func buildFiltersFromFacets() -> String? {
        if (!hasFacetRefinements()) {
            return nil
        }
        // NOTE: We sort attribute names to get predictable output.
        let expression = facetRefinements.keys.sorted().flatMap({ (facetName: String) -> String? in
            let refinements = self.facetRefinements[facetName]!
            if refinements.isEmpty {
                return nil
            }
            if self.isDisjunctiveFacet(name: facetName) {
                let innerFilters = refinements.map({ return $0.buildFilter() }).joined(separator: " OR ")
                return "(\(innerFilters))"
            } else {
                return refinements.map({ return $0.buildFilter() }).joined(separator: " AND ")
            }
        }).joined(separator: " AND ")
        assert(!expression.isEmpty)
        return expression
    }
    
    /// Generate facet refinements from the current filters.
    ///
    /// + Note: Those are intended for use with `Index.searchDisjunctiveFaceting(...)`. In the general case, please
    ///   use `buildFilters()` instead.
    ///
    /// - returns: Facet refinements suitable for use with `Index.searchDisjunctiveFaceting(...)`.
    ///
    @objc public func buildFacetRefinements() -> [String: [String]] {
        var stringRefinements = [String: [String]]()
        for (facetName, refinements) in facetRefinements {
            stringRefinements[facetName] = refinements.map({ $0.buildFacetRefinement() })
        }
        return stringRefinements
    }
    
    /// Generate facet filters from the current filters.
    ///
    /// + Note: Those are intended for use with `Query.facetFilters`. In the general case, please use
    ///   `buildFiltersFromNumerics()` instead.
    ///
    /// - returns: An expression suitable for use with `Query.facetFilters`.
    ///
    @objc public func buildFacetFilters() -> [Any] {
        var facetFilters = [Any]()
        for (facetName, refinements) in facetRefinements {
            if isDisjunctiveFacet(name: facetName) {
                var innerFacetFilters = [Any]()
                for refinement in refinements {
                    innerFacetFilters.append(refinement.buildFacetFilter())
                }
                facetFilters.append(innerFacetFilters)
            } else {
                for refinement in refinements {
                    facetFilters.append(refinement.buildFacetFilter())
                }
            }
        }
        return facetFilters
    }
    
    // MARK: - Update filters in place

    /// Update the parameters from the current refinements.
    ///
    /// + Warning: This will override the `filters` parameter.
    ///
    @objc public func update() {
        self["filters"] = buildFilters()
    }
    
    /// Update the parameters from the current *facet* refinements. Numeric refinements are ignored.
    ///
    /// + Warning: This will override the `filters` parameter.
    ///
    @objc public func updateFromFacets() {
        self["filters"] = buildFiltersFromFacets()
    }
    
    /// Update the parameters from the current *numeric* refinements. Facet refinements are ignored.
    ///
    /// + Warning: This will override the `filters` parameter.
    ///
    @objc public func updateFromNumerics() {
        self["filters"] = buildFiltersFromNumerics()
    }
    
    // MARK: - Facets
    
    /// Set a given facet as disjunctive or conjunctive.
    ///
    /// - parameter name: The facet's name.
    /// - parameter disjunctive: true to treat this facet as disjunctive (`OR`), false to treat it as conjunctive
    ///   (`AND`, the default).
    ///
    @objc public func setFacet(withName name: String, disjunctive: Bool) {
        if disjunctive {
            disjunctiveFacets.insert(name)
        } else {
            disjunctiveFacets.remove(name)
        }
    }
    
    /// Test whether a given facet is disjunctive or conjunctive.
    ///
    /// - parameter name: The facet's name.
    /// - returns: true if this facet is disjunctive (`OR`), false if it's conjunctive (`AND`).
    ///
    @objc public func isDisjunctiveFacet(name: String) -> Bool {
        return disjunctiveFacets.contains(name)
    }
    
    /// Add a refinement for a given facet.
    /// The refinement will be treated as conjunctive (`AND`) or disjunctive (`OR`) based on the facet's own
    /// disjunctive/conjunctive status.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to add.
    ///
    @objc public func addFacetRefinement(name: String, value: String, inclusive: Bool = true) {
        if facetRefinements[name] == nil {
            facetRefinements[name] = [FacetRefinement(name: name, value: value, inclusive: inclusive)]
        } else {
            facetRefinements[name]!.append(FacetRefinement(name: name, value: value, inclusive: inclusive))
        }
    }
    
    /// Remove a refinement for a given facet.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to remove.
    ///
    @objc public func removeFacetRefinement(name: String, value: String) {
        if let index = facetRefinements[name]?.index(where: { $0.name == name && $0.value == value }) {
            facetRefinements[name]!.remove(at: index)
            if facetRefinements[name]!.isEmpty {
                facetRefinements.removeValue(forKey: name)
            }
        }
    }
    
    /// Test whether a facet has a refinement for a given value.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to look for.
    /// - returns: true if the refinement exists, false otherwise.
    ///
    @objc public func hasFacetRefinement(name: String, value: String) -> Bool {
        return facetRefinements[name]?.contains(where: { $0.name == name && $0.value == value }) ?? false
    }
    
    /// Test whether a facet has any refinement(s).
    ///
    /// - parameter name: The facet's name.
    /// - returns: true if the facet has at least one refinment, false if it has none.
    ///
    @objc public func hasFacetRefinements(name: String) -> Bool {
        if let facetRefinements = facetRefinements[name] {
            return !facetRefinements.isEmpty
        } else {
            return false
        }
    }
    
    /// Test whether at least one facet refinement is defined.
    ///
    /// - returns: true if at least one refinement is defined for at least one facet, false otherwise.
    ///
    @objc public func hasFacetRefinements() -> Bool {
        return !facetRefinements.isEmpty
    }
    
    /// Add or remove a facet refinement, based on its current state: if it exists, it is removed; otherwise it is
    /// added.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to toggle.
    ///
    @objc public func toggleFacetRefinement(name: String, value: String) {
        if hasFacetRefinement(name: name, value: value) {
            removeFacetRefinement(name: name, value: value)
        } else {
            addFacetRefinement(name: name, value: value)
        }
    }
    
    /// Remove all refinements for all facets.
    ///
    @objc public func clearFacetRefinements() {
        facetRefinements.removeAll()
    }
    
    /// Remove all refinements for a given facet.
    ///
    /// - parameter name: The facet's name.
    ///
    @objc public func clearFacetRefinements(name: String) {
        facetRefinements.removeValue(forKey: name)
    }

    // MARK: - Numerics
    
    /// Set a given numeric as disjunctive or conjunctive.
    ///
    /// - parameter name: The numeric's name.
    /// - parameter disjunctive: true to treat this numeric as disjunctive (`OR`), false to treat it as conjunctive
    ///   (`AND`, the default).
    ///
    @objc public func setNumeric(withName name: String, disjunctive: Bool) {
        if disjunctive {
            disjunctiveNumerics.insert(name)
        } else {
            disjunctiveNumerics.remove(name)
        }
    }
    
    /// Test whether a given numeric is disjunctive or conjunctive.
    ///
    /// - parameter name: The numeric's name.
    /// - returns: true if this numeric is disjunctive (`OR`), false if it's conjunctive (`AND`).
    ///
    @objc public func isDisjunctiveNumeric(name: String) -> Bool {
        return disjunctiveNumerics.contains(name)
    }
    
    /// Add a refinement for a given numeric.
    /// The refinement will be treated as conjunctive (`AND`) or disjunctive (`OR`) based on the numeric's own
    /// disjunctive/conjunctive status.
    ///
    /// + Note: This is a convenience shortcut for `addNumericRefinement(_:)`.
    ///
    /// - parameter name: The numeric's name (first operand to the operator).
    /// - parameter op: The comparison operator to apply.
    /// - parameter value: The value to compare the numeric to (second operand to the operator).
    /// - parameter inclusive: Whether the refinement is treated as inclusive (the default) or exclusive
    ///                        (negated with a `NOT`).
    ///
    @objc(addNumericRefinementWithName:op:numberValue:inclusive:)
    public func addNumericRefinement(_ name: String, _ op: NumericRefinement.Operator, _ value: NSNumber, inclusive: Bool = true) {
        addNumericRefinement(NumericRefinement(name, op, value, inclusive: inclusive))
    }

    /// Add a refinement for a given numeric.
    /// The refinement will be treated as conjunctive (`AND`) or disjunctive (`OR`) based on the numeric's own
    /// disjunctive/conjunctive status.
    ///
    /// + Note: This is a convenience shortcut for `addNumericRefinement(_:)`.
    ///
    /// - parameter name: The numeric's name (first operand to the operator).
    /// - parameter op: The comparison operator to apply.
    /// - parameter value: The value to compare the numeric to (second operand to the operator).
    /// - parameter inclusive: Whether the refinement is treated as inclusive (the default) or exclusive
    ///                        (negated with a `NOT`).
    ///
    @objc(addNumericRefinementWithName:op:intValue:inclusive:)
    public func addNumericRefinement(_ name: String, _ op: NumericRefinement.Operator, _ value: Int, inclusive: Bool = true) {
        addNumericRefinement(NumericRefinement(name, op, value, inclusive: inclusive))
    }

    /// Add a refinement for a given numeric.
    /// The refinement will be treated as conjunctive (`AND`) or disjunctive (`OR`) based on the numeric's own
    /// disjunctive/conjunctive status.
    ///
    /// + Note: This is a convenience shortcut for `addNumericRefinement(_:)`.
    ///
    /// - parameter name: The numeric's name (first operand to the operator).
    /// - parameter op: The comparison operator to apply.
    /// - parameter value: The value to compare the numeric to (second operand to the operator).
    /// - parameter inclusive: Whether the refinement is treated as inclusive (the default) or exclusive
    ///                        (negated with a `NOT`).
    ///
    @objc(addNumericRefinementWithName:op:doubleValue:inclusive:)
    public func addNumericRefinement(_ name: String, _ op: NumericRefinement.Operator, _ value: Double, inclusive: Bool = true) {
        addNumericRefinement(NumericRefinement(name, op, value, inclusive: inclusive))
    }
    
    /// Add a refinement for a given numeric.
    /// The refinement will be treated as conjunctive (`AND`) or disjunctive (`OR`) based on the numeric's own
    /// disjunctive/conjunctive status.
    ///
    /// - parameter refinement: The refinement to add.
    ///
    @objc public func addNumericRefinement(_ refinement: NumericRefinement) {
        if numericRefinements[refinement.name] == nil {
            numericRefinements[refinement.name] = [refinement]
        } else {
            numericRefinements[refinement.name]!.append(refinement)
        }
    }
    
    /// Remove a refinement for a given numeric.
    ///
    /// + Note: This is a convenience shortcut for `removeNumericRefinement(_:)`.
    ///
    /// - parameter name: The numeric's name (first operand to the operator).
    /// - parameter op: The comparison operator to apply.
    /// - parameter value: The value to compare the numeric to (second operand to the operator).
    /// - parameter inclusive: Whether the refinement is treated as inclusive (the default) or exclusive
    ///                        (negated with a `NOT`).
    ///
    @objc(removeNumericRefinementWithName:op:value:inclusive:)
    public func removeNumericRefinement(_ name: String, _ op: NumericRefinement.Operator, _ value: NSNumber, inclusive: Bool = true) {
        removeNumericRefinement(NumericRefinement(name, op, value, inclusive: inclusive))
    }

    /// Remove a refinement for a given numeric.
    ///
    /// - parameter refinement: The refinement to remove.
    ///
    @objc public func removeNumericRefinement(_ refinement: NumericRefinement) {
        if let index = numericRefinements[refinement.name]?.index(where: { $0 == refinement }) {
            numericRefinements[refinement.name]!.remove(at: index)
            if numericRefinements[refinement.name]!.isEmpty {
                numericRefinements.removeValue(forKey: refinement.name)
            }
        }
    }
    
    /// Remove a refinement for a given refinement condition.
    ///
    /// - parameter condition: the condition to evaluate.
    ///
    @objc public func removeNumericRefinements(where condition: (NumericRefinement) -> Bool) {
        let oldRefinements = numericRefinements
        oldRefinements.forEach { (name: String, refinements: [NumericRefinement]) in
            let newRefinements = refinements.filter({ !condition($0) })
            if newRefinements.count != refinements.count {
                numericRefinements[name] = newRefinements.isEmpty ? nil : newRefinements
            }
        }
    }
    
    /// Update a refinement for a given numeric.
    ///
    /// - parameter name: The numeric's name (first operand to the operator).
    /// - parameter op: The comparison operator to apply.
    /// - parameter value: The value to compare the numeric to (second operand to the operator).
    /// - parameter inclusive: Whether the refinement is treated as inclusive (the default) or exclusive
    ///                        (negated with a `NOT`).
    ///
    @objc(updateNumericRefinementWithName:op:value:inclusive:)
    public func updateNumericRefinement(_ name: String, _ op: NumericRefinement.Operator, _ value: NSNumber, inclusive: Bool = true) {
        self.removeNumericRefinements(where: { $0.name == name && $0.op == op && $0.inclusive == inclusive })
        self.addNumericRefinement(name, op, value, inclusive: inclusive)
    }

    /// Test whether a numeric has any refinement(s).
    ///
    /// - parameter name: The numeric's name.
    /// - returns: true if the numeric has at least one refinment, false if it has none.
    ///
    @objc public func hasNumericRefinements(name: String) -> Bool {
        if let refinements = numericRefinements[name] {
            return !refinements.isEmpty
        } else {
            return false
        }
    }
    
    /// Test whether at least one numeric refinement is defined.
    ///
    /// - returns: true if at least one refinement is defined for at least one numeric, false otherwise.
    ///
    @objc public func hasNumericRefinements() -> Bool {
        return !numericRefinements.isEmpty
    }
    
    /// Remove all refinements for all numeric.
    ///
    @objc public func clearNumericRefinements() {
        numericRefinements.removeAll()
    }
    
    /// Remove all refinements for a given numeric.
    ///
    /// - parameter name: The numeric's name.
    ///
    @objc public func clearNumericRefinements(name: String) {
        numericRefinements.removeValue(forKey: name)
    }
    
    // MARK: - Notifications
    
    private func notifyRefinementChanges() {
        var userInfo: [String: Any] = [:]
        userInfo[Searcher.userInfoNumericRefinementChangeKey] = numericRefinements
        userInfo[Searcher.userInfoFacetRefinementChangeKey] = facetRefinements
        NotificationCenter.default.post(name: Searcher.RefinementChangeNotification, object: self, userInfo: userInfo)
    }
}
