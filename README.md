# durian.health (iOS)

The native iOS companion to the [durian.health](https://github.com/XinYanggg/fyp-website) web app. It lets durian farmers diagnose leaf diseases with their phone camera, manage farms and trees, and share farms with their team. The app is a client only: all data and AI inference go through the durian.health Next.js backend, the same one the [Android app](https://github.com/XinYanggg/fyp-android) uses.

## Key Features

-   **Introduction screen**: Signed-out users see an overview of the app, based on the website's landing page, before logging in or creating an account.
-   **AI Disease Scanner**: Take or pick a photo of a durian leaf and get a disease label with a confidence score. Results with 0% confidence cannot be saved.
-   **Home Dashboard**: Farm health at a glance, a scan shortcut and the trees that need attention.
-   **Farm Management**: Create farms and register trees (`Tree ID`, `Cultivar`). Filter trees by healthy or needing attention.
-   **Scan History**: Save diagnoses to a tree and review its full history. "Scan This Tree" opens the scanner with that tree selected.
-   **Team Collaboration**: The farm owner can add and remove members by email.
-   **Authentication**: Email/password registration (with email verification) and Google Sign-In. The session is kept in the Keychain and restored on launch.

## Tech Stack

-   **UI**: SwiftUI, with UIKit only for the camera picker
-   **Language**: Swift
-   **State**: Observation (`@Observable` stores injected through the environment)
-   **Networking**: `URLSession` with async/await
-   **Storage**: Keychain for the auth token and cached user
-   **Auth**: Backend-issued NextAuth JWT sent as `Authorization: Bearer <token>`. Native Google Sign-In via [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) (Swift Package Manager)
-   **Minimum iOS**: 27.2 (Xcode 27.2)

## Project Structure

```
durian.health/
├── Secrets.template.xcconfig       # Copy to Secrets.xcconfig (git-ignored)
├── durian-health-Info.plist        # Backend URL, Google IDs, camera permission
├── durian.health.xcodeproj
└── durian.health/
    ├── durian_healthApp.swift      # App entry, Google redirect handling
    ├── RootView.swift              # Welcome vs. signed-in UI
    ├── MainTabView.swift           # Home, Farms, Scan, Profile tabs
    ├── Core/
    │   ├── Auth/AuthStore.swift    # Login, register, Google, session restore
    │   ├── Config/AppConfig.swift  # Backend URL and Google configuration
    │   ├── Farms/FarmStore.swift   # Farms, trees, members and scans
    │   ├── Models/                 # Codable models matching the backend
    │   ├── Navigation/             # Cross-tab navigation
    │   ├── Networking/APIClient.swift
    │   ├── Storage/KeychainStore.swift
    │   └── UI/                     # Theme, StatusBadge, AvatarView
    └── Features/
        ├── Welcome/                # Introduction screen
        ├── Auth/                   # Login, register, Google button
        ├── Home/                   # Dashboard
        ├── Farms/                  # Farms, farm detail, tree detail, members
        ├── Scan/                   # Photo capture, detection, saving
        └── Profile/
```

## Prerequisites

-   A Mac with Xcode 27.2 or later
-   An iOS 27.2+ simulator or device
-   The [durian.health web backend](https://github.com/XinYanggg/fyp-website) running locally or deployed
-   For Google Sign-In: a Google Cloud project with OAuth credentials (see [Google Sign-In](#google-sign-in))

## Getting Started

1. Clone the repository
    ```bash
    git clone https://github.com/XinYanggg/durian.health.git
    cd durian.health
    ```
2. Create your secrets file
    ```bash
    cp Secrets.template.xcconfig Secrets.xcconfig
    ```
    Fill in the values (see [Configuration](#configuration)). Both Debug and Release builds need this file.
3. Start the backend. For local development, run it from the `fyp-website` folder:
    ```bash
    npm run dev
    ```
4. Open `durian.health.xcodeproj` in Xcode. Swift packages resolve automatically.
5. Choose an iPhone simulator and press **Run** (⌘R).

## Configuration

All settings live in `Secrets.xcconfig`, which is git-ignored. Xcode fills them into `durian-health-Info.plist` at build time.

| Setting                       | Description                                                                                                  |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `API_BASE_URL`                | Deployed backend used by **Release** builds, no trailing slash. Write `//` as `$(SLASH)$(SLASH)`, because xcconfig treats `//` as a comment. |
| `GOOGLE_WEB_CLIENT_ID`        | The **Web** OAuth client ID. Must equal `GOOGLE_CLIENT_ID` on the backend.                                   |
| `GOOGLE_IOS_CLIENT_ID_PREFIX` | The **iOS** OAuth client ID without `.apps.googleusercontent.com`. Leave empty to hide the Google button.    |

```
SLASH = /
API_BASE_URL = https:$(SLASH)$(SLASH)your-domain.com
GOOGLE_WEB_CLIENT_ID = 1234567890-xxxxxxxx.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID_PREFIX = 1234567890-yyyyyyyy
```

### Backend URL

-   **Debug** builds use `http://localhost:3000`. This works in the iOS Simulator, and iOS allows plain HTTP to `localhost`.
-   **Release** builds use `API_BASE_URL`.
-   **Physical device in Debug**: `localhost` points to the phone itself. Add an `APIBaseURLDebug` key to `durian-health-Info.plist` with your Mac's LAN address, e.g. `http://192.168.1.20:3000`. Non-localhost HTTP also needs an App Transport Security exception.

## Google Sign-In

The app signs in with Google natively, then sends the Google ID token to the backend, which returns the app's own session token.

1. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials), open the project that holds the website's OAuth client.
2. Create an OAuth client ID of type **iOS** with bundle ID `com.farnxinyang.durian-health`.
3. Set `GOOGLE_IOS_CLIENT_ID_PREFIX` in `Secrets.xcconfig` to the new client ID without the `.apps.googleusercontent.com` suffix.
4. Set `GOOGLE_WEB_CLIENT_ID` to the website's **Web** client ID (`GOOGLE_CLIENT_ID` in its `.env.local`).

The ID token's audience is the web client ID, which is what `POST /api/mobile/google` checks. If the iOS client ID is missing, the Google button is hidden and email login still works.

## How the App Talks to the Backend

The app uses the same endpoints as the Android app. Authenticated requests send `Authorization: Bearer <token>`.

| Endpoint                     | Method | Purpose                                                                 |
| ---------------------------- | ------ | ----------------------------------------------------------------------- |
| `/api/mobile/login`          | POST   | Email/password login, returns `{ token, user }`                          |
| `/api/mobile/google`         | POST   | Exchange a Google ID token for `{ token, user }`                         |
| `/api/mobile/me`             | GET    | Verify the stored token on launch. A 401 signs the user out              |
| `/api/register`              | POST   | Create an account. The backend emails a verification link                |
| `/api/farm/get`              | GET    | All farms the user is a member of                                        |
| `/api/farm/add`              | POST   | Create a farm                                                            |
| `/api/farm/tree/add`         | POST   | Add a tree to a farm                                                     |
| `/api/farm/member/add`       | POST   | Add a member by email (owner only)                                       |
| `/api/farm/member/remove`    | POST   | Remove a member (owner only)                                             |
| `/api/scan/detect`           | POST   | Multipart upload (`file`) to the AI model. Returns `{ prediction, confidence }` with confidence as 0–1 |
| `/api/scan/save`             | POST   | Save a diagnosis to a tree. Confidence is stored as a percentage         |

Before upload, photos are resized to at most 1600 px on the long side and sent as JPEG. Disease names such as `algal_leaf_spot` are shown as `Algal Leaf Spot`, the same as on the website.

## Troubleshooting

-   **"Cannot connect to the server"**: check that the backend is running on port 3000 (Debug) or that `API_BASE_URL` is correct (Release).
-   **Build fails with missing settings or `Secrets.xcconfig` not found**: create it from `Secrets.template.xcconfig`.
-   **Google button doesn't appear**: `GOOGLE_IOS_CLIENT_ID_PREFIX` is empty.
-   **"Google token audience mismatch"**: `GOOGLE_WEB_CLIENT_ID` doesn't match the backend's `GOOGLE_CLIENT_ID`.
-   **"Your email is not verified"**: open the verification link sent after registration, then log in again.

## Author

Farn Xin Yang (TP074541). Improving durian tree health. Developed under the supervision of Dr. Kulothunkan A/L Palasundram.

SDG 12: Responsible Consumption and Production
