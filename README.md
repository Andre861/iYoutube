# iYoutube for iPad Air 2 (iOS 15+)

A clean, native iOS YouTube client built in Swift and SwiftUI, specifically tailored for older iPads (like the iPad Air 2 running iOS 15.8.x).

## Features
- **Zero Ads & No Tracking:** Streams directly from public Invidious nodes without corporate tracking or commercials.
- **Background Audio Playback:** Listen to podcasts, music, and talks even when your iPad screen is locked or while multitasking in other apps.
- **Native Picture-in-Picture (PiP):** Watch videos in a floating window while browsing or taking notes.
- **Stream Quality Selector:** Choose 720p, 480p, or 360p direct streams.
- **Local Library:** Bookmark videos and access watch history completely offline and privately (no account required).
- **Invidious Instance Failover:** Automatically switches to healthy fallback nodes if an instance is experiencing downtime.

---

## How to Build the `.ipa` (Automated Free Cloud Build)

Because compiling iOS apps requires a macOS environment with Xcode, this repository includes an automated GitHub Actions workflow (`.github/workflows/build-ipa.yml`) that builds the app on a free cloud Mac:

1. **Push this project to a GitHub repository:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit for iYoutube iOS 15"
   git branch -M main
   git remote add origin https://github.com/<YOUR_USERNAME>/iYoutube.git
   git push -u origin main
   ```

2. **Download your compiled `.ipa`:**
   - Go to your repository on GitHub.
   - Click the **Actions** tab at the top.
   - Click on the latest workflow run: **"Build iYoutube IPA"**.
   - Under **Artifacts** at the bottom, click **`iYoutube-iOS15-ipa`** to download your ready-to-use `.ipa` file!

3. **Install on iPad:**
   - Drag `iYoutube.ipa` into **Sideloadly**.
   - Click **Start** to install it directly to your iPad Air 2.
