# Notification Sound Assets

## Required File

Please add a notification sound file named `water_reminder.mp3` or `water_reminder.ogg` to this directory.

The sound should be:
- Short duration (1-3 seconds)
- Pleasant and not jarring
- Clear and audible but not loud
- Suitable for a water drinking reminder

## Recommended Sources for Free Notification Sounds:

1. **Freesound.org** - https://freesound.org/
2. **Zapsplat** - https://www.zapsplat.com/
3. **Notification Sounds** - https://notificationsounds.com/

## File Requirements:

- **Format**: MP3 or OGG (MP3 recommended for better compatibility)
- **Sample Rate**: 44.1 kHz or 48 kHz
- **Bit Rate**: 128 kbps or higher
- **Max Size**: 500 KB (smaller is better for app size)

## Installation:

1. Place `water_reminder.mp3` in this folder
2. **IMPORTANT**: Also copy the same file to: `android/app/src/main/res/raw/water_reminder.mp3`
   - Note: Remove the extension when copying to raw folder (just `water_reminder.mp3`)
   - The raw folder doesn't support dots in filenames except for the extension

## Example Good Water Reminder Sounds:

- Gentle water drop sound
- Soft bell or chime
- Gentle "ding" notification
- Soft bubbling water sound
- Pleasant notification tone

Once you add the file, the app will use this custom sound for all water reminder notifications instead of the system default sound.
