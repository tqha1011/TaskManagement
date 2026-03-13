
# Flutter App Architecture

**TaskManagement App** is built based on **Feature-Based MVVM**
Architecture

In each feature, we organize the folders based on **MVVM** Architecture

### 1. core
- `.env`: Contains **Supabase URL** and secrets key
- **Themes & Constants**: Stores global UI configurations and constant values.

### 2. features
- `model`: Contains classes to define data
- `view`: Contains UI widgets
- `viewmodel`: Implements business logic and handles state management.
- `services`: Handles data operations and communicates with the Supabase Backend.
```plaintext
.
└── 📂 src/
    ├── 📂 android
    ├── 📂 ios
    ├── 📂 lib/
    │   ├── 📂 core
    │   ├── 📂 features/
    │   │   ├── 📂 auth/
    │   │   │   ├── 📂 model
    │   │   │   ├── 📂 view
    │   │   │   ├── 📂 viewmodel
    │   │   │   └── 📂 services
    │   │   └── 📂 ...
    │   └── main.dart
    ├── 📂 test
    ├── pubspec.lock
    ├── pubspec.yaml
    └── .metadata

```


