extends CharacterBody2D

class_name PlatformerController2D

@export var README: String = """
IMPORTANT: Ensure to assign 'left', 'right', 'jump', 'dash', 'up', 'down' in the project settings input map.
Usage Tips:
1. Hover over each toggle and variable to understand their functions and prevent bugs.
2. Animations are basic. For custom art, you may need to adjust the animation code.
"""

@export_category("Necessary Child Nodes")
@export var PlayerSprite: AnimatedSprite2D
@export var PlayerCollider: CollisionShape2D

# Horizontal Movement Settings
@export_category("L/R Movement")
# The maximum speed the player can move.
@export_range(50, 500) var maxSpeed: float = 200.0
# Time (in seconds) for the player to reach maximum speed from rest.
@export_range(0, 4) var timeToReachMaxSpeed: float = 0.2
# Time (in seconds) for the player to slow down to a stop from maximum speed.
@export_range(0, 4) var timeToReachZeroSpeed: float = 0.2
# If true, the player instantly changes direction, overriding acceleration settings.
@export var directionalSnap: bool = false
# If enabled, the player starts at half max speed and accelerates to full speed when holding the "run" button.
@export var runningModifier: bool = false

# Jumping and Gravity Settings
@export_category("Jumping and Gravity")
# The peak height of the player's jump.
@export_range(0, 20) var jumpHeight: float = 2.0
# Number of jumps available before needing to touch the ground again.
@export_range(0, 4) var jumps: int = 1
# Strength of gravity affecting the player.
@export_range(0, 100) var gravityScale: float = 20.0
# The maximum falling speed of the player.
@export_range(0, 1000) var terminalVelocity: float = 500.0
# Multiplier for gravity when the player is descending to create a less floaty jump.
@export_range(0.5, 3) var descendingGravityFactor: float = 1.3
# Enables variable jump height by cutting vertical velocity when the jump key is released.
@export var shortHopAkaVariableJumpHeight: bool = true
# Extra time (in seconds) allowed to jump after walking off a ledge.
@export_range(0, 0.5) var coyoteTime: float = 0.2
# Time window (in seconds) to buffer a jump input before landing.
@export_range(0, 0.5) var jumpBuffering: float = 0.2

# Wall Jumping Settings
@export_category("Wall Jumping")
# Enables the ability to jump off walls.
@export var wallJump: bool = false
# Duration (in seconds) to ignore input after a wall jump.
@export_range(0, 0.5) var inputPauseAfterWallJump: float = 0.1
# Angle (in degrees) at which the player jumps away from the wall.
@export_range(0, 90) var wallKickAngle: float = 60.0
# Divisor for gravity when sliding down a wall.
@export_range(1, 20) var wallSliding: float = 1.0
# If enabled, gravity is set to zero when touching a wall and descending.
@export var wallLatching: bool = false
# Requires wall latching to be enabled; holds the latch key to latch onto walls.
@export var wallLatchingModifier: bool = false

# Dashing Settings
@export_category("Dashing")
# Type of dashes the player can perform.
@export_enum("None", "Horizontal", "Vertical", "Four Way", "Eight Way") var dashType: int
# Number of dashes available before needing to touch the ground.
@export_range(0, 10) var dashes: int = 1
# If enabled, opposing dash directions will cancel the current dash.
@export var dashCancel: bool = true
# Distance the player will dash.
@export_range(1.5, 4) var dashLength: float = 2.5

# Corner Cutting and Jump Correction
@export_category("Corner Cutting/Jump Correct")
# Enables correction when the player's head is slightly blocked during a jump.
@export var cornerCutting: bool = false
# Pixels to push the player per frame for jump correction.
@export_range(1, 5) var correctionAmount: float = 1.5
# Raycasts for corner cutting calculations.
@export var leftRaycast: RayCast2D
@export var middleRaycast: RayCast2D
@export var rightRaycast: RayCast2D

# Down Input Settings
@export_category("Down Input")
# Enables crouching when holding down.
@export var crouch: bool = false
# Enables rolling when holding down and pressing the "roll" input.
@export var canRoll: bool
# Duration of the roll in seconds.
@export_range(1.25, 2) var rollLength: float = 2
# Enables ground pound functionality.
@export var groundPound: bool
# Time (in seconds) the player hovers before completing a ground pound.
@export_range(0.05, 0.75) var groundPoundPause: float = 0.25
# Allows canceling the ground pound by pressing up.
@export var upToCancel: bool = false

