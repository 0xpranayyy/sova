# Sova App Preview

An App Preview is the short video that autoplays, without sound, on the App Store page and in search. Apple's rules:
- **15–30 seconds**
- **footage captured from the app itself**: no people, no hands, no device frames, no footage of other apps
- text captions are fine

The marketing film (`marketing/Sova-intro.mp4`) is for social media. It can't be used here.

The plan: record six short clips of the real app, run one script, and upload.

---

## 1. Record on the Simulator

The Simulator gives a perfect 9:41 status bar and no notifications.

1. In Xcode, run Sova on an **iPhone 17 Pro Max** simulator. Use the 6.9" size; Apple scales it for smaller phones.
2. In Terminal, clean up the status bar once:

   ```bash
   xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
   ```

3. Set the app up with believable data. You'll need:
   - a few tasks today: one at 6:00 PM, one with `!!`, one with a checklist
   - three rituals, including "Drink water" with a target of 8
   - two goals with steps
   - your name set to something like "Alex"
4. To record each clip, run the line below, perform the action, then press **Ctrl-C** to stop:

   ```bash
   xcrun simctl io booted recordVideo --codec h264 clips/1.mov
   ```

   Change the number for each clip. Leave about half a second of stillness before and after each action.

You can also record on your iPhone: **Control Center → Screen Recording**. Turn on Do Not Disturb first, and crop out any stray notification.

---

## 2. The six clips

Each clip shows one action. Move a little slower than you normally would.

| # | Length | Caption | What to do |
|---|---|---|---|
| 1 | 4.5 s | Your day, at a glance | On **Today**, scroll slowly from the day card down the timeline past the NOW marker, then tick one task. The ring fills. |
| 2 | 5 s | Just type it | Tap **+** and type `Call Mom tomorrow 6pm !!`. The date and priority light up. Tap send. |
| 3 | 4 s | Habits that fill up | **Rituals** tab: tap "Drink water" a few times (5 → 6 → 7), then tick a plain ritual so it fills with color. |
| 4 | 3.5 s | Every task has a home | **Tasks** tab: tap Tomorrow in the calendar strip, then tap it again to show everything. |
| 5 | 4.5 s | Big goals, small steps | **Goals**: open a goal and tick a step. The percentage rolls up. Or, on a device with Apple Intelligence: New Goal → **Suggest steps**. |
| 6 | 5 s | Finish your day with a smile | Back on **Today**, tick the last thing. The owl celebrates and the wave opens "Day done!". |

That's about 27 seconds after the cross-fades: inside Apple's limit, with room to spare.

---

## 3. Make the preview

Put the clips in `marketing/app-store/preview/clips/` as `1.mov` … `6.mov`, then run:

```bash
brew install ffmpeg
```

```bash
cd marketing/app-store/preview && ./make-preview.sh
```

You get `Sova-App-Preview.mp4`:
- 886 × 1920 at 30 fps
- H.264 video with a silent stereo track
- a yellow caption on each clip, in Allo
- quick cross-fades between clips

For a version without captions, run `./make-preview.sh --plain`.

Or send me the six clips and I'll make it.

---

## 4. Upload

1. **App Store Connect → Sova → 1.0 → App Previews and Screenshots → 6.9" Display.**
2. Drop the video in the first slot, before the screenshots.
3. Choose the **poster frame**. Pick the moment in clip 1 where the day card and timeline are both on screen; that frame is what people see before it plays.

Apple processes previews for a few minutes before they show.
