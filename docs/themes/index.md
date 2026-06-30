# Themes

ttkbootstrap includes 18 built-in themes — 13 light and 5 dark.
All themes use TkDefaultFont for consistent text positioning across platforms.

## Switching Themes

```tcl
# At startup
ttkbootstrap::Window -themename darkly -title "My App"

# At runtime
ttkbootstrap::setTheme solar
```

## Light Themes (13)

| Theme | Primary | Style |
|-------|---------|-------|
| cerculean | Blue | Clean, professional |
| cosmo | Blue | Modern, Bootstrap-like |
| flatly | Dark blue | Flat design, muted |
| journal | Red | Readable, serif-inspired |
| litera | Blue | Light, paper-like |
| lumen | Blue | Bright, minimal |
| minty | Green | Fresh, friendly |
| morph | Purple | Soft, neumorphic |
| pulse | Purple | Vibrant, energetic |
| sandstone | Green | Warm, earthy |
| simplex | Red | Simple, no-frills |
| united | Orange | Bold, Ubuntu-inspired |
| yeti | Blue | Cool, spacious |

## Dark Themes (5)

| Theme | Primary | Style |
|-------|---------|-------|
| cyborg | Blue | High-contrast, techy |
| darkly | Blue | Dark Bootstrap |
| solar | Blue | Solarized dark |
| superhero | Orange | Bold, dark |
| vapor | Purple | Neon, futuristic |

## Querying Theme Info

```tcl
# All theme names
puts [ttkbootstrap::themeNames]

# Light themes only
puts [ttkbootstrap::lightThemes]

# Dark themes only
puts [ttkbootstrap::darkThemes]

# Current theme colours
puts [ttkbootstrap::getColor primary]  ;# hex colour
puts [ttkbootstrap::getColor bg]       ;# background
puts [ttkbootstrap::getColor fg]       ;# foreground
puts [ttkbootstrap::getColor type]     ;# "light" or "dark"

# All colours as a dict
puts [ttkbootstrap::getColors]
```

## Available Colour Keys

`primary`, `secondary`, `success`, `info`, `warning`, `danger`,
`light`, `dark`, `bg`, `fg`, `selectbg`, `selectfg`, `border`,
`active`, `inputfg`, `inputbg`, `font`, `type`
