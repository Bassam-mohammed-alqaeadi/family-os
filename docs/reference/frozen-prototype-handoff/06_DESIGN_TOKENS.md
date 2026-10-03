# Design Tokens — extracted LITERALLY from the frozen prototype CSS
Source: `:root` of `family-os/family_os_app.html` (v1.0 frozen). Port these EXACTLY into `lib/core/design/tokens.dart`. Raw `Color(0x…)` anywhere else is a constitution violation (rule 14).

## Colors
| Token | Value | Usage |
|---|---|---|
| `p700` | `#5B3FD0` | Primary purple darkest |
| `p600` | `#6C4BD8` | Primary purple dark (gradient end) |
| `p500` | `#7C5CE6` | **Primary brand purple** |
| `p400` | `#8B6FF0` | Primary light (gradient start) |
| `p100` | `#EDE7FF` | Primary tint background |
| `p50`  | `#F6F3FF` | Primary faintest tint |
| `mint` | `#00D9A3` | Success / growth |
| `mint100` | `#D4FBF0` | Success tint |
| `amber` | `#FFB547` | Warm attention (NEVER red for warnings — emotional-tone law) |
| `amber100` | `#FFF4DE` | Attention tint |
| `coral` | `#FF5A5F` | Danger / SOS only |
| `coral100` | `#FFE7E8` | Danger tint |
| `teal` | `#4DD0C7` | Secondary actions / child accents |
| `teal600` | `#26B3A9` | Teal dark (gradient end) |
| `teal100` | `#DFF7F5` | Teal tint |
| `bg` | `#F5F6FA` | App background |
| `surface` | `#FFFFFF` | Cards / sheets |
| `ink` | `#1A1D2E` | Primary text |
| `ink2` | `#8A8FA3` | Secondary text |
| `border` | `#EDEEF5` | Hairlines / dividers |

## Shadows
| Token | Value |
|---|---|
| `shCard` | `0 2px 12px rgba(26,29,46,.05)` |
| `shFloat` | `0 8px 28px rgba(26,29,46,.08)` |
| `shBrand` | `0 8px 24px rgba(124,92,230,.28)` |
| `shCoral` | `0 8px 24px rgba(255,90,95,.35)` |

## Gradients
| Token | Value |
|---|---|
| `grad` | `linear-gradient(135deg, #8B6FF0, #6C4BD8)` |
| `gradTeal` | `linear-gradient(135deg, #5FDDD4, #26B3A9)` |

## Component conventions observed in the prototype (port 1:1)
- Buttons `.btn`: full-width by default, radius ≈ 14–16, variants: primary(purple)/`teal`/`sec`(tinted)/`ghost`(borderless)/`coral`(danger).
- Cards `.card`: surface white, `shCard`, radius ≈ 16, padding ≈ 14.
- Row tiles `.row`: emoji/avatar leading + `.tx` (bold title + muted subtitle) + optional trailing tag/chevron.
- Tags `.tag`: pill; variants `g`(mint) `t`(teal) `p`(purple) `a`(amber).
- Banners `.banner`: tinted full-width note; variants `t`(teal) `p`(purple) `a`(amber).
- Progress `.prog`: 8–10px track, rounded, tinted fill (`pu` purple variant).
- Bottom sheet + toast: the two feedback primitives — every principal action produces toast / visible state change / navigation (loop-closure law).
- Child mode (`child-ui`): same components, friendlier scale/colors; floating SOS button always visible on child screens (except during onboarding/SOS itself); floating ✨ advisor button on parent screens.
- RTL is the default direction everywhere.
- Touch targets ≥ 48dp; circular action buttons in calls are 58px.

## Typography
- System font stack in prototype; for Flutter use a rounded Arabic-friendly family (e.g., IBM Plex Sans Arabic or Cairo) — **one family, weights 400/700/800**. Sizes observed: h3 ≈ 14.5–15, body ≈ 13–13.5, small ≈ 11–12.5.
