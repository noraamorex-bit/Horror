# Player feedback

Two places players leave feedback:

1. **Our own 📝 box (v150)**: the lobby's mailbox and every result card. Filtered by Roblox and kept in the
   `Feedback_v1` data store. Read it with `python3 tools/pull_feedback.py [--days=7]`.
2. **Roblox's own feedback window** (before v150, and the "⭐ Rate on Roblox" button in our box): it only shows in
   Creator Hub → your experience → Audience → Feedback. There's no API for it. To have it read, use the
   **export** button (top right of that page) to download the `.csv`, then upload it here
   (github.com → this repo → this branch → `marketing/feedback/` → Add file → Upload files).
