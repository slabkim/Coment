Changelog 09-27-2025
Navigation Flow & Authentication
Updated navigation flow from SplashScreen → LoginRegisterPage → HomePage to SplashScreen → HomePage
Created AuthHelper class for centralized authentication logic
Users can access Home without login
Added auth guards for restricted actions (favorites, comments, etc.)
Return to previous page after successful login

Theme System & Light Mode
Implemented full light mode with white/light-blue scheme
Dynamic splash screen based on theme
Fixed all UI color consistency in light mode

Profile & User Management
Migrated profile picture storage from Firebase to Cloudinary
Added CloudinaryService for uploads
Made profile stats clickable (Followers, Following, Reads)
Enhanced Edit Profile and Theme Selector

UI/UX Improvements
Fixed text color visibility in light mode
Updated detail, category, manga, about, search, and news screens
Chat screen wallpaper removed; theme-consistent
Modernized About screen UI

External Links & API
Fixed icon/color consistency for external links
Added caching and retry mechanisms
Added manual retry button
Unified icon system for external platforms

Reading Status & Data Sync
Integrated Firestore for reading status
Synced reading list and counts with profile
Ensured data consistency across screens

Bug Fixes & Error Handling
Fixed IconData and type mismatch errors
Fixed build and navigation errors
Improved error handling for API calls

Language & Localization
Unified all UI text in English
Translated About screen and mission statement
Updated all feature descriptions and labels

Performance & Optimization
Improved caching, loading states, and memory usage
Optimized background loading and API efficiency

Code Quality & Architecture
Centralized AuthHelper and improved service layer
Strengthened type safety in models
Enhanced error handling across app

Changelog 2025-10-01
Theming & Architecture
Added centralized theme in lib/core/theme.dart with color/dimension tokens from old Android project
Extended AppColors in lib/core/constants.dart for color consistency
Wrote architecture map in README.md (state, data layer, routing, theming, deep links)

Navigation & Boot
SplashScreen → _AuthGate flow in main.dart/app.dart connected
Bottom navigation simplified to 3 tabs: Home, Search, Profile

Authentication & Profile
Implemented login & register UI/flow (Firebase Auth)
Polished profile, including realtime stats: Followers/Following/Reads
Edit Profile updates avatar, username, bio, and normalizes usernameLower/handleLower for search

Data Layer
Firestore services available: Items, User, Favorites, Reading Status, Follow, Chat, Comments, Giphy
Reading List connected to Firestore status (plan/reading/completed/dropped/on_hold)

Home
Comic posters now proportional (AspectRatio 16:9) and safe layout
Added loading skeleton and smooth haptics on favorite button
Profile badge (leading) displays user photo; tap → Profile

Search
Search results can open to Detail page
Home page more lively with "Trending titles"
User search via @username using UserService.searchUsers (index usernameLower/handleLower)

Detail
Favorite button with haptic feedback
Reading status actions, comment tab, and information section

Chat
Chat list & DM with GIF picker, read indicators (check/double-check), and last read markers
In-app popup (snackbar) for new messages when app is in foreground

Notifications
FCM in app: save/refresh token, background handler, foreground snackbar, and handler when notification is opened
Cloud Functions: send notifications for new messages, comment likes, and new followers

Assets & Others
Legacy image migration and pubspec.yaml updates
Firebase analytics & Crashlytics integration (global error handler, app_open event)

UI Reusable
Added lib/ui/widgets/common.dart (SectionTitle, DarkListTile, TagChip) for component consistency

Latest Improvements
User search connected to Firestore stream + index addition
DM notification tap opens ChatList page
Local Storage standardization via SharedPrefsService
CI/CD GitHub Actions (format, analyze, test, build APK & AAB)

Priority Updates
Rebrand to Coment
Light theme toggle (Follow System / Light / Dark)
Splash Screen single animation (fade + scale)
Profile: Followers/Following clickable section
Added “About” page with link in Profile

Changelog 2025-10-04
API Migration & Optimization
Migrated to AniList API as main manga data source
Added AniList “Where to Read” integration
Simplified system to rely solely on AniList

Google Sign-In Integration
Implemented Google Sign-In via google_sign_in
Integrated with Firebase Auth
Synced user profile with Google account data
Added logout button + confirmation dialog
Configured OAuth Client ID and SHA-1 fingerprints
Added robust error handling

Home Page Redesign
Structured comic catalog system using multiple queries
Added featured, trending, top-rated, seasonal, and recently-added sections
Pull-to-refresh implemented
Adult content filtering applied globally

Detail Page Enhancement
Added more detailed AniList info (format, status, dates, scores)
Added Character & Relations sections
Added "Where to Read" with clickable external links
Added banner backgrounds + framed cover design
Cleaned HTML tags for readable description

UI/UX Improvements
Fixed profile photo display in Home
Restored chat button
Improved loading/error indicators
Optimized responsive layout and typography
Enhanced navigation smoothness

Technical Improvements
Improved error handling and logging
Optimized API and memory performance
Refactored for better maintainability
Updated dependencies and environment config

Bug Fixes
Fixed Google Sign-In ApiException: 10
Fixed profile photo issues and chat button missing
Fixed API errors, overflow bugs, and type mismatches

Security & Authentication
Configured OAuth 2.0 IDs & SHA-1 fingerprints
Updated Firebase config files
Ensured consistent package naming
Added required Android permissions

Data Models & Architecture
Expanded AniListManga, ComicItem, NandogamiItem, and UserProfile models
Added ExternalLink model
Improved repository structure

Content & Features
Added adult-content filtering system
Implemented genre-based manga display
Integrated external reading platforms
Added manga industry news