# Kadam Badge System Guide

## Overview
Kadam uses an achievement badge system to motivate users and track their progress. Badges are automatically unlocked when users reach specific milestones in steps, gait improvement, and scan consistency.

---

## Badge Types

### 1. **Step Milestone Badges** 👣
Awarded when you reach cumulative step milestones (tracked from device step counter):

| Badge | Name | Threshold | Emoji | Color |
|-------|------|-----------|-------|-------|
| **First Steps** | `steps_1k` | 1,000 steps | 👣 | Indigo (#6366F1) |
| **Getting There** | `steps_5k` | 5,000 steps | 🚶 | Purple (#8B5CF6) |
| **Daily Goal** | `steps_10k` | 10,000 steps | 🏃 | Green (#22C55E) |
| **Power Walker** | `steps_25k` | 25,000 steps | 💪 | Orange (#F59E0B) |
| **Marathoner** | `steps_50k` | 50,000 steps | 🏆 | Red (#EF4444) |
| **Ultra Walker** | `steps_100k` | 100,000 steps | 👑 | Gold (#FFD700) |

**How it works:**
- Steps are tracked continuously via device pedometer sensor
- Badges checked every time step count updates
- Only the highest milestone reached is awarded (you don't get all badges at once)
- Cumulative total steps tracked across all days

---

### 2. **Gait Improvement Badges** 📈
Awarded when your gait health score improves consecutively across scans:

| Badge | Name | Threshold | Emoji | Color |
|-------|------|-----------|-------|-------|
| **On the Rise** | `improve_3` | 3 consecutive improvements | 📈 | Green (#22C55E) |
| **Consistent Progress** | `improve_5` | 5 consecutive improvements | ⭐ | Indigo (#6366F1) |
| **Master Walker** | `improve_10` | 10 consecutive improvements | 🌟 | Orange (#F59E0B) |

**How it works:**
- Tracks your gait health score from each scan
- Compares current score to previous score
- **Improvement** = current score > previous score
- **Streak resets to 0** if score doesn't improve or decreases
- Badge unlocked when streak reaches threshold (3, 5, or 10)

**Example:**
```
Scan 1: Score 60 → Scan 2: Score 65 ✓ (streak = 1)
Scan 2: Score 65 → Scan 3: Score 70 ✓ (streak = 2)
Scan 3: Score 70 → Scan 4: Score 75 ✓ (streak = 3) 🎉 Badge unlocked!
Scan 4: Score 75 → Scan 5: Score 73 ✗ (streak = 0, reset)
```

---

### 3. **Consistency Badges** 🔥
Awarded for scanning regularly on consecutive days:

| Badge | Name | Threshold | Emoji | Color |
|-------|------|-----------|-------|-------|
| **Week Warrior** | `scan_7` | 7 consecutive days | 🔥 | Red (#EF4444) |
| **Month Master** | `scan_30` | 30 consecutive days | 🎯 | Purple (#8B5CF6) |

**How it works:**
- Tracks consecutive days of scanning
- **Consecutive** = scanning on consecutive calendar days
- If you miss a day, streak resets to 1 (current scan)
- Only counts one scan per day (multiple scans same day = same count)
- Badge unlocked when streak reaches threshold (7 or 30 days)

**Example:**
```
Day 1: Scan ✓ → Day 2: Scan ✓ → Day 3: Scan ✓ → ... → Day 7: Scan ✓ 🎉 Badge unlocked!
Day 8: No scan ✗ → Day 9: Scan ✓ (streak resets to 1)
```

---

## When Badges Are Checked

### Step Milestones
- **Checked:** Every time step count updates from device sensor
- **Location:** `lib/screens/landing_page.dart` - Step counter listener
- **Trigger:** Real-time step updates from `StepCounterService`

### Gait Improvement
- **Checked:** After each gait scan completes
- **Location:** `lib/widgets/enhanced_scan_screen.dart` - After `_completeScan()`
- **Trigger:** When scan result is added to history

### Scan Consistency
- **Checked:** After each gait scan completes
- **Location:** `lib/widgets/enhanced_scan_screen.dart` - After `_completeScan()`
- **Trigger:** When scan result is added to history

---

## Badge Storage

Badges are stored persistently using `SharedPreferences`:
- **Location:** Device local storage (persists after app restart)
- **Stored Data:**
  - List of unlocked badges (JSON format)
  - Total steps tracked
  - Current improvement streak
  - Current scan streak
  - Last scan date

**File:** `lib/providers/badge_provider.dart`

---

## Badge Display

### Profile Page
- **Location:** Profile screen → "Badges" section
- **Display:** Grid layout (3 columns)
- **Info Shown:**
  - Badge emoji (large)
  - Badge name
  - Unlock date ("Today", "Yesterday", "X days ago", or date)

### Badge Unlock Notifications
- **Location:** Shown as SnackBar when badge is unlocked
- **Display:** 
  - Badge emoji
  - "Badge Unlocked!" message
  - Badge name
  - Color-coded background (matches badge color)

---

## Code Implementation

### Badge Provider
`lib/providers/badge_provider.dart`
- Manages all badge logic
- Handles badge unlocking
- Persists badges to storage
- Notifies UI when badges change

### Badge Model
`lib/models/badge.dart`
- Defines badge structure (id, name, description, emoji, color)
- Contains all badge definitions and thresholds

### Integration Points
1. **Landing Page** (`lib/screens/landing_page.dart`)
   - Initializes step counter
   - Checks step milestones on step updates

2. **Scan Screen** (`lib/widgets/enhanced_scan_screen.dart`)
   - Checks gait improvement after scan
   - Checks scan consistency after scan

3. **Profile Screen** (`lib/screens/profile_screen.dart`)
   - Displays all unlocked badges

---

## Example Usage Flow

### Step Milestone Example:
```
1. User walks → Device sensor tracks steps
2. Step count updates → StepCounterService notifies
3. Landing page receives update → Calls badgeProvider.checkStepMilestones()
4. BadgeProvider checks if 10,000 steps threshold reached
5. If yes → Creates badge → Saves to storage → Shows notification
6. User sees badge in profile page
```

### Gait Improvement Example:
```
1. User completes scan → Score: 65
2. Previous score was 60
3. Enhanced scan screen calls badgeProvider.checkGaitImprovement(60, 65)
4. BadgeProvider increments streak (now streak = 1)
5. Scan 2: Score 70 → Streak = 2
6. Scan 3: Score 75 → Streak = 3 🎉 "On the Rise" badge unlocked!
7. Notification shown → Badge saved → Appears in profile
```

### Consistency Example:
```
1. User scans on Day 1
2. User scans on Day 2 → Streak = 2
3. User scans on Day 3 → Streak = 3
...
7. User scans on Day 7 → Streak = 7 🎉 "Week Warrior" badge unlocked!
```

---

## Adding New Badges

To add new badges, edit `lib/models/badge.dart`:

1. Add badge definition to appropriate array:
   - `stepMilestones` for step-based badges
   - `gaitImprovements` for improvement badges
   - `consistencyBadges` for consistency badges

2. Format:
```dart
{
  'id': 'unique_badge_id',
  'name': 'Badge Display Name',
  'description': 'Badge description',
  'emoji': '🎖️',
  'color': 0xFF6366F1, // Hex color code
  'threshold': 100, // Milestone value
}
```

3. No code changes needed in badge provider - it automatically checks all defined badges!

---

## Notes

- **Badges are persistent:** Once unlocked, they remain even if you reinstall the app (if using cloud backup)
- **One-time unlock:** Each badge can only be unlocked once
- **Automatic checking:** No manual action required - badges unlock automatically
- **Real-time updates:** Step badges update as you walk (with device permission)
- **Streak-based badges:** Gait improvement and consistency badges reset if you break the streak

---

## Troubleshooting

**Badges not unlocking?**
- Check device has step counter permission
- Verify scan is completing successfully
- Check that previous score is being tracked correctly

**Badges not persisting?**
- Check SharedPreferences is working
- Verify badge provider is saving correctly
- Look for errors in console logs

