# PennyPal Animation Showcase Pass

This pass builds on the existing PennyPal motion system and adds purposeful interaction and screen-level motion without changing the SRS feature scope.

## Motion language
- Route transitions: fade + left entrance + subtle scale.
- Landing: existing staggered reveal and animated gradient remain.
- Splash: single branded animated splash; no duplicate oversized native logo.
- Content screens: reusable `MotionReveal` for staggered fade/slide/scale entrances.
- Action tiles: `MotionPress` gives a small tactile press response.
- Dashboard/stat values: money figures animate from zero to their current values.
- Budget progress: progress bars animate into their current state.
- Reports/savings: existing chart libraries animate their chart transitions while screen sections reveal progressively.
- AI: single pulsing dot remains the thinking indicator; no text such as “PennyPal is thinking”.
- Bottom navigation remains stable by design.

## Screens covered
- Landing / authentication
- Dashboard
- Budget / Plan
- Savings / Save
- Reports
- Transactions / Activity
- Learning
- Profile
- Admin centre

The goal is a premium, responsive fintech feel rather than constant movement. Animations are short enough to keep recording, budgeting and navigation efficient.
