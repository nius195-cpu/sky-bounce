# Changes

## 1.2.0

- Added Reverse Mode: upward gravity, a top platform, downward rebounds, and loss through the top.
- Added a Play mode selector and independent Classic/Reverse high scores, preserving existing Classic scores.
- Shared one unchanged Classic physics model through a vertical-coordinate adapter. Speed, varied bounce heights, steering, platform movement, and cosmetics are identical under mirroring.
- Reverse uses a bottom HUD and the same horizontal touch controls.
- Added an iPhone/iPad export preset and setup guide. iOS data export is verified; native Xcode signing/build/device testing still requires a Mac and Apple development setup.
- Android version code increased to 4.

Validation: 85 automated checks pass, including exact Classic regression, mirrored rallies at three aspect ratios, input, collisions, loss, score migration, and persistence.

## 1.1.1

- Opening pace reduced by 35%, with slower early speed progression. Speed still increases as the score rises.
- Each rebound now selects a fresh height. Beginners get a gentle 240–300px range; the range gradually broadens to 170–360px at higher scores.
- The opening bounce flight lasts roughly 2.6–2.9 seconds on a stationary platform. Sideways steering does not shorten the randomized vertical arc.
- Bounce heights are kept below the top boundary so ceiling impacts do not flatten their variety.
- Android version code increased to 3.

Validation: 43 automated checks pass, including opening speed, height variation and bounds, beginner reaction time, edge-hit height, and a three-minute rally.

## 1.1.0

- New ball color every 10 points: gold, mint, blue, purple, pink, and orange, cycling for later levels. Color changes blend smoothly; the glow, highlight, trail, and bounce particles follow the ball color.
- The HUD shows the current level. Level 1 spans scores 0–9, level 2 spans 10–19, and so on.
- The star field drifts at different depths and gently twinkles. Decorative animation freezes while paused.
- Ball movement becomes faster after every successful bounce, including scores beyond the former score-30 speed ceiling. The curve rises gradually, shortening reaction time while preserving the ball's bounce arc and keeping platform touch controls consistent.
- Existing saved high scores and sound preferences retain their storage format.
- Android version code increased to 2 for installing the update.

Validation: 36 automated checks pass, including new level-color boundaries, smooth transitions, moving/paused stars, increasing speed at high scores, restart behavior, and a three-minute simulated rally.
