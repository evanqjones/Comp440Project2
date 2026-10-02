class_name PlayerFonts
## The game's fonts (docs/features/player/12-fonts/FEATURE.md, D-032). project.godot's
## gui/theme/custom_font makes Rubik Medium (UI) the default for every Control, so only big display
## text needs `display()`. All are SIL OFL 1.1 (licenses beside them, ASSETS.md §6).

const UI_PATH := "res://systems/player/fonts/ui_font.tres"
## Bungee: chunky arcade capitals for the timer, countdown, popups, titles and "+$" pops.
const DISPLAY: FontFile = preload("res://systems/player/fonts/Bungee-Regular.ttf")
## Rubik Medium: the default for everything else.
const UI: FontVariation = preload("res://systems/player/fonts/ui_font.tres")
## Rubik Bold: name tags over carts (Bungee is too wide for three tags side by side).
const BOLD: FontVariation = preload("res://systems/player/fonts/ui_font_bold.tres")
## Courier Prime: receipt lines, prices and key caps (player/13-artifact-screens).
const COURIER: FontFile = preload("res://systems/player/fonts/CourierPrime-Regular.ttf")
const COURIER_BOLD: FontFile = preload("res://systems/player/fonts/CourierPrime-Bold.ttf")
const RUBIK_FILE: FontFile = preload("res://systems/player/fonts/Rubik-Variable.ttf")

static var _cache: Dictionary = {}


## Give `control` the display font.
static func display(control: Control) -> void:
	control.add_theme_font_override("font", DISPLAY)


## Rubik at a CSS weight (400 regular, 500 medium, 700 bold). The same weight is always the same Font.
static func rubik(weight: int) -> Font:
	if weight == 500:
		return UI
	if weight == 700:
		return BOLD
	var key := ["rubik", weight]
	if not _cache.has(key):
		var variation := FontVariation.new()
		variation.base_font = RUBIK_FILE
		variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_cache[key] = variation
	return _cache[key]


## `font` with extra letter spacing in pixels (CSS letter-spacing), cached. A weighted Rubik is
## copied rather than wrapped: a FontVariation over another FontVariation loses the weight.
static func spaced(font: Font, pixels: int) -> Font:
	var key := [font, pixels]
	if not _cache.has(key):
		var variation := FontVariation.new()
		if font is FontVariation:
			variation.base_font = (font as FontVariation).base_font
			variation.variation_opentype = (font as FontVariation).variation_opentype
		else:
			variation.base_font = font
		variation.spacing_glyph = pixels
		_cache[key] = variation
	return _cache[key]
