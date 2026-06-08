# Planney

Planney is a collaborative group trip planning application that allows users to create trips, invite friends, and coordinate itineraries.

---

## Prerequisites

Before starting, ensure you have the following installed on your machine:
- **Flutter SDK** (compatible with Dart `^3.12.0`)
- **Node.js** (v18 or higher recommended)
- **MySQL Database Server**

---

## Project Structure
- `/backend` - Node.js Express server with MySQL connection.
- `/lib`, `/android`, `/ios`, `/web`, etc. - Flutter mobile and web application.

---

## Getting Started

### 1. Database Setup
Make sure your local MySQL server is running. Create a database for the application (e.g. `fullstack_db`):
```sql
CREATE DATABASE fullstack_db;
```

### 2. Backend Setup
1. Open a terminal and navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install the Node.js dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file in the `backend/` directory:
   ```env
   PORT=5000
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=fullstack_db
   JWT_SECRET=super_secret_alphanumeric_key_at_least_20_chars_long
   ```
4. Start the backend development server:
   ```bash
   npm run dev
   ```
   *Note: On startup, the backend automatically runs migrations to initialize all required tables (users, trips, itineraries, friendships, trip members).*

---

### 3. Frontend Setup
1. Open a separate terminal and navigate to the project root directory:
   ```bash
   cd ..
   ```
2. Get the Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the application:
   - For Android/iOS emulator/device:
     ```bash
     flutter run
     ```
   - For web:
     ```bash
     flutter run -d chrome
     ```

---

## IDE Setup Guide

### Visual Studio Code (Recommended)
1. **Open Workspace**: Open the root `Planney` folder in VS Code.
2. **Recommended Extensions**:
   - `Dart` and `Flutter` (for autocomplete, hot reload, and debugging)
   - `ESLint` and `Prettier` (for backend code styling)
3. **Running the Apps**:
   - Use the **Built-in Terminal** to run the backend (`cd backend && npm run dev`).
   - Use the **Run and Debug** tab (F5) or status bar device selector to select your device/simulator and run the Flutter application.

## 👥 Contributors

Meet the team behind Planney.

| Name | Responsibilities | GitHub |
|------|-----------------|--------|
| muffinism | Backend, final testing | [@muffinism](https://github.com/muffinism) |
| marissangls | Frontend | [@marissangls](https://github.com/marissangls) |
| Nicholas-Kenny | Backend, final testing | [@Nicholas-Kenny](https://github.com/Nicholas-Kenny) |