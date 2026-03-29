import AppIntents

struct OpenShoppingModeIntent: AppIntent {
    static let title: LocalizedStringResource = "appleSurface.intent.openShoppingMode.title"
    static let description = IntentDescription(
        LocalizedStringResource("appleSurface.intent.openShoppingMode.description")
    )
    static let openAppWhenRun = true

    @Parameter(title: "appleSurface.list.parameter.title")
    var list: ShoppingListAppEntity

    init() {
    }

    init(list: ShoppingListAppEntity) {
        self.list = list
    }

    func perform() async throws -> some IntentResult {
        AppleSurfaceRouteRequestStore.savePendingRoute(.shoppingMode(list.id))
        return .result()
    }
}
