//
//  NewsView.swift
//  social
//
//  Created by デバン・ナビーン on 14/03/24.
//

import SwiftUI
import Foundation
import WebKit

struct NewsView: View {
    struct NewsItem: Identifiable, Hashable {
        var id = UUID()
        var title: String
        var link: String
        var thumbnailURL: URL?
        var publicationDate: Date
        var websiteName: String // New property to store website name
        
        init(title: String, link: String, thumbnailURL: URL? = nil, publicationDate: Date) {
            self.title = title
            self.link = link
            self.thumbnailURL = thumbnailURL
            self.publicationDate = publicationDate
            
            // Determine website name based on the URL
            if link.contains("thedrive.com") {
                self.websiteName = "The Drive"
            } else if link.contains("jalopnik.com") {
                self.websiteName = "Jalopnik"
            } else if link.contains("autocar.co.uk") {
                self.websiteName = "Autocar"
            } else if link.contains("caranddriver.com") {
                self.websiteName = "Car and Driver"
            } else if link.contains("carscoops.com") {
                self.websiteName = "Carscoops"
            } else {
                self.websiteName = "Unknown Source"
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
        }
        
        static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
            return lhs.title == rhs.title
        }
    }
    
    @State private var newsItems: [NewsItem] = []
    @State private var currentPage = 1
    let itemsPerPage = 15
    let urls = [
        URL(string: "https://www.thedrive.com/feed")!,
        URL(string: "https://jalopnik.com/rss")!,
        URL(string: "https://www.autocar.co.uk/rss")!,
        URL(string: "https://www.caranddriver.com/rss/all.xml/")!,
        URL(string: "https://www.carscoops.com/category/news/feed/")!,
    ]
    
    var body: some View {
        NavigationView {
            if #available(iOS 17.0, *) {
                List(newsItems.uniqueElements, id: \.id) { news in
                    NavigationLink(destination: WebView(urlString: news.link)) {
                        VStack(alignment: .leading){
                            Text(news.websiteName) // Display the website name here
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack {
                                if let thumbnailURL = news.thumbnailURL {
                                    AsyncImage(url: thumbnailURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(5)
                                            .clipped()
                                    } placeholder: {
                                        Color.gray
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(5)
                                    }
                                }
                                Text(news.title)
                            }
                        }
                    }
                    .onAppear {
                        if news.id == newsItems.last?.id {
                            loadMoreData()
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .toolbarTitleDisplayMode(.inlineLarge)
                .navigationTitle("News")
                .onAppear {
                    fetchRSSFeeds(from: urls, page: currentPage)
                }
                .refreshable {
                    currentPage = 1
                    newsItems.removeAll()
                    fetchRSSFeeds(from: urls, page: currentPage)
                }
            } else {
                // Fallback on earlier versions
                List(newsItems.uniqueElements, id: \.id) { news in
                    NavigationLink(destination: WebView(urlString: news.link)) {
                        VStack(alignment: .leading){
                            Text(news.websiteName) // Display the website name here
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack {
                                if let thumbnailURL = news.thumbnailURL {
                                    AsyncImage(url: thumbnailURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(5)
                                            .clipped()
                                    } placeholder: {
                                        Color.gray
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(5)
                                    }
                                }
                                Text(news.title)
                            }
                        }
                    }
                    .onAppear {
                        if news.id == newsItems.last?.id {
                            loadMoreData()
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("News")
                .onAppear {
                    fetchRSSFeeds(from: urls, page: currentPage)
                }
                .refreshable {
                    currentPage = 1
                    newsItems.removeAll()
                    fetchRSSFeeds(from: urls, page: currentPage)
                }
            }
        }
    }
    
    func fetchRSSFeeds(from urls: [URL], page: Int) {
        var allNewsItems: [NewsItem] = []
        let group = DispatchGroup()
        
        for url in urls {
            group.enter()
            fetchRSSFeed(from: url, page: page) { parsedItems in
                allNewsItems.append(contentsOf: parsedItems)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            allNewsItems.sort { $0.publicationDate > $1.publicationDate }
            let startIndex = (currentPage - 1) * itemsPerPage
            let endIndex = min(startIndex + itemsPerPage, allNewsItems.count)
            let pageItems = Array(allNewsItems[startIndex..<endIndex])
            newsItems.append(contentsOf: pageItems.uniqueElements)
        }
    }
    
    func fetchRSSFeed(from url: URL, page: Int, completion: @escaping ([NewsItem]) -> Void) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion([])
                return
            }
            
            let parser = XMLParser(data: data)
            let rssParserDelegate = RSSParserDelegate(completion: completion)
            parser.delegate = rssParserDelegate
            
            if parser.parse() {
                // Completion is handled inside RSSParserDelegate
            } else {
                completion([])
            }
        }
        task.resume()
    }
    
    func loadMoreData() {
        currentPage += 1
        fetchRSSFeeds(from: urls, page: currentPage)
    }
    
    class RSSParserDelegate: NSObject, XMLParserDelegate {
        var currentElement = ""
        var currentTitle = ""
        var currentLink = ""
        var currentDescription = ""
        var currentMediaContentURL = ""
        var currentPubDate = ""
        var newsItems: [NewsItem] = []
        var completion: ([NewsItem]) -> Void
        var isParsingDescription = false
        
        init(completion: @escaping ([NewsItem]) -> Void) {
            self.completion = completion
        }
        
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            currentElement = elementName
            if currentElement == "item" {
                currentTitle = ""
                currentLink = ""
                currentDescription = ""
                currentMediaContentURL = ""
                currentPubDate = ""
                isParsingDescription = false
            } else if currentElement == "description" {
                isParsingDescription = true
            } else if currentElement == "media:content", let url = attributeDict["url"] {
                currentMediaContentURL = url
            }
        }
        
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            switch currentElement {
            case "title":
                currentTitle += string.trimmingCharacters(in: .whitespacesAndNewlines)
            case "link":
                currentLink += string.trimmingCharacters(in: .whitespacesAndNewlines)
            case "description" where isParsingDescription:
                currentDescription += string
            case "pubDate":
                currentPubDate += string.trimmingCharacters(in: .whitespacesAndNewlines)
            default:
                break
            }
        }
        
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "item" {
                let thumbnailURL = extractThumbnailURL(from: currentDescription) ?? URL(string: currentMediaContentURL)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
                let publicationDate = dateFormatter.date(from: currentPubDate) ?? Date()
                let newsItem = NewsItem(title: currentTitle, link: currentLink, thumbnailURL: thumbnailURL, publicationDate: publicationDate)
                newsItems.append(newsItem)
            }
        }
        
        func parserDidEndDocument(_ parser: XMLParser) {
            completion(newsItems)
        }
        
        private func extractThumbnailURL(from description: String) -> URL? {
            let imagePattern = #"<img[^>]*src="([^"]*)""#
            let videoPattern = #"<video[^>]*poster="([^"]*)""#
            
            if let imageURL = extractURL(from: description, using: imagePattern) {
                return imageURL
            } else if let videoURL = extractURL(from: description, using: videoPattern) {
                return videoURL
            } else {
                return nil
            }
        }
        
        private func extractURL(from description: String, using pattern: String) -> URL? {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            guard let matches = regex?.matches(in: description, options: [], range: NSRange(location: 0, length: description.utf16.count)) else {
                return nil
            }
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: description) {
                    let urlString = description[range]
                    return URL(string: String(urlString))
                }
            }
            
            return nil
        }
    }
}

extension Array where Element: Hashable {
    var uniqueElements: [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
