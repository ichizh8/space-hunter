extends Node
## Centralised design tokens and UI helper factories for Space-Hunter.
## Register as autoload "UITheme" in project.godot.

# ── PALETTE ──────────────────────────────────────────────────────────────────

# Backgrounds
const BG_DARK       := Color(0.04, 0.04, 0.08)   # #0a0a14 deep space
const BG_MEDIUM     := Color(0.08, 0.08, 0.16)   # #14142a panels
const BG_LIGHT      := Color(0.12, 0.12, 0.22)   # #1e1e38 raised elements
const BG_OVERLAY    := Color(0.02, 0.02, 0.06, 0.95) # modal overlays

# Text
const TEXT_PRIMARY   := Color(0.88, 0.88, 0.94)   # #e0e0f0
const TEXT_SECONDARY := Color(0.53, 0.53, 0.67)   # #8888aa
const TEXT_MUTED     := Color(0.33, 0.33, 0.44)   # #555570
const TEXT_WHITE     := Color(1.0, 1.0, 1.0)

# Borders
const BORDER_DEFAULT := Color(0.17, 0.17, 0.29)   # #2a2a4a
const BORDER_LIGHT   := Color(0.25, 0.25, 0.40)   # #404066
const BORDER_ACTIVE  := Color(0.35, 0.35, 0.55)

# Accents
const ACCENT_GOLD    := Color(1.0, 0.80, 0.0)     # #ffcc00
const ACCENT_GREEN   := Color(0.27, 1.0, 0.40)    # #44ff66
const ACCENT_PURPLE  := Color(0.67, 0.27, 1.0)    # #aa44ff
const ACCENT_RED     := Color(1.0, 0.27, 0.27)    # #ff4444
const ACCENT_CYAN    := Color(0.27, 0.87, 1.0)    # #44ddff
const ACCENT_ORANGE  := Color(1.0, 0.53, 0.27)    # #ff8844
const ACCENT_BLUE    := Color(0.30, 0.50, 0.90)

# Semantic
const HP_GREEN       := Color(0.20, 0.90, 0.20)
const HP_BG          := Color(0.30, 0.10, 0.10)
const XP_PURPLE      := Color(0.50, 0.0, 0.90)
const CORRUPTION_LOW := Color(0.30, 0.90, 0.30)
const CORRUPTION_MID := Color(0.90, 0.80, 0.20)
const CORRUPTION_HI  := Color(0.90, 0.30, 0.20)
const CORRUPTION_MAX := Color(1.0, 0.10, 0.10)
const DISABLED_ALPHA := 0.35

# Track colours (matching existing game data)
const TRACK_COLORS: Dictionary = {
	"contractor":  Color(0.30, 0.80, 0.30),
	"void_walker": Color(0.67, 0.27, 1.0),
	"tactician":   Color(0.30, 0.50, 0.90),
	"scrapper":    Color(1.0, 0.53, 0.27),
}

const PANTRY_COLORS: Dictionary = {
	"rift_dust":    Color(0.90, 0.80, 0.30),
	"void_crystal": Color(0.67, 0.27, 1.0),
	"cave_moss":    Color(0.30, 0.70, 0.40),
	"river_silt":   Color(0.30, 0.60, 0.90),
	"elite_core":   Color(1.0, 0.85, 0.0),
}

# ── SIZES ────────────────────────────────────────────────────────────────────

const FONT_TITLE   := 22
const FONT_HEADING := 17
const FONT_BODY    := 15
const FONT_SMALL   := 13
const FONT_TINY    := 10

const MARGIN_XS := 4
const MARGIN_SM := 8
const MARGIN_MD := 12
const MARGIN_LG := 16
const MARGIN_XL := 24

const BORDER_WIDTH := 2        # pixel grid border
const CORNER_RADIUS := 0       # pixel corners — no rounding
const BUTTON_MIN_H := 44       # mobile tap target
const BUTTON_MIN_W := 80
const PROGRESS_H := 8          # progress bar height
const ICON_SIZE := 28

