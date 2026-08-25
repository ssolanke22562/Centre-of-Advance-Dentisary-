# Dr. Patil's Centre of Advance Dentistry - Mobile Application

A cross-platform mobile application (Android & iOS) tailored for **"Dr. Patil's Centre of Advance Dentistry"**, built with **Flutter**, **Riverpod**, and **local SQLite**. The application streamlines patient intake, front-desk queue management, and administration in a 100% offline environment.

---

## 🔑 Pre-Registered Staff Credentials

The app ships with salted SHA-256 encrypted credentials initialized locally in SQLite on first run:

| Role | Email | Password |
| :--- | :--- | :--- |
| **Admin** | `admin@drpatil.com` | `Admin@123` |
| **Reception Desk 1** | `reception1@drpatil.com` | `Reception@123` |
| **Reception Desk 2** | `reception2@drpatil.com` | `Reception@123` |

*(Quick-fill demo chips are available on the Login screen for testing.)*

---

## 🏥 Architecture & Key Features

### 1. Security & Offline-First Data Architecture
- **Salted Password Hashing**: Passwords are never stored in plaintext. Each account is hashed with a per-install cryptographic salt via SHA-256.
- **Secure Session Storage**: Sessions are managed with `flutter_secure_storage` (iOS Keychain / Android EncryptedSharedPreferences) with auto-expiry thresholds and a logout action.
- **Data-Layer Privacy Enforcement**: Receptionists can only query `id`, `name`, and `registration_date` from SQLite. Sensitive medical history, contact info, and payment records are omitted at the database query level for non-admin roles.
- **Permanent Image Storage**: Patient profile photos are stored as image files in the app's local documents directory (`path_provider`), with only file paths stored in SQLite to avoid query bloat.

### 2. Receptionist Module
- **Patient Registration Form**:
  - Mandatory fields: Name, Age (0–120), Sex (Male/Female/Other), Visit Type (First Time vs Already Consulted), Primary Phone (10 digits), Secondary Phone (10 digits), Address.
  - Optional fields: Last Consultation Date, Chief Problem / Complaint, Patient Photo (Camera/Gallery picker with fallback handling).
  - Auto-generated Serial Number (`Sr. No`) upon submission.
- **Grace Window Editing**: Receptionists can fix typographical errors in patient names within a grace window immediately after submission.
- **Reception Patient List**: Minimal list displaying only `Sr. No` and `Patient Name`.

### 3. Admin Module
- **Dashboard Analytics**: Real-time counts for Total Patients, Today's Appointments, and Pending Payments.
- **Patient Queue**: Filterable by name/phone/Sr. No, registration date range, and payment status (`All`, `Pending`, `Paid`).
- **Interactive Payment Status**: One-tap toggle between `Pending` and `Paid`.
- **Double-Booking Prevention**: Appointment scheduler checks for conflicts within a ±30 minute window and displays overlap warnings.
- **Patient History & Profile**: View complete form data, photo, appointment timeline, full edit modal, and soft-delete flag.
- **Data Export & Backup**:
  - **CSV Export**: RFC-compliant CSV containing all non-deleted patients and joined appointment logs. Shared via `share_plus` (Android 13+ scoped storage compliant).
  - **Database Backup**: Local SQLite database export.

---

## 📁 Project Directory Structure

```
Dentist/
├── android/
│   └── app/src/main/AndroidManifest.xml   # Camera & storage permissions
├── ios/
│   └── Runner/Info.plist                  # Camera & photo permissions
├── lib/
│   ├── database/
│   │   └── db_helper.dart                 # SQLite schema, migrations & CRUD
│   ├── models/
│   │   ├── appointment_model.dart         # Appointment model
│   │   ├── patient_model.dart             # Patient & MinimalPatient models
│   │   └── user_model.dart                # User & session models
│   ├── providers/
│   │   ├── appointment_provider.dart      # Appointment state & conflicts
│   │   ├── auth_provider.dart             # Auth StateNotifier
│   │   ├── patient_provider.dart          # Patient queue & filter providers
│   │   └── stats_provider.dart            # Analytics stats
│   ├── screens/
│   │   ├── admin/
│   │   │   ├── tabs/
│   │   │   │   ├── admin_export_tab.dart
│   │   │   │   ├── admin_queue_tab.dart
│   │   │   │   └── admin_schedule_tab.dart
│   │   │   ├── widgets/
│   │   │   │   ├── edit_patient_dialog.dart
│   │   │   │   └── schedule_appointment_dialog.dart
│   │   │   ├── admin_dashboard.dart
│   │   │   └── patient_profile_screen.dart
│   │   ├── reception/
│   │   │   ├── widgets/
│   │   │   │   ├── patient_registration_form.dart
│   │   │   │   ├── reception_edit_dialog.dart
│   │   │   │   └── reception_patient_list.dart
│   │   │   └── reception_dashboard.dart
│   │   ├── login_screen.dart
│   │   └── splash_screen.dart
│   ├── services/
│   │   ├── auth_service.dart              # Salted SHA-256 + SecureStorage
│   │   ├── export_service.dart            # CSV & DB backup sharing
│   │   └── image_service.dart             # Image capture & persistence
│   ├── theme/
│   │   └── app_theme.dart                 # Premium clinical teal design
│   ├── widgets/
│   │   └── custom_widgets.dart            # Reusable UI components
│   └── main.dart                          # App entry & ProviderScope
└── pubspec.yaml                           # Dependencies
```

---

## 🚀 How to Run the App

1. Ensure Flutter 3.10+ is installed on your system.
2. Navigate to the project root directory:
   ```bash
   cd Dentist
   ```
3. Fetch all dependencies:
   ```bash
   flutter pub get
   ```
4. Run on a connected device, emulator, or simulator:
   ```bash
   flutter run
   ```
