---
name: Sonic Dark
colors:
  surface: '#0e150e'
  surface-dim: '#0e150e'
  surface-bright: '#333b33'
  surface-container-lowest: '#091009'
  surface-container-low: '#161d16'
  surface-container: '#1a211a'
  surface-container-high: '#242c24'
  surface-container-highest: '#2f372e'
  on-surface: '#dde5d9'
  on-surface-variant: '#bccbb9'
  inverse-surface: '#dde5d9'
  inverse-on-surface: '#2b322a'
  outline: '#869585'
  outline-variant: '#3d4a3d'
  surface-tint: '#53e076'
  primary: '#53e076'
  on-primary: '#003914'
  primary-container: '#1db954'
  on-primary-container: '#004118'
  inverse-primary: '#006e2d'
  secondary: '#c8c6c5'
  on-secondary: '#303030'
  secondary-container: '#474746'
  on-secondary-container: '#b7b5b4'
  tertiary: '#c8c6c5'
  on-tertiary: '#313030'
  tertiary-container: '#a3a1a1'
  on-tertiary-container: '#383838'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#72fe8f'
  primary-fixed-dim: '#53e076'
  on-primary-fixed: '#002108'
  on-primary-fixed-variant: '#005320'
  secondary-fixed: '#e4e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1b1c1c'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#e5e2e1'
  tertiary-fixed-dim: '#c8c6c5'
  on-tertiary-fixed: '#1c1b1b'
  on-tertiary-fixed-variant: '#474646'
  background: '#0e150e'
  on-background: '#dde5d9'
  surface-variant: '#2f372e'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  title-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  metadata:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-padding: 16px
  stack-gap: 24px
  list-item-gap: 12px
  section-margin: 32px
---

## Brand & Style

This design system is engineered for immersive, long-form music consumption. It prioritizes content-first architecture through a deep, low-light aesthetic that minimizes eye strain in dimly lit environments. The brand personality is modern, rhythmic, and high-fidelity.

The visual style blends **Modern Minimalism** with **Glassmorphism**. While the foundational layers are matte and grounded, the interactive layers—such as the persistent bottom player and modal overlays—utilize frosted glass effects to provide a sense of spatial depth and context. The emotional response should be one of "effortless flow," where the interface recedes to let the album art and artist imagery become the focal point.

## Colors

The palette is strictly nocturnal, utilizing varying shades of charcoal to define hierarchy. 

- **Primary Background (#121212):** The base canvas for the entire application.
- **Surface/Card (#282828):** Used for elevated elements like album cards, list items, and search bars.
- **Accent (#1DB954):** Reserved for high-intent actions (Play, Follow, Toggle ON) and active states.
- **Typography:** Primary text uses pure white for maximum legibility, while metadata and secondary labels use a muted grey to reduce visual noise.

## Typography

The typography utilizes **Inter** to maintain a systematic, neutral, and highly readable interface. 

- **Hierarchy:** Use `display-lg` for playlist titles and `headline-md` for section headers (e.g., "Recently Played"). 
- **Emphasis:** Track titles must always use `title-sm` with Semi-Bold or Bold weights. 
- **Subtlety:** Use `metadata` for artist names and timestamps, colored in the secondary neutral tone.
- **Scaling:** On mobile, ensure that long track titles truncate with an ellipsis rather than wrapping, preserving the vertical rhythm of lists.

## Layout & Spacing

The layout follows a **fluid mobile grid** with a standard 16px gutter on the outer edges. 

- **Rhythm:** Vertical spacing between sections (e.g., between "Jump back in" and "Made for you") should be 32px to provide clear separation.
- **Touch Targets:** All interactive elements (buttons, list items) must maintain a minimum height of 48px.
- **The Player Bar:** This is a persistent floating element at the bottom of the screen. It should sit 8px above the navigation bar or bottom screen edge, utilizing horizontal margins to appear detached and "floating."

## Elevation & Depth

Depth is communicated through **Tonal Layering** and **Glassmorphism**:

1.  **Level 0 (Base):** #121212.
2.  **Level 1 (Cards):** #282828 with no shadow, relying on color contrast.
3.  **Level 2 (Floating Player/Modals):** Semi-transparent #282828 (80% opacity) with a 20px Backdrop Blur. A subtle 1px border (#FFFFFF, 10% opacity) should be applied to define the edges of glass elements.
4.  **Shadows:** Use large, ultra-soft ambient shadows (0px 8px 24px rgba(0,0,0,0.5)) only for modal pop-ups and context menus to pull them away from the background.

## Shapes

The shape language is consistently rounded to evoke a friendly, modern feel.

- **Standard Elements:** Album art, playlist tiles, and search inputs use a 12px radius.
- **Control Elements:** The main "Play" button is always a perfect circle. 
- **Interactive Pill:** Chips for filtering (e.g., "Music", "Podcasts") use a full pill-shape (radius: 100px) to distinguish them from content cards.

## Components

- **Primary Action Button:** Circular, #1DB954 background, with a black Play/Pause icon. Use a subtle scale-down animation on press.
- **Lists:** Song items include a 48px square thumbnail (8px radius), Title (White), and Artist (Grey). On "Active" state, the Title changes to #1DB954.
- **Cards:** Album cards are vertical stacks: a square image followed by the title and a sub-label. No borders; use background contrast.
- **The Glass Player:** A horizontal bar containing a small thumbnail, track info, and a play/pause toggle. It must use the backdrop-blur effect defined in the Elevation section.
- **Progress Sliders:** Use #1DB954 for the filled portion and #B3B3B3 (30% opacity) for the track. The "thumb" should only appear during an active drag state.
- **Context Menus:** Full-width bottom sheets with 16px rounded top corners, using the Level 1 surface color.