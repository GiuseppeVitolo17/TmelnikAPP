# Tmelnik Youth Exchange Management App - Complete Project Documentation

This document provides a comprehensive overview of all functions, variables, and components in the Tmelnik Youth Exchange Management Flutter application.

## Table of Contents

1. [Main Entry Point](#main-entry-point)
2. [Models](#models)
3. [Services](#services)
4. [Screens](#screens)
5. [Widgets](#widgets)
6. [Theme & Configuration](#theme--configuration)
7. [Utils](#utils)

---

## Main Entry Point

### `lib/main.dart`

The main entry point of the application. Handles Firebase initialization, authentication state management, and app routing.

#### Top-Level Functions

**`_firebaseMessagingBackgroundHandler(RemoteMessage message)`**
- **Purpose**: Background handler for Firebase Cloud Messaging (FCM) notifications
- **Parameters**: 
  - `message` (RemoteMessage): The FCM message received in background
- **Behavior**: 
  - Initializes Firebase in background isolate
  - Forwards message to NotificationService for local notification display
- **Platform**: Android/iOS only (not web)

**`main()`**
- **Purpose**: Application entry point
- **Initialization Steps**:
  1. Ensures Flutter binding is initialized
  2. Logs loading configuration
  3. Initializes debug logging
  4. Initializes Firebase
  5. Attempts to restore user session from Google Sign-In
  6. Registers FCM background handler
  7. Initializes notification service
  8. Sets preferred device orientations (portrait only)
  9. Signals loading controller that app is ready
  10. Runs the app

#### Classes

**`TmelnikApp` (StatelessWidget)**
- **Purpose**: Root widget of the application
- **Properties**: None
- **Methods**:
  - `build(BuildContext context)`: Builds MaterialApp with theme configuration and AuthWrapper as home

**`AuthWrapper` (StatefulWidget)**
- **Purpose**: Manages authentication state and routes between auth screen and main app
- **State Variables**:
  - `_isGuestMode` (bool): Whether user is in guest mode
- **Methods**:
  - `_enterGuestMode()`: Sets guest mode to true
  - `_exitGuestMode()`: Sets guest mode to false
  - `build(BuildContext context)`: 
    - If guest mode: shows MainNavigationScreen with guest restrictions
    - Otherwise: StreamBuilder listening to FirebaseAuth.authStateChanges()
      - If authenticated: shows MainNavigationScreen
      - If not authenticated: shows AuthScreen

**`AuthScreen` (StatefulWidget)**
- **Purpose**: Login/registration screen with Google Sign-In and email/password options
- **Properties**:
  - `onGuestModeRequested` (VoidCallback?): Callback when user requests guest mode
- **State Variables**:
  - `_formKey` (GlobalKey<FormState>): Form validation key
  - `_email` (String): User email input
  - `_password` (String): User password input
  - `_isLogin` (bool): Toggle between login and registration
  - `_isLoading` (bool): Loading state during authentication
  - `_googleSignIn` (GoogleSignIn): Google Sign-In instance
- **Methods**:
  - `_submit()`: Handles email/password authentication (login or registration)
  - `_signInWithGoogle()`: Handles Google Sign-In flow with silent sign-in fallback
  - `build(BuildContext context)`: Builds authentication UI with Google button, email/password form, and guest mode option

**`MainNavigationScreen` (StatefulWidget)**
- **Purpose**: Main navigation container with bottom navigation bar
- **Properties**:
  - `isGuestMode` (bool): Whether user is in guest mode
  - `onLoginRequested` (VoidCallback?): Callback when guest requests login
- **State Variables**:
  - `_currentIndex` (int): Current selected tab index (0-3)
- **Methods**:
  - `_screens` (getter): Returns list of screens based on guest mode
  - `_currentScreenTitle` (getter): Returns title for current screen
  - `_buildHeader(String title)`: 
    - Builds custom header with emoji, title, and profile/logout button
    - Profile button shows confirmation dialog before logout
    - Dialog asks "Are you sure you want to log out?" with Cancel and Log Out options
  - `build(BuildContext context)`: Builds Scaffold with custom header, IndexedStack for screens, and BottomNavigationBar

**`MainNavigationScreen` (StatefulWidget)**
- **Purpose**: Main navigation container with bottom navigation bar
- **Properties**:
  - `isGuestMode` (bool): Whether user is in guest mode
  - `onLoginRequested` (VoidCallback?): Callback when guest requests login
- **State Variables**:
  - `_currentIndex` (int): Current selected tab index (0-3)
- **Methods**:
  - `_screens` (getter): Returns list of screens based on guest mode
    - Guest mode: ProjectOffersScreen, GuestLoginScreen (reflection), GuestLoginScreen (diary), NewsScreen
    - Authenticated: ProjectOffersScreen, DailyReflectionScreen, DiaryCalendarScreen, NewsScreen
  - `_currentScreenTitle` (getter): Returns title for current screen
  - `_buildHeader(String title)`: Builds custom header with emoji, title, and profile/logout button
  - `build(BuildContext context)`: Builds Scaffold with custom header, IndexedStack for screens, and BottomNavigationBar

**`GuestLoginScreen` (StatelessWidget)**
- **Purpose**: Placeholder screen shown to guests when accessing restricted features
- **Properties**:
  - `title` (String): Section title requiring login
  - `onLoginRequested` (VoidCallback?): Callback to request login
- **Methods**:
  - `build(BuildContext context)`: Shows lock icon, "Login Required" message, and login button

**`FeedbackScreen` (StatelessWidget)**
- **Purpose**: Placeholder screen for feedback collection (future feature)
- **Methods**:
  - `build(BuildContext context)`: Shows feedback icon and placeholder message

---

## Models

### `lib/models/project_offer.dart`

Data model for project offers stored in Firestore.

#### Class: `ProjectOffer`

**Properties**:
- `id` (String): Unique project identifier
- `title` (String): Project title
- `description` (String): Project description
- `targeting` (String): Target audience description
- `location` (String): Project location/city
- `duration` (String?): Optional duration description
- `requirements` (String): Project requirements
- `benefits` (List<String>): List of project benefits
- `contactInfo` (String): Contact information
- `instagramAccount` (String): Instagram account handle
- `applyLink` (String): URL for applying to the project
- `infoPackUrl` (String): URL to infopack document
- `createdAt` (DateTime): Creation timestamp
- `expiresAt` (DateTime?): Optional expiration date
- `departureDate` (DateTime?): Optional departure date
- `returnDate` (DateTime?): Optional return date
- `status` (OfferStatus): Project status (active, paused, expired, completed)
- `shareCount` (int): Number of times shared
- `imageUrl` (String): Optional project image URL

**Methods**:
- `copyWith(...)`: Creates a copy with modified fields
- `toJson()`: Converts to JSON map
- `fromJson(Map<String, dynamic>)`: Creates from JSON map
- `toFirestore()`: Converts to Firestore document format
- `fromFirestore(DocumentSnapshot)`: Creates from Firestore document
- `isExpired` (getter): Checks if project has expired
- `isActive` (getter): Checks if project is active and not expired
- `formattedExpiryDate` (getter): Returns human-readable expiry date
- `instagramShareText` (getter): Returns formatted text for Instagram sharing

#### Enum: `OfferStatus`

**Values**: `active`, `paused`, `expired`, `completed`

**Extension: `OfferStatusExtension`**
- `displayName` (getter): Human-readable status name
- `emoji` (getter): Emoji representation of status

---

### `lib/models/news_item.dart`

Data model for RSS news items from Erasmus+ feed.

#### Class: `NewsItem`

**Properties**:
- `title` (String): News article title
- `summary` (String): Article summary/description
- `date` (String): Formatted date string
- `url` (String): Article URL
- `imageUrl` (String): Optional preview image URL
- `pubDateTimestamp` (DateTime?): Parsed publication timestamp
- `isNew` (bool): Flag indicating new article
- `isUpdated` (bool): Flag indicating updated article

**Methods**:
- `copyWith(...)`: Creates a copy with modified fields
- `parsePubDate(String?)`: Static method to parse RFC 822 date format
- `formattedDate` (getter): Returns human-readable formatted date

---

## Services

### `lib/services/notification_service.dart`

Service for handling push notifications via FCM and local notifications.

#### Class: `NotificationService`

**Static Properties**:
- `_instance` (NotificationService): Singleton instance
- `_random` (Random): Random number generator
- `notificationsEnabled` (bool): Global toggle for notifications

**Instance Properties**:
- `_localNotifications` (FlutterLocalNotificationsPlugin?): Local notifications plugin
- `_initialized` (bool): Initialization flag
- `_firestoreService` (FirebaseFirestoreService): Firestore service instance
- `_notificationTemplates` (List<String>): Template messages for notifications

**Methods**:
- `initialize()`: 
  - Initializes Firebase Messaging
  - Requests notification permissions (iOS/Android 13+)
  - Initializes local notifications plugin
  - Subscribes to FCM topic "projects"
  - Sets up foreground message listener
  - Sets up message opened app listener
- `_getRandomMessage(String, String, String)`: Returns random notification message from templates
- `getRandomMessage(String, String, String)`: Public static accessor for random message
- `showNewProjectNotification({required String projectName, required String cityName, required String departureDate})`: 
  - Shows local notification for new project
  - Platform: Android/iOS only
- `handleRemoteMessage(RemoteMessage, {bool fromBackground})`: 
  - Handles FCM remote message
  - Fetches project details from Firestore
  - Shows local notification if from background
- `formatDateForNotification(DateTime)`: Formats date for notification display

---

### `lib/services/erasmus_rss_service.dart`

Service for fetching and parsing Erasmus+ RSS feed.

#### Class: `ErasmusRssService`

**Constants**:
- `_rssUrl` (String): RSS feed URL
- `_maxArticles` (int): Maximum articles to fetch (50)

**Methods**:
- `fetchErasmusNews({Function(NewsItem)? onItemFound})`: 
  - Fetches RSS feed (uses CORS proxy on web)
  - Parses XML incrementally
  - Filters news items (excludes documents)
  - Calls `onItemFound` callback for each valid item
  - Returns complete list of news items
- `_parseRssXml(String)`: 
  - Parses RSS XML string
  - Extracts title, link, pubDate, description, imageUrl
  - Sorts by date (newest first)
- `_formatDateForDisplay(DateTime)`: Formats date as "Today", "Yesterday", "X days ago", or "dd MMM yyyy"
- `_cleanXmlText(String)`: 
  - Removes CDATA wrappers
  - Decodes HTML entities
  - Strips HTML tags

---

### `lib/services/firebase_firestore_service.dart`

Service for Firestore database operations.

#### Class: `FirebaseFirestoreService`

**Constants**:
- `_offersCollection` (String): "project_offers"
- `_feedbackCollection` (String): "feedback"
- `_newsCollection` (String): "news"
- `_infoCollection` (String): "info_items"
- `_usersCollection` (String): "users"
- `_dailyReflectionsCollection` (String): "daily_reflections"

**Properties**:
- `_firestore` (FirebaseFirestore): Firestore instance

**Project Offers Methods**:
- `getProjectOffersStream()`: Returns Stream<List<ProjectOffer>> of active projects
- `getProjectOfferById(String)`: Fetches single project by ID
- `getProjectOffers()`: Fetches all active projects (one-time)
- `addProjectOffer(ProjectOffer)`: Adds new project to Firestore
- `updateProjectOffer(ProjectOffer)`: Updates existing project
- `deleteProjectOffer(String)`: Deletes project by ID

**Other Methods**:
- Similar CRUD methods for feedback, news, info items, daily reflections, and user roles

---

### `lib/services/user_role_service.dart`

Service for managing user roles and admin permissions.

#### Class: `UserRoleService`

**Methods**:
- `initializeUserRole(User)`: Initializes user role in Firestore (default: user)
- `isCurrentUserAdmin()`: Checks if current user has admin role
- `getUserRole(String)`: Fetches user role by UID

---

### `lib/services/news_cache_service.dart`

Service for caching news items locally using SharedPreferences.

#### Class: `NewsCacheService`

**Methods**:
- `saveToCache(List<NewsItem>)`: Saves news items to local cache
- `getFromCache()`: Retrieves cached news items
- `markAsSeen(String)`: Marks article URL as seen
- `isSeen(String)`: Checks if article URL was seen
- `markAsNew(String)`: Marks article URL as new
- `isNew(String)`: Checks if article URL is new
- `markAsUpdated(String)`: Marks article URL as updated
- `isUpdated(String)`: Checks if article URL was updated

---

### `lib/services/image_cache_service.dart`

Service for caching project images locally to avoid API calls on every app launch.

#### Class: `ImageCacheService`

**Purpose**: Caches project images on disk (mobile) or in SharedPreferences (web) to prevent unnecessary API calls. Images are only refreshed when user taps on them.

**Static Properties**:
- `_instance` (ImageCacheService): Singleton instance
- `_cacheKeyPrefix` (String): "project_image_url_" - prefix for SharedPreferences keys
- `_cacheTimestampPrefix` (String): "project_image_timestamp_" - prefix for timestamp keys

**Methods**:
- `getCachedImagePath(String city)`: Returns cached image file path for mobile (null if not cached)
- `getCachedImage(String city)`: Returns cached image URL (web) or file path (mobile)
- `cacheImage(String city, String imageUrl)`: 
  - Downloads and saves image locally (mobile) or stores URL (web)
  - Returns file path (mobile) or URL (web)
- `fetchAndCacheImage(String city)`: 
  - Fetches new image from Pexels API
  - Caches it locally
  - Called only when user taps on image to refresh
- `clearCache(String city)`: Removes cached image for a specific city
- `_getCacheDirectory()`: Gets or creates cache directory for mobile
- `_getFileName(String city)`: Generates safe filename from city name using MD5 hash

**Behavior**:
- **Mobile**: Images are saved as files in app cache directory
- **Web**: Image URLs are stored in SharedPreferences
- **No automatic refresh**: Images are loaded from cache on app startup
- **Manual refresh**: User taps on image to fetch and cache new image

---

## Screens

### `lib/screens/project_offers_screen.dart`

Screen displaying list of project offers.

#### Class: `ProjectOffersScreen` (StatefulWidget)

**State Variables**:
- `_firestoreService` (FirebaseFirestoreService): Firestore service
- `_notificationService` (NotificationService): Notification service
- `_imageCacheService` (ImageCacheService): Image cache service for local image storage
- `_isAdmin` (bool): Admin status flag
- `_isLoadingAdmin` (bool): Admin check loading state
- `_seenProjectIds` (Set<String>): Tracks previously seen project IDs

**Methods**:
- `_checkAdminStatus()`: Checks if current user is admin
- `_checkForNewProjects(List<ProjectOffer>)`: Detects new projects and shows notifications
- `_handleApply(String, {String?, String?})`: Opens apply link in external browser
- `_handleInfo(String, {String?, String?})`: Opens infopack link in external browser
- `_openUrl(BuildContext, String, String)`: Generic URL launcher with error handling
- `_handleEdit(String)`: Navigates to edit project screen
- `_handleDelete(String)`: Deletes project with confirmation dialog
- `build(BuildContext context)`: 
  - Builds screen with StreamBuilder for project list
  - Loads images from cache (no API calls on startup)
  - Shows admin FAB if user is admin
  - Project cards support image tap to refresh cached images

**Image Loading Behavior**:
- Images are loaded from local cache on app startup (no API calls)
- If project has `imageUrl` field, it's used directly
- Otherwise, cached image for city location is loaded
- User can tap on image to fetch and cache a new image from Pexels API

---

### `lib/screens/news_screen.dart`

Screen displaying RSS news feed from Erasmus+.

#### Class: `NewsScreen` (StatefulWidget)

**State Variables**:
- `_newsItems` (List<NewsItem>): List of news items
- `_isLoading` (bool): Loading state
- `_rssService` (ErasmusRssService): RSS service instance
- `_cacheService` (NewsCacheService): Cache service instance

**Methods**:
- `_loadNews()`: Fetches news from RSS feed and updates cache
- `build(BuildContext context)`: Builds screen with loading indicator or list of NewsCard widgets

---

### `lib/screens/add_project_screen.dart`

Screen for adding new project offers (admin only).

#### Class: `AddProjectScreen` (StatefulWidget)

**State Variables**:
- `_formKey` (GlobalKey<FormState>): Form validation key
- `_titleController` (TextEditingController): Title input
- `_descriptionController` (TextEditingController): Description input
- `_targetingController` (TextEditingController): Targeting input
- `_locationController` (TextEditingController): Location input
- `_durationController` (TextEditingController): Duration input
- `_requirementsController` (TextEditingController): Requirements input
- `_benefitsController` (TextEditingController): Benefits input (comma-separated)
- `_contactController` (TextEditingController): Contact info input
- `_instagramController` (TextEditingController): Instagram account (pre-filled: "tmelnik_cz")
- `_applyLinkController` (TextEditingController): Apply link (pre-filled with default)
- `_infoPackUrlController` (TextEditingController): Infopack link
- `_departureDate` (DateTime?): Selected departure date
- `_returnDate` (DateTime?): Selected return date
- `_expiresAt` (DateTime?): Selected expiration date
- `_isLoading` (bool): Saving state

**Methods**:
- `_saveProject()`: Validates form, creates ProjectOffer, saves to Firestore
- `_selectDate(BuildContext, DateTime?)`: Shows date picker
- `build(BuildContext context)`: Builds form with all input fields and save button

---

### `lib/screens/edit_project_offer_screen.dart`

Screen for editing existing project offers (admin only).

#### Class: `EditProjectOfferScreen` (StatefulWidget)

**Properties**:
- `projectId` (String): ID of project to edit

**State Variables**: Similar to AddProjectScreen, plus:
- `_projectOffer` (ProjectOffer?): Current project data

**Methods**:
- `_loadProject()`: Loads project data from Firestore and populates form
- `_saveChanges()`: Updates project in Firestore
- `build(BuildContext context)`: Similar to AddProjectScreen but with loaded data

---

### `lib/screens/daily_reflection_screen.dart`

Screen for daily reflection/journaling feature.

#### Class: `DailyReflectionScreen` (StatefulWidget)

**State Variables**:
- `_selectedDate` (DateTime): Currently selected date
- `_currentReflection` (DailyReflection?): Current reflection data
- `_isLoading` (bool): Loading state
- `_predefinedActivityCategories` (List<Map<String, String>>): Predefined activity categories with emojis:
  - Food 🍽️
  - Group atmosphere 👥
  - Morning activities 🌅
  - Afternoon activities ☀️
  - Coffee breaks ☕
  - Energy level ⚡

**Methods**:
- `_loadReflection()`: Loads reflection for selected date from Firestore
- `_saveReflection()`: Saves reflection to Firestore
- `_selectMood(MoodType)`: Sets mood for current reflection
- `_addActivity(String)`: Adds activity to reflection
- `_rateActivity(String, MoodType)`: Rates an activity with mood
- `_removeActivity(String)`: Removes activity from reflection
- `_showAddActivityDialog()`: 
  - Shows dialog with predefined activity categories
  - Each category is selectable with emoji
  - Includes "+" button to add custom activity
  - Dialog is scrollable and responsive for mobile
- `_showCustomActivityDialog()`: Shows dialog for entering custom activity name
- `_buildMoodButton(String, String, MoodType)`: Builds mood selection button
- `_buildDateCard()`: Builds date display card with month and day
- `_buildActivityItem(Activity)`: Builds activity list item with rating buttons
- `_buildRatingButton(String, MoodType, Activity)`: Builds rating button for activity
- `build(BuildContext context)`: Builds screen with mood buttons, date card, and activities list

---

### `lib/screens/diary_calendar_screen.dart`

Screen for calendar view of journal entries.

#### Class: `DiaryCalendarScreen` (StatefulWidget)

**State Variables**:
- `_selectedDate` (DateTime): Currently selected date
- `_entries` (List<JournalEntry>): Journal entries

**Methods**:
- `_loadEntries()`: Loads journal entries from Firestore
- `build(BuildContext context)`: Builds calendar widget with entry markers

---

## Widgets

### `lib/widgets/project_card.dart`

Reusable widget for displaying project offer cards.

#### Class: `ProjectCard` (StatelessWidget)

**Properties**:
- `imagePathOrUrl` (String): Image path (local file) or URL (network/web)
- `title` (String): Project title
- `dates` (String): Formatted date range
- `deadline` (String?): Optional application deadline
- `onApply` (VoidCallback): Callback when Apply button clicked
- `onInfo` (VoidCallback): Callback when Info button clicked
- `onEdit` (VoidCallback?): Callback when Edit button clicked (admin only)
- `onDelete` (VoidCallback?): Callback when Delete button clicked (admin only)
- `showAdminActions` (bool): Whether to show admin action buttons
- `onImageTap` (VoidCallback?): Callback when image is tapped (for refreshing cached images)

**Methods**:
- `build(BuildContext context)`: 
  - Builds card with project details, action buttons, and admin actions
  - Handles network images, local files, and asset images
  - Image is tappable if `onImageTap` is provided (for cache refresh)
- `_buildCardContent()`: Builds card content section with title, dates, deadline, and buttons
- `_buildPlaceholderImage()`: Builds placeholder when no image is available

**Image Handling**:
- Network images: Loaded via `Image.network`
- Local files: Loaded via `Image.file` (for cached images on mobile)
- Asset images: Loaded via `Image.asset` (fallback)
- All images are wrapped in `GestureDetector` to support tap for refresh

---

### `lib/widgets/news_card.dart`

Reusable widget for displaying news article cards.

#### Class: `NewsCard` (StatelessWidget)

**Properties**:
- `newsItem` (NewsItem): News item data to display

**Methods**:
- `_openArticle(BuildContext, String)`: Opens article URL in external browser
- `build(BuildContext context)`: Builds card with:
  - Image background (if available) with gradient overlay
  - Date and status badges
  - Title and summary
  - "Read more" button

---

## Theme & Configuration

### `lib/theme/app_theme.dart`

Centralized theme configuration.

#### Classes

**`AppColors`**
- `primaryBlue` (Color): #0066FF
- `secondaryYellow` (Color): #FFC107
- `backgroundGrey` (Color): #F5F6FA
- `textPrimary` (Color): Black
- `textSecondary` (Color): Grey
- `cardBackground` (Color): White

**`AppRadius`**
- `large` (BorderRadius): 20px radius
- `medium` (BorderRadius): 12px radius

**`AppShadows`**
- `soft` (List<BoxShadow>): Soft shadow with 0.08 opacity, 10px blur

**Functions**:
- `buildAppTheme()`: Returns ThemeData with color scheme, Material 3, and app bar configuration

---

### `lib/config/loading_config.dart`

Configuration for loading screen behavior.

#### Class: `LoadingConfig`

**Properties**:
- `showLoadingScreen` (bool): Whether to show loading screen
- `loadingScreenDuration` (Duration): Minimum loading screen duration

**Methods**:
- `logConfig()`: Logs current configuration

---

## Utils

### `lib/utils/debug_logger.dart`

Debug logging utility with platform-specific implementations.

#### Class: `DebugLogger`

**Methods**:
- `initializeLog()`: Initializes logging system
- `log(String)`: General log message
- `firebase(String)`: Firebase-specific log
- `auth(String)`: Authentication log
- `navigation(String)`: Navigation log
- `ui(String)`: UI log
- `success(String)`: Success log
- `error(String, dynamic)`: Error log with exception

**Platform Implementations**:
- `debug_logger_mobile.dart`: Mobile implementation (file logging)
- `debug_logger_web.dart`: Web implementation (console logging)

---

## Cloud Functions

### `notification_setup/functions/index.js`

Firebase Cloud Functions for push notifications.

#### Functions

**`onProjectOfferCreate`**
- **Trigger**: Firestore document create on `project_offers/{projectId}`
- **Purpose**: Sends FCM notification to "projects" topic when new project is created
- **Message Structure**:
  - `notification.title`: "New Project Available! 🎉"
  - `notification.body`: Project title and location
  - `data.type`: "project_created"
  - `data.projectId`: Project document ID
  - `topic`: "projects"
  - `android.priority`: "high"
  - `apns.payload.aps.contentAvailable`: true

**`sendTestPush`**
- **Type**: HTTP callable function
- **Purpose**: Sends test push notification
- **Parameters** (query/body):
  - `token` (String, optional): FCM token for direct send
  - `title` (String, optional): Notification title (default: "Test: New Project Available! 🎉")
  - `body` (String, optional): Notification body (default: "This is a test push from Functions")
- **Behavior**: 
  - If token provided: sends to specific device
  - Otherwise: sends to "projects" topic

**`createTestProject`**
- **Type**: HTTP callable function
- **Purpose**: Creates a test project in Firestore to trigger onCreate notification
- **Returns**: Created project document ID

---

## Key Dependencies

- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `firebase_messaging`: Push notifications
- `cloud_firestore`: Database operations
- `google_sign_in`: Google Sign-In
- `flutter_local_notifications`: Local notifications
- `url_launcher`: Opening external URLs
- `shared_preferences`: Local caching (news, image URLs)
- `path_provider`: File system access for image cache (mobile)
- `http`: HTTP requests for RSS feed and image downloads
- `crypto`: MD5 hashing for cache file names
- `intl`: Date formatting

---

## Architecture Overview

The app follows a layered architecture:

1. **Presentation Layer**: Screens and Widgets
2. **Business Logic Layer**: Services (Firestore, RSS, Notifications)
3. **Data Layer**: Models and Firestore
4. **Infrastructure Layer**: Firebase, HTTP, Local Storage

**State Management**: StatefulWidget with StreamBuilder for reactive data

**Navigation**: BottomNavigationBar with IndexedStack for tab persistence

**Authentication**: Firebase Auth with Google Sign-In and email/password

**Notifications**: FCM topic-based with local notification fallback

**Caching**: SharedPreferences for news items and user preferences

---

## Platform Support

- **Android**: Full support (notifications, deep linking)
- **iOS**: Full support (notifications, deep linking)
- **Web**: Limited support (no push notifications, CORS proxy for RSS)

---

## Security Considerations

- Firestore security rules enforce admin-only write access
- User roles stored in Firestore `users/{uid}/role`
- Guest mode allows read-only access to public content
- FCM tokens managed securely by Firebase SDK

---

## Future Enhancements

- Feedback collection system
- Enhanced diary features
- Project search and filtering
- Offline mode support
- Image upload for projects
- Social sharing enhancements

