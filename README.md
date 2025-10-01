# Coment Flutter

Modern rebuild of the Coment Android app using Flutter.

## Architecture Map (high-level)

- State management: Provider (`ItemProvider`) for catalog/search/sections; ephemeral widget `State` for local UI.
- Data layer (Firestore-first):
  - `ApiService` → read titles from `titles` collection.
  - `UserService` → user profile CRUD/streams in `users`.
  - `FavoriteService` → favorites in `favorites` (per-user per-title).
  - `ReadingStatusService` → statuses in `reading_status` (`plan|reading|completed|dropped|on_hold`).
  - `FollowService` → social graph in `follows`.
  - `ChatService` + `ChatHistoryService` → DMs and last-read tracking.
  - `GiphyService` → external GIF search.
- UI routing:
  - `main.dart` bootstraps Firebase, FCM, Crashlytics, Analytics.
  - `SplashScreen` → `NandogamiApp` (`_AuthGate`) → `LoginRegisterScreen` or `MainScreen` (3 tabs: Home, Search, Profile).
- Theming/tokens: `lib/core/constants.dart`, `lib/core/theme.dart` mirror old Android colors/dimens.
- Deep links: `app_links` push to `DetailScreen` by id.

## Data Flow Examples

- Home: `ItemProvider.load()` → `NandogamiRepository.getAll()` → sections (`featured/popular/newReleases/categories`).
- Search: `ItemProvider.search(q)` filters `_all` locally; recent queries saved via `SearchService`.
- Detail: Favorite toggle via `FavoriteService`; Reading Status via `ReadingStatusService`; Comments via `CommentsService`.
- Reading List: stream titleIds by status → map to `ItemProvider.findById` → list opens `DetailScreen`.
- Recommendations: watch favorites → overlap categories with catalog to suggest items.

## Folders

- `lib/data/services/*`: Firestore and external APIs.
- `lib/state/*`: Providers and app-level state.
- `lib/ui/screens/*`: Feature screens.
- `lib/ui/widgets/*`: Reusable UI components.
