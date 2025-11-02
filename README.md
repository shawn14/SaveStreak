# SaveStreak - Daily Savings Habit Tracker

Turn saving money into a simple daily habit with streaks, progress tracking, and motivational reminders.

## Overview

SaveStreak is an iOS app that gamifies saving money by combining:
- **Savings Goals** - Set target amounts with deadlines
- **Micro-Savings** - Small daily or weekly saving targets
- **Streak Tracking** - Visual motivation to maintain consistent saving habits
- **Local Notifications** - Daily reminders (no backend required)
- **In-App Purchases** - Freemium model with premium features

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Apple's data persistence framework (iOS 17+)
- **UserNotifications** - Local push notifications
- **StoreKit 2** - In-App Purchases
- **iOS 18.5+** - Minimum deployment target

## Project Structure

```
save.streak/
├── Models/
│   ├── SavingsGoal.swift         # Main savings goal model
│   ├── SaveEntry.swift           # Individual save transaction
│   └── UserPreferences.swift     # App settings & preferences
├── Services/
│   ├── NotificationManager.swift # Local notification handling
│   ├── StreakCalculator.swift    # Streak logic & calculations
│   └── StoreManager.swift        # IAP with StoreKit 2
├── ViewModels/
│   └── DashboardViewModel.swift  # Dashboard business logic
├── Views/
│   ├── DashboardView.swift       # Main app screen
│   ├── GoalSetupView.swift       # Create/edit goals
│   ├── HistoryView.swift         # Save history
│   ├── SettingsView.swift        # App settings
│   └── PaywallView.swift         # Premium upgrade screen
├── ContentView.swift             # App entry point
└── save_streakApp.swift          # App configuration
```

## Features

### Core Features (Free Tier)
- ✅ Single active savings goal
- ✅ Daily or weekly saving targets
- ✅ Streak tracking with visual fire icons
- ✅ Progress bars and stats
- ✅ Daily notification reminders
- ✅ Save history with monthly grouping
- ✅ Motivational messages

### Premium Features ($1.99/mo or $14.99/yr)
- 🔒 Unlimited savings goals
- 🔒 Multiple daily reminders (morning + evening)
- 🔒 Advanced statistics
- 🔒 Custom themes (coming soon)
- 🔒 AI-powered saving tips (coming soon)
- 🔒 iCloud sync (coming soon)

## Setup Instructions

### 1. Open in Xcode
```bash
cd /Users/shawncarpenter/Desktop/save.streak
open save.streak.xcodeproj
```

### 2. Configure App Store Connect (For IAP)

Before IAP will work, you need to:

1. **Create App in App Store Connect**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Create a new app with bundle ID: `com.savestreak.save-streak`

2. **Create In-App Purchase Products**
   - Navigate to Features → In-App Purchases
   - Create two **Auto-Renewable Subscriptions**:
     - **Monthly**: Product ID `com.savestreak.premium.monthly` - Price: $1.99
     - **Yearly**: Product ID `com.savestreak.premium.yearly` - Price: $14.99
   - Set subscription group name (e.g., "Premium Features")

3. **Update StoreManager.swift** (if needed)
   - Product IDs are already configured in `Services/StoreManager.swift:14-17`
   - Verify they match your App Store Connect products

### 3. Testing Notifications

