import Foundation

public enum UnitConvert {
    public static let volumeUnits: [String] = ["tsp", "tbsp", "cup", "fl oz", "mL", "L"]
    public static let weightUnits: [String] = ["g", "oz", "lb"]

    private static let volumeFactors: [String: Double] = [
        "tsp": 4.92892,
        "tbsp": 14.7868,
        "cup": 236.588,
        "fl oz": 29.5735,
        "mL": 1,
        "L": 1000
    ]

    private static let weightFactors: [String: Double] = [
        "g": 1,
        "oz": 28.3495,
        "lb": 453.592
    ]

    public static func convert(_ value: Double, from: String, to: String) -> Double? {
        if let fromVol = volumeFactors[from], let toVol = volumeFactors[to] {
            return (value * fromVol) / toVol
        }
        if let fromWt = weightFactors[from], let toWt = weightFactors[to] {
            return (value * fromWt) / toWt
        }
        return nil
    }
}
