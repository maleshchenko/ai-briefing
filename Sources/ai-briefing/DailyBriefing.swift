import Foundation
import FoundationModels

@available(macOS 26.0, *)
@Generable
struct DailyBriefing {

    let keyDevelopments: [String]
    let importantSignals: [String]
    let risks: [String]
    let thingsToWatch: [String]

}
