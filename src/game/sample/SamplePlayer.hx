package sample;

import hxd.BitmapData;
import h2d.Anim;
import format.swf.Data.ButtonRecord;
import hxd.Res;
import h2d.Object;
import h2d.Sprite;
import h2d.SpriteBatch;


class SamplePlayer extends Entity {
    var ca: ControllerAccess<GameAction>;
    var upaccel = 0.07; // Reduced acceleration
    var walkSpeed = 0.15; // Reduced base walk speed
    var maxspeed = 0.4; // Reduced max walk speed
    var dispeed = 0.3; // Adjusted deceleration speed
    public static var boost = 30; // Maximum boost (30 as per your changes)
    var drifting = 10;
    var dashSpeed = 0.0;
    var charging = 0;
    var accel = 0.03; // Slower acceleration
    var memmov = 1.0;
    var color: Int;
    var firstJump = false;
    var shieldHealth: Int;
    var shieldMaxHealth: Int = 100; // Maximum shield health
    var shieldRegenTime: Float = 8.0; // Time to regenerate shield
    var shieldCooldown: Float = 0; // Timer for shield regeneration
    var isShieldActive: Bool = true; // Whether the shield is currently active
    var spriteBatch:SpriteBatch;
    var tileGroup:h2d.TileGroup;
    var sprites:Array<Sprite>;

    var isDashing = false;
    var dashDuration = 0.02;
    var dashTimer = 0.0;
    var maxDashSpeed = 1.5; // Reduced dash speed for balance

    var onGround(get, never): Bool;
    inline function get_onGround() return !destroyed && vBase.dy == 0 && yr == 0.9 && level.hasCollision(cx, cy + 1);

    var onWallLeft = false;
    var onWallRight = false;
    var wallHuggingSpeedReduction = 0.5; // Speed reduction factor while hugging a wall
    var wallJumpStrength = 0.6; // Wall jump strength modifie



    // Jump parameters
    var jumpStrength = -1.0; // Increase this value for higher jumps

    var boostText: h2d.Text; // Text to display boost

    public function new() {
        super(5, 5);

         // Loads hxd.Res.char1_test.Player.png


        // Load all sprites for each action and boost level
        spriteBatch = new SpriteBatch();
        tileGroup = new TileGroup();
        sprites = new Array<Sprite>();




        var start = level.data.l_Entities.all_PlayerStart[0];
        if (start != null) setPosCase(start.cx, start.cy);

        vBase.setFricts(0.84, 0.94);

        camera.trackEntity(this, true);
        camera.clampToLevelBounds = true;

        ca = App.ME.controller.createAccess();
        ca.lockCondition = Game.isGameControllerLocked;

        var b = new h2d.Bitmap(h2d.Tile.fromColor(Green, iwid, ihei), spr);
        b.tile.setCenterRatio(0.5, 1);
        shieldHealth = shieldMaxHealth; // Initialize shield

        
    }
    public function loadSprites(): Void {
        try {
            // Load the sprite using hxd.Res
            var sprite = new Sprite();
            sprite.load(Res.char1_test.Player.toBitmap());
            sprites.push(sprite);
            spriteBatch.add(sprite);
        } catch (e: Dynamic) {
            trace('Failed to load sprite: $e');
        }
    }

    public function update():Void {
        // Update logic for player entity
    }



    public function render():Void {
        spriteBatch.render();
    }

    private function sign(value: Float): Int {
        if (value > 0) return 1;
        if (value < 0) return -1;
        return 0;
    }

    override function dispose() {
        super.dispose();
        ca.dispose();
        
    }

    

    override function onPreStepX() {
        super.onPreStepX();

        onWallLeft = level.hasCollision(cx - 1, cy); // Detect wall to the left
        onWallRight = level.hasCollision(cx + 1, cy); // Detect wall to the right

        if (xr > 0.4 && level.hasCollision(cx + 1, cy)) xr = 0.4;
        if (xr < 0.4 && level.hasCollision(cx - 1, cy)) xr = 0.4;
    }

