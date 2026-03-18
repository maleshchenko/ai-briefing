import Foundation
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
@Generable
public struct DailyBriefing {

    public let keyDevelopments: [String]
    public let importantSignals: [String]
    public let risks: [String]
    public let thingsToWatch: [String]

}
