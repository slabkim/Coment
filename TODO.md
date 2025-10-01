# TODO (Post-migration Priorities)

1) Search: connect user results
   - Wire `_UserResults` to `UserService.searchUsers(query)`
   - Create Firestore indexes if prompted; backfill `usernameLower/handleLower` for old users

2) Notifications
   - On notification tap for DM, navigate directly to `ChatScreen`
   - Optionally show heads-up banner UI in foreground

3) Local storage
   - Create wrapper service for SharedPreferences (favorites, recents) with namespaced keys

4) Tests
   - Widget/integration: Auth → Main → Detail; Search → Detail; favorite toggle; comments

5) CI/CD
   - GitHub Actions: build Android (APK/AAB), optional iOS; upload artifacts

6) Release prep
   - Final app icon/splash, versioning, store listing, privacy policy link

7) Analytics events
   - Log key events (search, open_detail, favorite_toggle, chat_send)
