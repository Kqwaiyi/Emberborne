## scripts/environment/vision_cone.gd
## Attach to the VisionCone Node2D child inside human.tscn and dog.tscn.
## Casts multiple rays across the enemy's forward arc and draws a clipped polygon.
##
## How facing/angle works:
##   - The parent enemy's `facing` property is a unit Vector2 in global space.
##   - We convert it to an angle with facing.angle() (radians from +X axis).
##   - We then sweep rays from  (facing_angle - half_cone)  to
##     (facing_angle + half_cone), evenly spaced.
##   - Each ray is cast in GLOBAL space from the parent's global_position.
##   - Hit positions are converted to LOCAL space of this node before drawing,
##     because draw_polygon() uses local coordinates.
##   - The node's global_position matches the parent because it is a direct child
##     with zero offset.
extends Node2D

@export var ray_count: int     = 36          # more = smoother but slower
@export var fill_color: Color  = Color(1, 0, 0, 0.22)
@export var edge_color: Color  = Color(1, 0, 0, 0.55)
@export var edge_width: float  = 1.5

# These are read from the parent EnemyBase each frame.
var _range: float  = 360.0
var _angle: float  = 40.0

func _ready() -> void:
	# Ensure this node draws on top of the enemy body.
	z_index = 1

func _process(_delta: float) -> void:
	# Read parent values every frame so Inspector changes are reflected live.
	var parent := get_parent()
	if parent == null:
		return
	if "vision_range" in parent:
		_range = parent.vision_range
	if "vision_angle" in parent:
		_angle = parent.vision_angle
	queue_redraw()

func _draw() -> void:
	var parent := get_parent()
	if parent == null:
		return

	# Facing direction as angle (radians), derived from the parent's facing Vector2.
	var facing_dir: Vector2 = Vector2.RIGHT
	if "facing" in parent:
		facing_dir = parent.facing
	var facing_angle: float = facing_dir.angle()   # radians from +X global

	var half_cone: float  = deg_to_rad(_angle * 0.5)
	var space := get_world_2d().direct_space_state
	var origin: Vector2  = global_position          # same as parent for child at (0,0)

	# Build polygon points in LOCAL space (this node has zero offset from parent).
	var points: PackedVector2Array
	points.append(Vector2.ZERO)   # apex at local origin

	var step: float = (2.0 * half_cone) / float(ray_count - 1)
	for i in ray_count:
		var ray_angle: float  = (facing_angle - half_cone) + float(i) * step
		var ray_dir: Vector2  = Vector2(cos(ray_angle), sin(ray_angle))
		var ray_end: Vector2  = origin + ray_dir * _range

		var query := PhysicsRayQueryParameters2D.create(
			origin,
			ray_end,
			1 << 6   # VisionBlocker = layer 7 = bit 6
		)
		# Exclude the parent enemy so it doesn't block its own cone.
		if parent.has_method("get_rid"):
			query.exclude = [parent.get_rid()]

		var result: Dictionary = space.intersect_ray(query)
		var hit_global: Vector2
		if result.is_empty():
			hit_global = ray_end
		else:
			hit_global = result["position"]

		# Convert from global to this node's local space for drawing.
		points.append(to_local(hit_global))

	if points.size() < 3:
		return

	draw_colored_polygon(points, fill_color)
	# Draw border along the outer arc edges only (skip the apex-to-first and apex-to-last).
	for i in range(1, points.size() - 1):
		draw_line(points[i], points[i + 1], edge_color, edge_width)