    override function onPreStepY() {
        super.onPreStepY();

        if (yr > 0.9 && level.hasCollision(cx, cy + 1)) {
            setSquashY(0.5);
            vBase.dy = 0;
            vBump.dy = 0;
            yr = 0.9;
            ca.rumble(0.2, 0.06);
            onPosManuallyChangedY();
        }

        if (yr < 0.2 && level.hasCollision(cx, cy - 1)) yr = 0.2;
    }
    // Function to calculate current speed, multiplied by 1000, and return as an integer
    private function getCurrentSpeed(): Int {
        return  Math.round(Math.sqrt(Math.pow(vBase.dx, 2) + Math.pow(vBase.dy, 2)) * 10);
    }


    override function preUpdate() {
        super.preUpdate();

        walkSpeed = 0;
        if (onGround) cd.setS("recentlyOnGround", 0.1);


            // Update the sprite based on the player's state

    
        // Optionally update sprite position
        

        

        // Jumping (Ground, Air, and Wall Jump)
        if (ca.isPressed(Jump)) {
            if (onGround) {
                // Ground jump with higher jump strength
                if (boost >= 5) {
                    vBase.dy = jumpStrength + upaccel;
                    setSquashX(0.6);
                    cd.unset("recentlyOnGround");
                    spawnEffect(centerX, centerY, boost);
                    ca.rumble(0.05, 0.06);
                    boost -= 5;
                } else {
                    vBase.dy = jumpStrength * 0.8;
                    setSquashX(0.3);
                    cd.unset("recentlyOnGround");
                    spawnEffect(centerX, centerY, boost);
                    ca.rumble(0.02, 0.04);
                }
                firstJump = true; // Reset first jump on ground
            }
            // Wall Jump logic (requires 5 boost)
            else if ((onWallLeft || onWallRight) && boost >= 5) {
                // Apply a jump off the wall
                vBase.dy = wallJumpStrength; // Vertical jump strength
                if (onWallLeft) {
                    vBase.dx = 0.5 +upaccel ; // Jump to the right if touching the left wall
                } else if (onWallRight) {
                    vBase.dx = -0.5 +upaccel; // Jump to the left if touching the right wall
                }
                vBase.dy = jumpStrength + upaccel;
                boost -= 5; // Consume 5 boost for wall jump
                spawnEffect(centerX, centerY, boost);
                ca.rumble(0.05, 0.06);
                accel = upaccel;
            }
            // Air Jump
            else if (!onGround && !onWallLeft && !onWallRight && boost >= 10) {
                vBase.dy = jumpStrength + upaccel; // Disable further air jumps until grounded
                spawnEffect(centerX, centerY, boost);
                ca.rumble(0.05, 0.06);
                boost -= 10;
                firstJump = false; // Mark first jump as used
            }
        }

        // Cancel only the first jump when releasing the jump button early
        if (ca.isReleased(Jump) && firstJump && vBase.dy < 0) {
            vBase.dy *= 0.5; // Reduce the upward velocity to cancel the jump early
        }



        // Float while holding Dash in the air
        if (ca.isPadDown(B) || ca.isKeyboardDown(hxd.Key.SHIFT)&& boost > 5) {
            if (!onGround) {
                vBase.dy -= 0.02; // Apply float effect in the air
            } 
            drifting -=2;
            if (drifting <=0){
                drifting = 40;
                boost -=1;
            }
        }

        // Walk Speed logic (Move Left / Right)
        if (!isDashing && ca.getAnalogDist2(MoveLeft, MoveRight) > 0) {
            if (ca.getAnalogValue2(MoveLeft, MoveRight) != memmov) {
                accel = 0.03; // Consistent acceleration
            }
            walkSpeed = ca.getAnalogValue2(MoveLeft, MoveRight); // -1 to 1
            memmov = ca.getAnalogValue2(MoveLeft, MoveRight);
        }



        // Charging boost regeneration with increasing rate
        
        if (sign(boost)<= -1) {
            charging =0;
            boost=0;
        }


        // Dash input (initial press)
        if (ca.isPadPressed(B) || ca.isKeyboardPressed(hxd.Key.SHIFT) && boost >= 10) {
            startDash();
            boost -= 10;
        }

        // Speed boost while holding Dash
        if (ca.isPadDown(B) || ca.isKeyboardDown(hxd.Key.SHIFT) && boost > 5) {
            vBase.dx += 0.03 * sign(memmov); // Consistent speed boost for both directions
            drifting -= 2;
            if (drifting <=0){
                drifting = 40;
                boost -=1;
            }
        }
        
        
       
    }

