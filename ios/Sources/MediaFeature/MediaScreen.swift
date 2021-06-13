import ComposableArchitecture
import Introspect
import Model
import SwiftUI
import Styleguide

public struct MediaScreen: View {

    private let store: Store<MediaState, MediaAction>
    @ObservedObject var viewStore: ViewStore<ViewState, ViewAction>

    @SearchController private var searchController: UISearchController

    public init(store: Store<MediaState, MediaAction>) {
        self.store = store
        let viewStore = ViewStore(store.scope(state: ViewState.init(state:), action: MediaAction.init(action:)))
        self.viewStore = viewStore
        self._searchController = .init(searchBarPlaceHolder: L10n.MediaScreen.SearchBar.placeholder) { text in
            viewStore.send(.searchTextDidChang(to: text))
        }
    }

    struct ViewState: Equatable {
        var isInitialLoadingIndicatorVisible: Bool
        var isSearchResultVisible: Bool

        init(state: MediaState) {
            isInitialLoadingIndicatorVisible = state.listState == nil
            isSearchResultVisible = !(state.listState?.searchText?.isEmpty ?? true)
        }
    }

    enum ViewAction {
        case progressViewAppeared
        case searchTextDidChang(to: String)
    }

    public var body: some View {
        searchController.searchBar.isUserInteractionEnabled = !viewStore.isInitialLoadingIndicatorVisible
        return NavigationView {
            IfLetStore(
                store.scope(state: \.listState?.list),
                then: MediaListView.init(store:),
                else: { ProgressView().onAppear { viewStore.send(.progressViewAppeared) } }
            )
            .if(viewStore.isSearchResultVisible) {
                $0.overlay(
                    SearchResultView()
                )
            }
            .navigationTitle(L10n.MediaScreen.title)
            .navigationBarItems(
                trailing: AssetImage.iconSetting.image
                    .renderingMode(.template)
                    .foregroundColor(AssetColor.Base.primary.color)
            )
            .introspectViewController { viewController in
                viewController.view.backgroundColor = AssetColor.Background.primary.uiColor
                guard viewController.navigationItem.searchController == nil else { return }
                viewController.navigationItem.searchController = searchController
                viewController.navigationItem.hidesSearchBarWhenScrolling = false
                // To keep the navigation bar expanded
                viewController.navigationController?.navigationBar.sizeToFit()
            }
        }
    }
}

extension MediaAction {
    init(action: MediaScreen.ViewAction) {
        switch action {
        case .progressViewAppeared:
            self = .loadItems
        case let .searchTextDidChang(to: text):
            self = .searchTextDidChange(to: text)
        }
    }
}

public struct MediaScreen_Previews: PreviewProvider {
    public static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            Group {
                var initialState = MediaState()
                MediaScreen(
                    store: .init(
                        initialState: initialState,
                        reducer: .empty,
                        environment: {}
                    )
                )
                let _ = initialState.listState = .init(list: .mock) // swiftlint:disable:this redundant_discardable_let
                MediaScreen(
                    store: .init(
                        initialState: initialState,
                        reducer: .empty,
                        environment: {}
                    )
                )
            }
            .environment(\.colorScheme, colorScheme)
        }
        .accentColor(AssetColor.primary.color)
    }
}
