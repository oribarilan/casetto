import Foundation
import SwiftData

extension Library {
    // MARK: Settings

    public func globalSpeed() throws -> PlaybackSpeed {
        PlaybackSpeed(try settings().speed)
    }

    public func setGlobalSpeed(_ speed: PlaybackSpeed) throws {
        try changeSettings { $0.speed = speed.value }
    }

    public func effectiveSpeed(for showKey: ShowKey) throws -> PlaybackSpeed {
        PlaybackSpeed.effective(
            global: try globalSpeed(),
            override: try speedOverride(showKey)
        )
    }

    public func globalVoiceBoost() throws -> Bool {
        try settings().voiceBoost
    }

    public func setGlobalVoiceBoost(_ isOn: Bool) throws {
        try changeSettings { $0.voiceBoost = isOn }
    }

    public func effectiveVoiceBoost(for showKey: ShowKey) throws -> Bool {
        try voiceBoostOverride(showKey) ?? globalVoiceBoost()
    }

    public func globalExpiry() throws -> InboxExpiry {
        InboxExpiry(storedDays: try settings().expiryDays)
    }

    public func setGlobalExpiry(_ expiry: InboxExpiry) throws {
        try changeSettings { $0.expiryDays = expiry.storedDays }
    }

    public func downloadCount() throws -> Int {
        try settings().downloadCount
    }

    public func setDownloadCount(_ count: Int) throws {
        try changeSettings { $0.downloadCount = max(count, 0) }
    }

    /// A stored value this build doesn't know, from a newer device, reads as the default.
    public func buttonActions() throws -> (double: ButtonAction, triple: ButtonAction) {
        let settings = try settings()
        return (
            ButtonAction(rawValue: settings.doublePress) ?? .doublePressDefault,
            ButtonAction(rawValue: settings.triplePress) ?? .triplePressDefault
        )
    }

    public func setButtonAction(_ action: ButtonAction, forDoublePress double: Bool) throws {
        try changeSettings {
            if double { $0.doublePress = action.rawValue } else { $0.triplePress = action.rawValue }
        }
    }

    /// Every settings change stamps `updatedAt`, so a merge keeps the listener's settings over a new device's defaults.
    private func changeSettings(_ change: (UserSettings) -> Void) throws {
        let settings = try settings()
        change(settings)
        settings.updatedAt = clock()
        try modelContext.save()
    }

    func settings() throws -> UserSettings {
        if let existing = try modelContext.fetch(FetchDescriptor<UserSettings>()).first {
            return existing
        }
        let settings = UserSettings()
        modelContext.insert(settings)
        return settings
    }
}