# Animation Settings
@export_category("Animations (Check Box if has animation)")
@export var run: bool
@export var jump: bool
@export var idle: bool
@export var walk: bool
@export var slide: bool
@export var latch: bool
@export var falling: bool
@export var crouch_idle: bool
@export var crouch_walk: bool
@export var roll: bool

# Internal Variables
var appliedGravity: float
var maxSpeedLock: float
var appliedTerminalVelocity: float

var friction: float
var acceleration: float
var deceleration: float
var instantAccel: bool = false
var instantStop: bool = false

var jumpMagnitude: float = 500.0
var jumpCount: int
var jumpWasPressed: bool = false
var coyoteActive: bool = false
var dashMagnitude: float
var gravityActive: bool = true
var dashing: bool = false
var dashCount: int
var rolling: bool = false

var twoWayDashHorizontal: bool = false
var twoWayDashVertical: bool = false
var eightWayDash: bool = false

var wasMovingR: bool
var wasPressingR: bool
var movementInputMonitoring: Vector2 = Vector2(true, true) # X for right, Y for left

var gdelta: float = 1

var dset: bool = false

var colliderScaleLockY: float
var colliderPosLockY: float

var latched: bool = false
var wasLatched: bool = false
var crouching: bool = false
var groundPounding: bool = false

var anim: AnimatedSprite2D
var col: CollisionShape2D
var animScaleLock: Vector2

# Input Variables
var upHold: bool
var downHold: bool
var leftHold: bool
var leftTap: bool
var leftRelease: bool
var rightHold: bool
var rightTap: bool
var rightRelease: bool
var jumpTap: bool
var jumpRelease: bool
var runHold: bool
var latchHold: bool
var dashTap: bool
var rollTap: bool
var downTap: bool
var twirlTap: bool

func _ready():
	wasMovingR = true
	anim = PlayerSprite
	col = PlayerCollider
	
	_updateData()

func _updateData():
	acceleration = maxSpeed / timeToReachMaxSpeed
	deceleration = -maxSpeed / timeToReachZeroSpeed
	
	jumpMagnitude = (10.0 * jumpHeight) * gravityScale
	jumpCount = jumps
	
	dashMagnitude = maxSpeed * dashLength
	dashCount = dashes
	
	maxSpeedLock = maxSpeed
	
	animScaleLock = abs(anim.scale)
	colliderScaleLockY = col.scale.y
	colliderPosLockY = col.position.y
	
	if timeToReachMaxSpeed <= 0:
		instantAccel = true
		timeToReachMaxSpeed = 1
	else:
		instantAccel = false
		
	if timeToReachZeroSpeed <= 0:
		instantStop = true
		timeToReachZeroSpeed = 1
	else:
		instantStop = false
		
	if jumps > 1:
		jumpBuffering = 0
		coyoteTime = 0
	
	coyoteTime = abs(coyoteTime)
	jumpBuffering = abs(jumpBuffering)
	
	if directionalSnap:
		instantAccel = true
		instantStop = true
	
	twoWayDashHorizontal = false
	twoWayDashVertical = false
	eightWayDash = false
	match dashType:
		0:
			# No dash
			pass
		1:
			twoWayDashHorizontal = true
		2:
			twoWayDashVertical = true
		3:
			twoWayDashHorizontal = true
			twoWayDashVertical = true
		4:
			eightWayDash = true

func _process(_delta):
	_handle_animations()

func _physics_process(delta):
	if not dset:
		gdelta = delta
		dset = true
	
	_handle_input()
	_handle_movement(delta)
	_handle_crouching()
	_handle_rolling()
	_handle_jump_and_gravity()
	_handle_dashing()
	_handle_corner_cutting()
	_handle_ground_pound()
	
	move_and_slide()

	if upToCancel and upHold and groundPounding:
		_endGroundPound()