     // Function to be called when the player is hit
     public function takeDamage(damage: Int) {
        if (isShieldActive) {
            if (shieldHealth > 0) {
                shieldHealth -= damage;
                shieldCooldown = shieldRegenTime; // Start cooldown after shield is hit
            } else {
                // If no shield, apply damage to player health
                // (Assuming you have player health)
            }
        } else {
            // Apply damage directly if shield is not active
            // (Assuming you have player health)
        }
    }

    override function fixedUpdate() {
        super.fixedUpdate();

    

        if (!onGround) vBase.dy += 0.05; // Normal gravity
        if (onGround) upaccel = 0.07;

        if (isDashing) {
            dashTimer -= 1 / 30;
            if (dashTimer <= 0) {
                isDashing = false;
                dashSpeed = 0;
            }
        } else {
            if (walkSpeed != 0) {
                vBase.dx += walkSpeed * accel;
                if ((walkSpeed * accel)*sign(walkSpeed) <= maxspeed -dispeed  && onGround) {
                    accel += 0.002;
                    if (walkSpeed * accel <= maxspeed) {
                        accel += 0.003;
                    }
                }
            } else {
                accel = 0.03;
            }
        }

        if (boost < 30 && !ca.isPadDown(B) && !ca.isKeyboardDown(K.SHIFT)  ) {
            charging += 1;
            if (onGround) charging += 3;
            if (charging >= (30 -boost)) { // Faster regen as boost decreases
                boost += 1;
                charging = 0;
            }
        } 

        if (isDashing && Math.abs(vBase.dx) > maxDashSpeed) {
            vBase.dx = sign(vBase.dx) * maxDashSpeed;
        }

         // Handle shield regeneration
         if (shieldHealth < shieldMaxHealth && shieldCooldown <= 0) {
            shieldHealth += 1; // Regenerate shield over time
        } else if (shieldCooldown > 0) {
            shieldCooldown -= 1 / 30; // Decrease cooldown
        }
    }
    

    private function startDash() {
        if (memmov == 0) return;

        isDashing = true;
        dashTimer = dashDuration;

        dashSpeed = memmov * maxDashSpeed;

        var appliedSpeed = accel * 5 > 0.3 ? dashSpeed * accel * 5 : dashSpeed * 0.3;
        vBase.dx += appliedSpeed;

        if (Math.abs(vBase.dx) > maxDashSpeed) {
            vBase.dx = sign(vBase.dx) * maxDashSpeed;
        }

        spawnEffect(centerX, centerY, boost); // Dash effect
        ca.rumble(0.1, 0.1);
        accel = 0.2;
    }

    private function spawnEffect(x: Float, y: Float, boost: Int) {
        var color: Int;
        if (boost >= 20) {
            color = 0x0000ff; // Blue
        } else if (boost >= 10) {
            color = 0x00ff00; // Green
        } else if (boost >= 1) {
            color = 0xffff00; // Yellow
        } else {
            color = 0xff0000; // Red
        }
        fx.dotsExplosionExample(x, y, color);
    }
    override function frameUpdate() {
		super.frameUpdate();
        debug( boost + "  boost |" +" speed   "+getCurrentSpeed());
    }


}


