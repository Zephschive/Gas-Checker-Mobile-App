# Gas Eye App

## Overview
Gas Eye App is a Flutter application designed to monitor gas readings and statuses in real-time using Firebase Realtime Database. The app provides users with an intuitive interface to view gas history and current readings.

## Features
- Real-time updates of gas readings and statuses.
- User-friendly dashboard to display gas data.
- Integration with Firebase for data storage and retrieval.

## Project Structure
```
gascheckerapp
├── android                # Android platform-specific code
├── ios                    # iOS platform-specific code
├── lib                    # Main application code
│   ├── main.dart          # Entry point of the application
│   ├── firebase_options.dart # Firebase configuration options
│   ├── pages              # Contains different pages of the app
│   │   ├── pagesExt.dart  # Additional page definitions
│   │   └── home_dashboard.dart # Dashboard for displaying gas readings
│   ├── services           # Services for handling Firebase operations
│   │   └── firebase_service.dart # Firebase service for data operations
│   ├── models             # Data models for the application
│   │   └── gas_history.dart # Model for gas history entries
│   └── widgets            # Reusable widgets
│       └── gas_tile.dart  # Widget for displaying individual gas readings
├── pubspec.yaml           # Flutter project configuration file
├── .firebaserc            # Firebase project configuration settings
├── firebase.json          # Firebase hosting configuration settings
└── README.md              # Project documentation
```

## Setup Instructions
1. Clone the repository:
   ```
   git clone <repository-url>
   cd gascheckerapp
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Configure Firebase:
   - Create a Firebase project in the Firebase Console.
   - Add your app to the Firebase project and download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS).
   - Place these files in the respective directories.

4. Update `firebase_options.dart` with your Firebase configuration.

5. Run the app:
   ```
   flutter run
   ```

## Usage
- Upon launching the app, users will see a splash screen followed by the home dashboard.
- The dashboard will display real-time gas readings and statuses fetched from the Firebase Realtime Database.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for details.