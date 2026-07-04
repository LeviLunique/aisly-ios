import AppIntents

struct OpenListsIntent: AppIntent {
    static let title: LocalizedStringResource = "appleSurface.intent.openLists.title"
    static let description = IntentDescription("appleSurface.intent.openLists.description")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        AppleSurfaceRouteRequestStore.savePendingRoute(.home)
        return .result()
    }
}
