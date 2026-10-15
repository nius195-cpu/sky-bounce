# Changes

## 1.1.0

- New ball color every 10 points: gold, mint, blue, purple, pink, and orange, cycling for later levels. Color changes blend smoothly; the glow, highlight, trail, and bounce particles follow the ball color.
- The HUD shows the current level. Level 1 spans scores 0–9, level 2 spans 10–19, and so on.
- The star field drifts at different depths and gently twinkles. Decorative animation freezes while paused.
- Ball movement becomes faster after every successful bounce, including scores beyond the former score-30 speed ceiling. The curve rises gradually, shortening reaction time while preserving the ball's bounce arc and keeping platform touch controls consistent.
- Existing saved high scores and sound preferences retain their storage format.
- Android version code increased to 2 for installing the update.

Validation: 36 automated checks pass, including new level-color boundaries, smooth transitions, moving/paused stars, increasing speed at high scores, restart behavior, and a three-minute simulated rally.
