# Wallet Flutter App - Setup Guide

This guide explains how to set up and run the Flutter application and its required backend.

## 1. Backend Requirements (`wallet-movement-api`)

The Flutter app depends on a NestJS API. Ensure the backend is configured as follows:

### Backend Environment Variables (`.env`)
Create a `.env` file in the `wallet-movement-api` root:
```env
# Database connection (PostgreSQL)
DATABASE_URL="postgresql://postgres:postgres@localhost:5438/wallet_database?schema=public"

# API Port
PORT=3000
```

### Database Initialization
1. Start the PostgreSQL database using Docker:
   ```bash
   docker compose -f docker/docker-compose.yml up -d
   ```
2. Push the Prisma schema to the database:
   ```bash
   npx prisma db push
   ```
3. (Optional) Seed the database with an initial balance for `wal-001` if needed.

---

## 2. Flutter App Setup (`wallet_flutter`)

### Environment Variables (`.env`)
Create a `.env` file in the `wallet_flutter` root:
```env
# URL of the Backend API
API_URL="http://127.0.0.1:3000"

# Mock User and Wallet IDs
USER_ID="usr-001"
WALLET_ID="wal-001"
```
*Note: If you are running on a physical Android/iOS device, replace `127.0.0.1` with your computer's local IP address.*

### Running the App
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run the application:
   ```bash
   flutter run
   ```

---

## 3. How it Works
- **Total Balance**: Fetched directly from the backend via `GET /wallet-balances/wal-001`.
- **Income/Expenses**: Calculated dynamically in the app based on the list of movements fetched from `GET /wallet-movements/wallet/wal-001`.
- **Clean Code**: The app uses `Provider` for state management and follow clean code principles for conciseness.
