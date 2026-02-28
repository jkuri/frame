import Foundation

extension KeyedDecodingContainer {
  func decodeOrDefault<T: Decodable>(
    _ key: Key,
    _ defaultValue: @autoclosure () -> T
  ) throws -> T {
    try decodeIfPresent(T.self, forKey: key) ?? defaultValue()
  }
}