func _handle_animations():
	# Handle sprite direction based on movement
	if is_on_wall() and not is_on_floor() and latch and wallLatching:
		if (wallLatchingModifier and latchHold) or not wallLatchingModifier:
			latched = true
		else:
			latched = false
			wasLatched = true
			_setLatch(0.2, false)
	
	if rightHold and not latched:
		anim.scale.x = animScaleLock.x
	if leftHold and not latched:
		anim.scale.x = animScaleLock.x * -1
	
	# Run and Idle Animations
	if run and idle and not dashing and not crouching:
		if abs(velocity.x) > 0.1 and is_on_floor() and not is_on_wall():
			anim.speed_scale = abs(velocity.x / 150)
			anim.play("run")
		elif abs(velocity.x) < 0.1 and is_on_floor():
			anim.speed_scale = 1
			anim.play("idle")
	elif run and idle and walk and not dashing and not crouching:
		if abs(velocity.x) > 0.1 and is_on_floor() and not is_on_wall():
			anim.speed_scale = abs(velocity.x / 150)
			if abs(velocity.x) < maxSpeedLock:
				anim.play("walk")
			else:
				anim.play("run")
		elif abs(velocity.x) < 0.1 and is_on_floor():
			anim.speed_scale = 1
			anim.play("idle")
	
	# Jump and Falling Animations
	if velocity.y < 0 and jump and not dashing:
		anim.speed_scale = 1
		anim.play("jump")
	
	if velocity.y > 40 and falling and not dashing and not crouching:
		anim.speed_scale = 1
		anim.play("falling")
	
	# Wall Slide and Latch Animations
	if latch and slide:
		if latched and not wasLatched:
			anim.speed_scale = 1
			anim.play("latch")
		if is_on_wall() and velocity.y > 0 and slide and anim.animation != "slide" and wallSliding != 1:
			anim.speed_scale = 1
			anim.play("slide")
	
	# Dash Animation
	if dashing:
		anim.speed_scale = 1
		anim.play("dash")
	
	# Crouch Animations
	if crouching and not rolling:
		if abs(velocity.x) > 10:
			anim.speed_scale = 1
			anim.play("crouch_walk")
		else:
			anim.speed_scale = 1
			anim.play("crouch_idle")
	
	# Roll Animation
	if rollTap and canRoll and roll:
		anim.speed_scale = 1
		anim.play("roll")

func _handle_input():
	# Input Detection
	leftHold = Input.is_action_pressed("left")
	rightHold = Input.is_action_pressed("right")
	upHold = Input.is_action_pressed("up")
	downHold = Input.is_action_pressed("down")
	leftTap = Input.is_action_just_pressed("left")
	rightTap = Input.is_action_just_pressed("right")
	leftRelease = Input.is_action_just_released("left")
	rightRelease = Input.is_action_just_released("right")
	jumpTap = Input.is_action_just_pressed("jump")
	jumpRelease = Input.is_action_just_released("jump")
	runHold = Input.is_action_pressed("run")
	latchHold = Input.is_action_pressed("latch")
	dashTap = Input.is_action_just_pressed("dash")
	rollTap = Input.is_action_just_pressed("roll")
	downTap = Input.is_action_just_pressed("down")
	twirlTap = Input.is_action_just_pressed("twirl")

func _handle_movement(delta):
	# Horizontal Movement
	if rightHold and leftHold and movementInputMonitoring.x and movementInputMonitoring.y:
		if not instantStop:
			_decelerate(delta, false)
		else:
			velocity.x = 0
	elif rightHold and movementInputMonitoring.x:
		if velocity.x > maxSpeed or instantAccel:
			velocity.x = maxSpeed
		else:
			velocity.x += acceleration * delta
		if velocity.x < 0:
			if not instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = 0
	elif leftHold and movementInputMonitoring.y:
		if velocity.x < -maxSpeed or instantAccel:
			velocity.x = -maxSpeed
		else:
			velocity.x -= acceleration * delta
		if velocity.x > 0:
			if not instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = 0
	
	# Update movement direction
	if velocity.x > 0:
		wasMovingR = true
	elif velocity.x < 0:
		wasMovingR = false
	
	if rightTap:
		wasPressingR = true
	if leftTap:
		wasPressingR = false
	
	# Running Modifier
	if runningModifier and not runHold:
		maxSpeed = maxSpeedLock / 2
	elif is_on_floor():
		maxSpeed = maxSpeedLock
	
	# Deceleration when no input
	if not (leftHold or rightHold):
		if not instantStop:
			_decelerate(delta, false)
		else:
			velocity.x = 0