# ── STYLE FACTORIES ──────────────────────────────────────────────────────────

static func make_panel_style(bg: Color = BG_MEDIUM, border: Color = BORDER_DEFAULT, bw: int = BORDER_WIDTH) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top = bw; s.border_width_bottom = bw
	s.content_margin_left = MARGIN_MD; s.content_margin_right = MARGIN_MD
	s.content_margin_top = MARGIN_SM; s.content_margin_bottom = MARGIN_SM
	return s

static func make_button_normal(bg: Color = BG_LIGHT, border: Color = BORDER_DEFAULT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = BORDER_WIDTH; s.border_width_right = BORDER_WIDTH
	s.border_width_top = BORDER_WIDTH; s.border_width_bottom = BORDER_WIDTH
	s.content_margin_left = MARGIN_SM; s.content_margin_right = MARGIN_SM
	s.content_margin_top = MARGIN_XS; s.content_margin_bottom = MARGIN_XS
	return s

static func make_button_hover(bg: Color = BG_LIGHT, border: Color = BORDER_LIGHT) -> StyleBoxFlat:
	var s := make_button_normal(Color(bg.r + 0.05, bg.g + 0.05, bg.b + 0.05), border)
	return s

static func make_button_pressed(bg: Color = BG_DARK, border: Color = BORDER_ACTIVE) -> StyleBoxFlat:
	return make_button_normal(bg, border)

static func make_button_disabled() -> StyleBoxFlat:
	var s := make_button_normal(Color(BG_LIGHT.r, BG_LIGHT.g, BG_LIGHT.b, 0.4), Color(BORDER_DEFAULT.r, BORDER_DEFAULT.g, BORDER_DEFAULT.b, 0.3))
	return s

## Apply full pixel-style theme to a Button node.
static func style_button(btn: Button, accent: Color = ACCENT_CYAN, font_size: int = FONT_BODY) -> void:
	var normal := make_button_normal(Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15), Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5))
	var hover := make_button_normal(Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22), accent)
	var pressed := make_button_normal(Color(accent.r * 0.08, accent.g * 0.08, accent.b * 0.08), accent)
	var disabled := make_button_disabled()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", TEXT_WHITE)
	btn.add_theme_color_override("font_pressed_color", accent)
	btn.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, DISABLED_ALPHA))
	btn.add_theme_font_size_override("font_size", font_size)
	if btn.custom_minimum_size.y < BUTTON_MIN_H:
		btn.custom_minimum_size.y = BUTTON_MIN_H

## Apply accent-coloured "primary action" style.
static func style_button_primary(btn: Button, accent: Color = ACCENT_GOLD, font_size: int = FONT_HEADING) -> void:
	var normal := make_button_normal(Color(accent.r * 0.20, accent.g * 0.20, accent.b * 0.20), accent)
	var hover := make_button_normal(Color(accent.r * 0.30, accent.g * 0.30, accent.b * 0.30), accent)
	var pressed := make_button_normal(Color(accent.r * 0.10, accent.g * 0.10, accent.b * 0.10), accent)
	var disabled := make_button_disabled()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", TEXT_WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(accent.r * 0.7, accent.g * 0.7, accent.b * 0.7))
	btn.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, DISABLED_ALPHA))
	btn.add_theme_font_size_override("font_size", font_size)
	if btn.custom_minimum_size.y < BUTTON_MIN_H:
		btn.custom_minimum_size.y = BUTTON_MIN_H

