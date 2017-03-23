import Foundation
import InstantSearchCore
import AlgoliaSearch

class SearcherBuilder {
    
    private static let ALGOLIA_APP_ID = "latency"
    private static let ALGOLIA_INDEX_NAME = "bestbuy_promo"
    private static let ALGOLIA_API_KEY = "1f6fd3a6fb973cb08419fe7d288fa4db"
    
    
    public static func createSearcher() -> Searcher {
        var searcher: Searcher
    
        let client = Client(appID: ALGOLIA_APP_ID, apiKey: ALGOLIA_API_KEY)
        let index = client.index(withName: ALGOLIA_INDEX_NAME)
        searcher = Searcher(index: index)
        
        searcher.params.attributesToRetrieve = ["name", "salePrice"]
        searcher.params.attributesToHighlight = ["name"]
        searcher.params.facets = ["category", "manufacturer"]
        
        return searcher
    }
}