func _handle_crouching():
	# Crouching Logic
	if crouch:
		if downHold and is_on_floor():
			crouching = true
		elif not downHold and ((runHold and runningModifier) or not runningModifier) and not rolling:
			crouching = false
	
	if not is_on_floor():
		crouching = false
	
	if crouching:
		maxSpeed = maxSpeedLock / 2
		col.scale.y = colliderScaleLockY / 2
		col.position.y = colliderPosLockY + (8 * colliderScaleLockY)
	else:
		maxSpeed = maxSpeedLock
		col.scale.y = colliderScaleLockY
		col.position.y = colliderPosLockY

func _handle_rolling():
	# Rolling Logic
	if canRoll and is_on_floor() and rollTap and crouching:
		_rollingTime(0.75)
		if wasPressingR and not upHold:
			velocity.y = 0
			velocity.x = maxSpeedLock * rollLength
			dashCount -= 1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(rollLength * 0.0625)
		elif not upHold:
			velocity.y = 0
			velocity.x = -maxSpeedLock * rollLength
			dashCount -= 1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(rollLength * 0.0625)
	
	if canRoll and rolling:
		# Additional rolling behavior can be added here.
		pass

func _handle_jump_and_gravity():
	# Jump and Gravity Logic
	if velocity.y > 0:
		appliedGravity = gravityScale * descendingGravityFactor
	else:
		appliedGravity = gravityScale
	
	if is_on_wall() and not groundPounding:
		appliedTerminalVelocity = terminalVelocity / wallSliding
		if wallLatching and ((wallLatchingModifier and latchHold) or not wallLatchingModifier):
			appliedGravity = 0
			if velocity.y < 0:
				velocity.y += 50
			elif velocity.y > 0:
				velocity.y = 0
			
			if wallLatchingModifier and latchHold and movementInputMonitoring == Vector2(true, true):
				velocity.x = 0
		elif wallSliding != 1 and velocity.y > 0:
			appliedGravity /= wallSliding
	elif not is_on_wall() and not groundPounding:
		appliedTerminalVelocity = terminalVelocity
	
	if gravityActive:
		if velocity.y < appliedTerminalVelocity:
			velocity.y += appliedGravity
		elif velocity.y > appliedTerminalVelocity:
			velocity.y = appliedTerminalVelocity
	
	if shortHopAkaVariableJumpHeight and jumpRelease and velocity.y < 0:
		velocity.y /= 2
	
	if jumps == 1:
		if not is_on_floor() and not is_on_wall():
			if coyoteTime > 0:
				coyoteActive = true
				_coyoteTime()
		
		if jumpTap and not is_on_wall():
			if coyoteActive:
				coyoteActive = false
				_jump()
			if jumpBuffering > 0:
				jumpWasPressed = true
				_bufferJump()
			elif jumpBuffering == 0 and coyoteTime == 0 and is_on_floor():
				_jump()
		elif jumpTap and is_on_wall() and not is_on_floor():
			if wallJump:
				_wallJump()
		elif jumpTap and is_on_floor():
			_jump()
		
		if is_on_floor():
			jumpCount = jumps
			coyoteActive = true
			if jumpWasPressed:
				_jump()
	
	elif jumps > 1:
		if is_on_floor():
			jumpCount = jumps
		if jumpTap and jumpCount > 0 and not is_on_wall():
			velocity.y = -jumpMagnitude
			jumpCount -= 1
			_endGroundPound()
		elif jumpTap and is_on_wall() and wallJump:
			_wallJump()

