/// What a headphone or car button does: AirPods send a double press as next and a triple press as previous.
public enum ButtonAction: String, CaseIterable, Sendable {
    case skipForward, skipBack, bookmark

    public static let doublePressDefault = ButtonAction.bookmark
    public static let triplePressDefault = ButtonAction.skipBack

    public var title: String {
        switch self {
        case .skipForward: "Skip forward 30"
        case .skipBack: "Skip back 15"
        case .bookmark: "Bookmark"
        }
    }

    /// The Settings footer: what each press does now, joined when both match.
    public static func footer(double: ButtonAction, triple: ButtonAction) -> String {
        let presses = double == triple
            ? "Double and triple press \(double.phrase(plural: true))."
            : "Double press \(double.phrase(plural: false)). Triple press \(triple.phrase(plural: false))."
        return presses + " Other headphones and cars do the same with their next and previous buttons."
    }

    private func phrase(plural: Bool) -> String {
        let s = plural ? "" : "s"
        switch self {
        case .skipForward: return "skip\(s) forward 30"
        case .skipBack: return "skip\(s) back 15"
        case .bookmark: return "bookmark\(s), with a chime"
        }
    }
}