Notifications require a **real device** (Simulator doesn't support notifications properly):

1. Build and run on a physical iPhone
2. When prompted, allow notifications
3. Go to Settings in the app
4. Enable reminders and set a time
5. Lock your device and wait for the notification

### 4. Testing In-App Purchases

1. **Create Sandbox Tester** in App Store Connect:
   - Users and Access → Sandbox Testers
   - Add a new tester account

2. **Sign in on Device**:
   - Settings → App Store → Sandbox Account
   - Sign in with your sandbox tester credentials

3. **Test Purchase Flow**:
   - In app, tap Settings → Upgrade to Premium
   - Purchase will use sandbox environment (no real charge)

### 5. Build and Run

1. Select your development team in Xcode project settings
2. Select a device (iPhone with iOS 18.5+)
3. Build and run (⌘R)

## Key Screens

### Dashboard
- Main screen showing current goal progress
- Big "Log Save" button for quick entry
- Streak counter with fire icons
- Progress bar and stats
- Recent activity feed

### Goal Setup
- Create new savings goals
- Set target amount and deadline
- Choose daily/weekly frequency
- Estimated timeline calculation

### History
- Chronological list of all saves
- Grouped by month
- Swipe to delete entries
- Summary statistics

### Settings
- Notification preferences
- Premium status
- Goal management
- App information

### Paywall
- Premium features showcase
- Monthly/yearly subscription options
- Purchase and restore functionality

## Data Models

### SavingsGoal
- Target amount (stored in cents)
- Deadline date
- Daily/weekly saving target
- Current streak counter
- Related save entries (cascade delete)

### SaveEntry
- Amount saved (in cents)
- Timestamp
- Optional note
- Relationship to parent goal

### UserPreferences
- Notification settings
- Premium status
- Theme preferences
- Feature flags

## Next Steps

### Must-Do Before Launch
1. ✅ All code implemented
2. ⚠️ Configure IAP in App Store Connect
3. ⚠️ Test on real device (notifications + IAP)
4. ⚠️ Add app icon (Assets.xcassets/AppIcon.appiconset)
5. ⚠️ Create screenshots for App Store
6. ⚠️ Write App Store description
7. ⚠️ Privacy policy & terms of service URLs (update in SettingsView.swift:211-212)

### Optional Enhancements
- [ ] Add charts/graphs for savings history
- [ ] Implement CloudKit sync for multi-device
- [ ] Add AI-powered saving tips (GPT-4 API)
- [ ] Custom color themes
- [ ] Widget support for home screen
- [ ] Apple Watch companion app
- [ ] Export data (CSV/PDF)
- [ ] Savings insights & analytics

## Testing Checklist

- [ ] Create a goal successfully
- [ ] Log a save (quick button)
- [ ] Log a custom amount
- [ ] Verify streak increments correctly
- [ ] Test daily vs weekly mode
- [ ] Receive notification at scheduled time
- [ ] Complete a goal (100% progress)
- [ ] Delete save entries
- [ ] Delete goals
- [ ] Restore IAP purchases
- [ ] Free tier limits (1 goal max)
- [ ] Premium unlocks multiple goals
- [ ] Settings persist across app restarts

## Known Considerations

### SwiftData Storage
- All data stored locally in SwiftData
- Persists between app launches
- No cloud backup initially (can add CloudKit later)

### Notifications
- Local only (no server needed)
- Re-scheduled when settings change
- Requires notification permissions from user

### IAP
- StoreKit 2 used (modern API)
- Subscription auto-renewal handled by Apple
- Receipt validation needed for production

### iOS 18.5 Target
- Uses latest SwiftUI features
- SwiftData requires iOS 17+
- Consider lowering to iOS 17.0 for wider reach

## Business Model

### Pricing
- Free: 1 goal, basic features
- Premium: $1.99/month or $14.99/year
- Target: 2% conversion rate

### Cost Analysis
- Zero server costs (all local)
- Minimal AI costs if added (~$0.03/1K tokens)
- Apple takes 30% (15% after year 1)

### Revenue Projection
- 5,000 downloads × 2% conversion = 100 paid users
- 100 users × $15/year = $1,500/year gross
- After Apple's cut: ~$1,050/year net

## Resources

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [StoreKit 2 Guide](https://developer.apple.com/documentation/storekit)
- [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)
- [App Store Connect](https://appstoreconnect.apple.com)

## License

All rights reserved. This is a proprietary application.

---

**Built with Claude Code** 🤖

Questions? Check the inline code comments - they're beginner-friendly!
