class_name PlayerFonts
## The game's fonts (docs/features/player/11-fonts/FEATURE.md, D-032). project.godot's
## gui/theme/custom_font makes Rubik Medium (UI) the default for every Control, so only big display
## text needs `display()`. Both fonts are SIL OFL 1.1 (licenses beside them, ASSETS.md §6).

const UI_PATH := "res://systems/player/fonts/ui_font.tres"
## Bungee: chunky arcade capitals for the timer, countdown, popups, titles and "+$" pops.
const DISPLAY: FontFile = preload("res://systems/player/fonts/Bungee-Regular.ttf")
## Rubik Medium: the default for everything else.
const UI: FontVariation = preload("res://systems/player/fonts/ui_font.tres")
## Rubik Bold: name tags over carts (Bungee is too wide for three tags side by side).
const BOLD: FontVariation = preload("res://systems/player/fonts/ui_font_bold.tres")


## Give `control` the display font.
static func display(control: Control) -> void:
	control.add_theme_font_override("font", DISPLAY)
