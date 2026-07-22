import Testing
import Foundation

struct CounterDeepLinkTests {
  @Test func urlBuildsCounterDeepLink() throws {
    let id = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!
    let url = try #require(CounterDeepLink.url(counterID: id.uuidString))
    #expect(url.scheme == "numo")
    #expect(url.host == "counter")
    #expect(url.path == "/\(id.uuidString)")
  }

  @Test func urlRejectsInvalidCounterID() {
    #expect(CounterDeepLink.url(counterID: "") == nil)
    #expect(CounterDeepLink.url(counterID: "preview") == nil)
    #expect(CounterDeepLink.url(counterID: "not-a-uuid") == nil)
  }

  @Test func parsesCounterIDFromURL() throws {
    let id = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!
    let url = try #require(URL(string: "numo://counter/\(id.uuidString)"))
    #expect(CounterDeepLink.counterID(from: url) == id)
  }

  @Test func rejectsUnrelatedURLs() throws {
    let urls = try [
      #require(URL(string: "https://example.com/counter/\(UUID().uuidString)")),
      #require(URL(string: "numo://other/\(UUID().uuidString)")),
      #require(URL(string: "numo://counter/preview")),
      #require(URL(string: "numo://counter/")),
    ]
    for url in urls {
      #expect(CounterDeepLink.counterID(from: url) == nil)
    }
  }
}