func _handle_dashing():
	# Dashing Logic
	if is_on_floor():
		dashCount = dashes
	
	if eightWayDash and dashTap and dashCount > 0 and not rolling:
		var input_direction = Input.get_vector("left", "right", "up", "down").normalized()
		var dTime = 0.0625 * dashLength
		_dashingTime(dTime)
		_pauseGravity(dTime)
		velocity = dashMagnitude * input_direction
		dashCount -= 1
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(dTime)
	
	if twoWayDashVertical and dashTap and dashCount > 0 and not rolling:
		var dTime = 0.0625 * dashLength
		if upHold and downHold:
			_placeHolder()
		elif upHold:
			_dashingTime(dTime)
			_pauseGravity(dTime)
			velocity.x = 0
			velocity.y = -dashMagnitude
			dashCount -= 1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
		elif downHold and dashCount > 0:
			_dashingTime(dTime)
			_pauseGravity(dTime)
			velocity.x = 0
			velocity.y = dashMagnitude
			dashCount -= 1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
	
	if twoWayDashHorizontal and dashTap and dashCount > 0 and not rolling:
		var dTime = 0.0625 * dashLength
		if wasPressingR and not (upHold or downHold):
			velocity.y = 0
			velocity.x = dashMagnitude
			_pauseGravity(dTime)
			_dashingTime(dTime)
			dashCount -= 1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
		elif not (upHold or downHold):
			velocity.y = 0
			velocity.x = -dashMagnitude
			_pauseGravity(dTime)
			_dashingTime(dTime)
			dashCount -= 1
			movementInputMonitoring = Vector2(false, false)
			_inputPause_reset(dTime)
	
	# Dash Cancellation
	if dashing:
		if velocity.x > 0 and leftTap and dashCancel:
			velocity.x = 0
		elif velocity.x < 0 and rightTap and dashCancel:
			velocity.x = 0

func _handle_corner_cutting():
	# Corner Cutting Logic
	if cornerCutting:
		if velocity.y < 0:
			if leftRaycast.is_colliding() and not rightRaycast.is_colliding() and not middleRaycast.is_colliding():
				position.x += correctionAmount
			elif not leftRaycast.is_colliding() and rightRaycast.is_colliding() and not middleRaycast.is_colliding():
				position.x -= correctionAmount

func _handle_ground_pound():
	# Ground Pound Logic
	if groundPound and downTap and not is_on_floor() and not is_on_wall():
		groundPounding = true
		gravityActive = false
		velocity.y = 0
		yield(get_tree().create_timer(groundPoundPause), "timeout")
		_groundPound()
	if is_on_floor() and groundPounding:
		_endGroundPound()

func _bufferJump():
	yield(get_tree().create_timer(jumpBuffering), "timeout")
	jumpWasPressed = false

func _coyoteTime():
	yield(get_tree().create_timer(coyoteTime), "timeout")
	coyoteActive = false
	jumpCount -= 1

func _jump():
	if jumpCount > 0:
		velocity.y = -jumpMagnitude
		jumpCount -= 1
		jumpWasPressed = false

func _wallJump():
	var horizontalWallKick = abs(jumpMagnitude * cos(deg2rad(wallKickAngle)))
	var verticalWallKick = abs(jumpMagnitude * sin(deg2rad(wallKickAngle)))
	velocity.y = -verticalWallKick
	var dir = wallLatchingModifier and latchHold ? -1 : 1
	velocity.x = wasMovingR ? -horizontalWallKick * dir : horizontalWallKick * dir
	if inputPauseAfterWallJump != 0:
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(inputPauseAfterWallJump)

func _setLatch(delay: float, setBool: bool):
	yield(get_tree().create_timer(delay), "timeout")
	wasLatched = setBool

func _inputPauseReset(time: float):
	yield(get_tree().create_timer(time), "timeout")
	movementInputMonitoring = Vector2(true, true)

func _decelerate(delta: float, vertical: bool):
	if not vertical:
		if velocity.x > 0:
			velocity.x += deceleration * delta
			velocity.x = max(velocity.x, 0)
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
			velocity.x = min(velocity.x, 0)
	else:
		if velocity.y > 0:
			velocity.y += deceleration * delta
			velocity.y = min(velocity.y, 0)

func _pauseGravity(time: float):
	gravityActive = false
	yield(get_tree().create_timer(time), "timeout")
	gravityActive = true

func _dashingTime(time: float):
	dashing = true
	yield(get_tree().create_timer(time), "timeout")
	dashing = false

func _rollingTime(time: float):
	rolling = true
	yield(get_tree().create_timer(time), "timeout")
	rolling = false	

func _groundPound():
	appliedTerminalVelocity = terminalVelocity * 10
	velocity.y = jumpMagnitude * 2

func _endGroundPound():
	groundPounding = false
	appliedTerminalVelocity = terminalVelocity
	gravityActive = true

func _placeHolder():
	print("")