## Ghost/secondary button (dim border, no fill).
static func style_button_ghost(btn: Button, font_size: int = FONT_BODY) -> void:
	var normal := make_button_normal(Color(0, 0, 0, 0), BORDER_DEFAULT)
	var hover := make_button_normal(Color(BG_LIGHT.r, BG_LIGHT.g, BG_LIGHT.b, 0.3), BORDER_LIGHT)
	var pressed := make_button_normal(Color(0, 0, 0, 0), BORDER_ACTIVE)
	var disabled := make_button_disabled()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", TEXT_SECONDARY)
	btn.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_pressed_color", TEXT_MUTED)
	btn.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, DISABLED_ALPHA))
	btn.add_theme_font_size_override("font_size", font_size)
	if btn.custom_minimum_size.y < BUTTON_MIN_H:
		btn.custom_minimum_size.y = BUTTON_MIN_H

# ── NODE FACTORIES ───────────────────────────────────────────────────────────

## Create a styled Label.
static func make_label(text: String, font_size: int = FONT_BODY, color: Color = TEXT_PRIMARY) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

## Section header with pixel underline.
static func make_section_header(text: String, accent: Color = ACCENT_CYAN) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	var lbl := make_label(text, FONT_HEADING, accent)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(lbl)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, BORDER_WIDTH)
	line.color = Color(accent.r, accent.g, accent.b, 0.4)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line)
	return vbox

## Pixel-art separator line.
static func make_separator(color: Color = BORDER_DEFAULT) -> ColorRect:
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = color
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line

## Styled PanelContainer with pixel borders.
static func make_card(bg: Color = BG_MEDIUM, border: Color = BORDER_DEFAULT) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", make_panel_style(bg, border))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return pc

## Progress bar as two ColorRects in an HBoxContainer.
static func make_progress_bar(frac: float, fill_color: Color, bg_color: Color = BG_DARK, height: int = PROGRESS_H) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.custom_minimum_size = Vector2(0, height)

	var fill := ColorRect.new()
	fill.color = fill_color
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.size_flags_stretch_ratio = maxf(frac, 0.001)
	hbox.add_child(fill)

	if frac < 1.0:
		var empty := ColorRect.new()
		empty.color = bg_color
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.size_flags_stretch_ratio = 1.0 - frac
		hbox.add_child(empty)

	return hbox

## Pixel-art coloured dot with count underneath.
static func make_ingredient_badge(count: int, color: Color, label_text: String) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	if count > 0:
		dot.color = color
	else:
		dot.color = Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.5)
	vbox.add_child(dot)

	var count_lbl := make_label(str(count), FONT_SMALL, color if count > 0 else TEXT_MUTED)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(count_lbl)

	var name_lbl := make_label(label_text, FONT_TINY, TEXT_MUTED)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	return vbox

## Floating bottom bar container (glass-like panel at bottom of screen).
static func make_bottom_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(BG_DARK.r, BG_DARK.g, BG_DARK.b, 0.85)
	style.border_color = BORDER_DEFAULT
	style.border_width_top = BORDER_WIDTH
	style.border_width_left = BORDER_WIDTH; style.border_width_right = BORDER_WIDTH
	style.border_width_bottom = BORDER_WIDTH
	style.content_margin_left = MARGIN_SM; style.content_margin_right = MARGIN_SM
	style.content_margin_top = MARGIN_XS; style.content_margin_bottom = MARGIN_XS
	bar.add_theme_stylebox_override("panel", style)
	return bar

## Tab button for the bottom bar. Returns a Button configured as tab.
static func make_tab_button(text: String, accent: Color = ACCENT_CYAN) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 48)
	style_button_ghost(btn, FONT_SMALL)
	btn.add_theme_color_override("font_color", TEXT_MUTED)
	return btn

## Mark a tab button as active.
static func set_tab_active(btn: Button, active: bool, accent: Color = ACCENT_CYAN) -> void:
	if active:
		var style := make_button_normal(Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 0.8), accent)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", accent)
		btn.disabled = true
	else:
		style_button_ghost(btn, FONT_SMALL)
		btn.add_theme_color_override("font_color", TEXT_MUTED)
		btn.disabled = false
