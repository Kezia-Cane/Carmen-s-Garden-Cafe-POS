# Carmen's Garden Cafe - Flutter POS
## Quick Reference Guide (Antigravity IDE)

---

## 🚀 PROJECT OVERVIEW

| Aspect | Details |
|--------|---------|
| **App Name** | Carmen's Garden POS |
| **Platform** | Flutter (Android 5.0+) |
| **Target Device** | OUKITEL WP18 (5.93" HD+, 4GB RAM) |
| **IDE** | Antigravity IDE |
| **Database Local** | SQLite (sqflite) |
| **Database Cloud** | Supabase (PostgreSQL) |
| **Scope** | Single Device (One terminal per shop) |
| **Mode** | Offline-First with Auto Sync |

---

## 🎨 BRAND COLORS

```
Primary Green:    #3b5006  (Dark Forest Green)
Primary Lime:     #a8bd06  (Lime Green)
Accent Yellow:    #e7e80e  (Bright Yellow)
Light Cream:      #f8f7f0  (Off-white background)
Dark Brown:       #272007  (Text color)
Error Red:        #d32f2f  (Error states)
```

---

## 📁 QUICK FILE LOCATIONS

```
lib/
├── main.dart                      ← App entry point
├── app.dart                       ← Router setup
├── config/
│   ├── color_palette.dart        ← Carmen's colors
│   └── theme.dart                ← Material Design 3
├── services/
│   ├── sync_service.dart         ← Core sync logic
│   ├── order_service.dart        ← Order management
│   └── connectivity_service.dart ← Network monitoring
├── ui/screens/
│   ├── pos/pos_terminal_screen.dart    ← Main POS
│   ├── checkout_screen.dart            ← Payment
│   └── orders/orders_list_screen.dart  ← Order history
└── providers/
    ├── cart_provider.dart        ← Current cart state
    ├── order_provider.dart       ← Orders list
    └── sync_provider.dart        ← Sync status
```

---

## ⚡ KEY PERFORMANCE OPTIMIZATIONS

| Optimization | Details |
|--------------|---------|
| **Memory** | <200MB footprint (4GB RAM available) |
| **Animations** | Lightweight, device-aware |
| **Database** | SQLite with indexes, <10MB |
| **Caching** | Image cache <50MB |
| **UI Rendering** | Lazy loading, RepaintBoundary |
| **Network** | Batch sync, exponential backoff |

---

## 🔄 OFFLINE/ONLINE FEATURE MATRIX

| Feature | Offline | Online |
|---------|---------|--------|
| Browse Menu | ✅ | ✅ |
| Add to Cart | ✅ | ✅ |
| Create Order | ✅ | ✅ |
| Accept Cash | ✅ | ✅ |
| Update Status | ✅ | ✅ |
| Inventory Mgmt | ✅ | ✅ |
| View Reports | ✅ (Local) | ✅ (Cloud) |
| Sync to Supabase | ❌ | ✅ |
| Real-time Updates | ❌ | ✅ |
| Cloud Backup | ❌ | ✅ |

---

## 📊 DATABASE STRUCTURE

### Local (SQLite)
```
users                 → Login credentials
menu_items           → Menu (cached)
categories           → Item categories
orders               → Daily orders
order_items          → Order line items
inventory            → Stock levels
payments             → Payment records
sync_queue           → Pending operations
sales_reports        → Daily summaries
```

### Cloud (Supabase)
Same schema, with real-time subscriptions and backups

---

## 🔐 SECURITY CHECKLIST

- ✅ Credentials stored in `.env` (never in code)
- ✅ Secure storage for JWT tokens
- ✅ Password hashing (bcrypt)
- ✅ Input validation on all forms
- ✅ HTTPS only for Supabase
- ✅ Row-level security (RLS) on tables
- ✅ No sensitive data logged
- ✅ API key rotation capability

---

## 🛠️ ANTIGRAVITY IDE SETUP

### 1. Create New Project
```bash
antigravity create --template flutter_app
cd carmen_garden_pos
```

### 2. Add Dependencies
```bash
flutter pub add supabase_flutter dio riverpod freezed_annotation json_serializable
flutter pub add --dev riverpod_generator build_runner freezed
```

### 3. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure Supabase
```bash
# Create .env file
echo "SUPABASE_URL=https://xxxxx.supabase.co" > .env
echo "SUPABASE_ANON_KEY=eyJ..." >> .env
```

### 5. Run App
```bash
flutter run -d <device_id>
```

---

## 📱 DEPLOYMENT STEPS

### Android APK Build

**1. Create signing key:**
```bash
keytool -genkey -v -keystore ~/carmen_key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias carmen_garden
```

**2. Sign app:**
```bash
flutter build apk --release --split-per-abi
```

**3. Install on device:**
```bash
adb install -r build/app/outputs/flutter-app.apk
```

**4. Verify on device:**
- Check: Settings → Apps → Carmen's Garden POS
- Check: Offline POS works without internet
- Check: Sync works when online
- Check: Memory usage <200MB

---

## 🔄 SYNC WORKFLOW

```
1. USER WORKS OFFLINE
   └─ Creates order
   └─ Data saved to SQLite
   └─ Added to sync_queue

2. DEVICE COMES ONLINE
   └─ Connectivity detected
   └─ SyncService triggers

3. BATCH UPLOAD
   └─ All pending operations queued
   └─ POST to Supabase
   └─ Server validates & processes

4. RESPONSE RECEIVED
   └─ Successful: Mark as synced, delete from queue
   └─ Failed: Retry with exponential backoff
   └─ Merge server updates locally

5. UI UPDATES
   └─ Riverpod providers invalidated
   └─ UI reflects latest state
   └─ User sees "✓ Sync complete"
```

---

## ⚙️ CONFIGURATION CONSTANTS

```dart
// Device limits
MAX_APP_MEMORY_MB = 200
SQLITE_CACHE_MB = 8
IMAGE_CACHE_MB = 50

// Sync settings
SYNC_INTERVAL = 30 minutes
MAX_RETRY_ATTEMPTS = 5
BACKOFF_MULTIPLIER = 2x

// Tax rate
TAX_RATE = 0.08 (8%)

// UI
MIN_API = 21 (Android 5.0)
TARGET_API = 33 (Android 13)
```

---

## 🐛 TROUBLESHOOTING

### App Won't Start
```bash
# Clear cache & rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### High Memory Usage
- Check image caching limits
- Clear app cache: Settings → Apps → Carmen's Garden → Storage → Clear Cache
- Restart device

### Sync Not Working
- Check internet connection
- Check Supabase credentials in `.env`
- Ensure device can reach `https://xxxxx.supabase.co`
- Check sync_queue table for errors

### Freezing/Lag
- Check SQLite query indexes
- Monitor with: `adb logcat | grep flutter`
- Profile with: DevTools Performance tab

---

## 📈 MONITORING

### Check App Performance
```bash
# Show memory usage
adb shell dumpsys meminfo com.carmensgarden.pos

# Show FPS
adb shell dumpsys gfxinfo com.carmensgarden.pos
```

### View Logs
```bash
adb logcat -s flutter
```

### Database Inspection (Debug)
```dart
// In Android Studio debugger
Database db = await DatabaseHelper.instance.database;
List<Map> orders = await db.query('orders');
print(orders);
```

---

## 📝 EXAMPLE WORKFLOWS

### Workflow 1: Create & Complete Order (Offline)

```
1. Tap "Cappuccino" → Add to cart
2. Modify: Size → Large (+$0.50)
3. Modify: Milk → Oat (+$0.60)
4. Quantity: 2
5. Special: "Extra hot, no foam"
6. Cart total: $10.20
7. Tap "Checkout"
8. Payment: Cash, $20 tendered
9. Change: $9.80
10. Order complete → Print receipt
11. Status: Ready for customer
```

### Workflow 2: Order Status Updates (Offline)

```
1. Orders screen
2. See "Pending" tab
3. Tap order #142
4. See all items
5. Tap "Start Preparing"
6. Items move to "Preparing" status
7. Tap "Ready"
8. Notify customer (manual)
```

### Workflow 3: Automatic Sync (Online)

```
1. Phone connects to WiFi
2. SyncService detects connection
3. Shows "Syncing..." indicator
4. Batches 15 orders from sync_queue
5. POSTs to Supabase
6. Server validates all orders
7. Returns success response
8. Deletes from sync_queue
9. Shows "✓ Sync complete"
10. All orders now in cloud backup
```

---

## 🎯 NEXT STEPS AFTER DEPLOYMENT

1. **Test thoroughly on OUKITEL WP18** for 1 week
2. **Gather staff feedback** on usability
3. **Monitor sync reliability** - aim for 99.9%
4. **Optimize based on real usage patterns**
5. **Consider Phase 2 features:**
   - Card payment integration
   - Customer loyalty program
   - Web manager dashboard
   - Multi-location support

---

## 📞 SUPPORT RESOURCES

| Resource | Link |
|----------|------|
| Flutter Docs | https://docs.flutter.dev |
| Supabase Docs | https://supabase.com/docs |
| Antigravity Docs | https://antigravity.dev/docs |
| Dart Language | https://dart.dev |
| Riverpod Guide | https://riverpod.dev |

---

## 📋 FINAL DEPLOYMENT CHECKLIST

**Before deploying to production:**

- [ ] All unit tests pass: `flutter test`
- [ ] No lint warnings: `flutter analyze`
- [ ] Memory usage confirmed <200MB
- [ ] Offline POS fully functional
- [ ] Sync tested (upload/download/conflict)
- [ ] Supabase credentials in `.env`
- [ ] APK signed with production key
- [ ] Tested on OUKITEL WP18 for 24 hours
- [ ] Receipt printing tested
- [ ] Reports accuracy verified
- [ ] Backup/restore process documented
- [ ] User manual completed
- [ ] Staff training conducted
- [ ] Monitoring setup ready

---

**Status: Ready for Production Deployment** ✅

Built with: Flutter | Dart | SQLite | Supabase | Antigravity IDE
Optimized for: OUKITEL WP18 | Single Device | Offline-First