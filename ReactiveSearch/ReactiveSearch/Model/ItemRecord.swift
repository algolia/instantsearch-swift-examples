//
//  ItemRecord.swift
//  ecommerce
//
//  Created by Guy Daher on 03/02/2017.
//  Copyright © 2017 Guy Daher. All rights reserved.
//

import AlgoliaSearch
import InstantSearchCore
import Foundation

struct ItemRecord {
    private var json: JSONObject
    private let MAX_BEST_SELLING_RANK = 32691;
    
    init(json: JSONObject) {
        self.json = json
    }
    
    var name: String? {
        return json["name"] as? String
    }
    
    var type: String? {
        return json["type"] as? String
    }
    
    var category: String? {
        return json["category"] as? String
    }
    
    var price: Double? {
        return json["price"] as? Double
    }
    
    
    var rating: Int? {
        return json["rating"] as? Int
    }
    
    var imageUrl: URL? {
        guard let urlString = json["image"] as? String else { return nil }
        return URL(string: urlString)
    }
    
    var name_highlighted: String? {
        return SearchResults.highlightResult(hit: json, path: "name")?.value
    }
    
    var category_highlighted: String? {
        return SearchResults.highlightResult(hit: json, path: "category")?.value
    }
    
    var type_highlighted: String? {
        return SearchResults.highlightResult(hit: json, path: "type")?.value
    }
}

