# TicketHub

Multi-Business Ticketing & Booking Marketplace — Mobile App Development Internship (Task #06), New AI Tech Softs.

## Tech Stack
- **Flutter** — cross-platform mobile UI
- **Provider** — state management (`AuthState`)
- **SharedPreferences** — local persistence for users/session (placeholder for a real backend; swap in an API/database service behind the same `AuthState` interface later)
- **uuid**, **intl** — IDs and date formatting

## Progress

### Day 1 — Planning, Setup & Authentication
- Defined architecture: Presentation → State → Service → Data layers
- Core models: `AppUser`, `Business`, `Listing`, `TicketType`
- `AuthState`: register, login, logout, role-based session persistence
- Screens: Splash (session check + role routing), Onboarding, Login, Registration (role toggle: Customer / Business Owner)

### Day 2 — Customer App UI
- Home screen: search bar, categories, featured businesses, upcoming events
- Categories screen (grid)
- Search screen (text + category filter)
- Business Listing screen (category filter + sort: Popular / Newest / Highest Rated)
- Business Details screen (profile info + its listings)
- Mock data layer (`mock_data.dart`) standing in for the backend until the API is wired up

### Day 3 — Business Owner Module
- `BusinessState`: register business, update business, add/update/delete listing — persisted locally
- Business Registration screen (name, category, description, location, contact phone)
- Business Owner Home: status card (Pending/Approved/Rejected/Suspended), listings overview, add listing shortcut
- Business Profile screen (view/edit existing business details)
- Add/Edit Listing screen (title, category, description, location, date, start/end time, seat-selection toggle)
- Login/Register/Splash now route Business Owners to their own home flow

### Day 6 — QR Validation, Dashboards & Admin
- Ticket validation for business staff: Valid / Already used / Cancelled / Invalid, with event details and Mark-as-Used
- Business dashboard: bookings, tickets sold, revenue, cancelled bookings, active listings, upcoming events, available / sold tickets, sales by event, revenue chart
- Business owner bookings list with status filters
- Admin module: dashboard with charts, business approval (Approve / Reject / Suspend / Reactivate), user management, booking management
- Approved businesses and their listings go live for customers automatically

### Day 7 — Notifications, Reviews, Search & Filters
- In-app notifications (booking confirmation, new booking, cancellation, event changes, business approval, ticket scanned, upcoming event reminders)
- Reviews and ratings after an attended (Used / Completed) booking, shown on business profiles, with admin moderation
- Event search with filters (category, date, price, availability) and sorting (Popular, Soonest, Price, Highest Rated)

## Demo Accounts
- Admin: admin@tickethub.com / admin123 (created automatically on first launch)
- Business Owner and Customer: register from the app

## Running
```
flutter pub get
flutter run
```

## Known Limitations (as of Day 3)
- Auth and business/listing data are local-only (SharedPreferences); not yet connected to a real backend/API
- Admin home/dashboard flow is not yet built
- Ticket types, pricing, seat selection, checkout, and QR flows are not yet implemented
- Business logo/cover image upload is not yet implemented (placeholder icon shown)
- Seed demo businesses (Grand Cinema, Alhamra Theatre, Soundwave Live, Skillverse) are static mock data shown alongside real approved businesses