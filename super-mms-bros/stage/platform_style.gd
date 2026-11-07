class_name PlatformStyle
extends Resource
## A platform material: the colors and front-face bands PlatformLook draws
## (docs/specs/match-and-stage.md#platform-look-perspective).
##
## A front face is a stack of bands, top to bottom, each an array:
##   ["solid", height, color]
##   ["brick", height, brick, dark_brick, mortar]   rows of 3 px brick + 1 px mortar
##   ["glass", height, glass, highlight, frame]     a window band with thin frames
##   ["panel", height, color, seam]                 concrete panels with joints

@export_group("Top face")
@export var top: Color
## The top face's back edge.
@export var top_edge: Color
## The thin platforms' shadows on the main platform; the top platform's is fainter.
@export var shadow: Color
@export var far_shadow: Color

@export_group("Faces")
## A platform end, turned away from the light.
@export var side: Color
## The main platform's underside.
@export var under: Color
@export var main_bands: Array = []
@export var thin_bands: Array = []
## Corner blocks at both ends of the main platform's front face.
@export var has_quoins: bool = false
@export var quoins: Color
