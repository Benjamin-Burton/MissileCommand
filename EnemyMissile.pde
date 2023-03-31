/*******************************************************************************
* EnemyMissile class    
* An object for representing the missiles attacking the player's cities from
* the top of the screen.
* When created, the missile will target a random city and appear form a random
* point along the top of the screen.
* It will target cities even if they are already destroyed.
*******************************************************************************/
public class EnemyMissile {

  private PVector initPos, currPos, targetPos, velocity;
  private float speed, angle;
  private boolean live;

  // Constructor
  public EnemyMissile() {

    // Randomly generate a starting position for the missile
    this.initPos = new PVector(
      random(0, width), 
      random(-(height / 3f), -(height / 12f))
    );

    // Set the currPos to the initial position
    this.currPos = new PVector(initPos.x, initPos.y);

    // Target a random city
    City targetCity = cities.get((int)random(0, cities.size()));
    this.targetPos = targetCity.getLocation();

    // The velocity is computed as the normal direction from the starting
    // position to the target
    this.velocity = PVector.sub(this.targetPos, this.currPos).normalize();

    // Changes based on wave
    this.speed = constrain(2 + (wave * 0.1f), 2, 3.5);

    // Angle (radians) between initial missile position and target position
    this.angle = this.velocity.heading();

    // Missile starts live
    this.live = true;
  }
  
  /* Draw the missile */
  public void draw() {
    
    shapeMode(CORNER);
    missileShape.setFill(143);
    
    // Move to current position
    missileShape.translate(this.currPos.x, this.currPos.y);

    // Rotate towards target (add 90 degrees to take into account the
    // initial orientation of ellipse shape)
    missileShape.rotate(radians(90) + this.angle);

    // Draw shape
    shape(missileShape);

    // Reset shape before next frame
    missileShape.resetMatrix();

    /* Draw a trail for the missile */

    // Set trail thickness
    strokeWeight(3);

    // Set trail colour
    stroke(127, 95);

    // Draw the trail    
    line(initPos.x, initPos.y, currPos.x, currPos.y);
    
    noStroke();
  }

  // updates the position of the missile if it is live
  public void update() {
    if (!this.isLive()) {
      return;
    }

    this.advance();
  }
  
  // updates the missile's position, destroys it if it reaches the ground
  public void advance() {
    // Position of missile moves according to velocity
    this.currPos.add(PVector.mult(this.velocity, this.speed));

    if (this.currPos.y >= height * 900 / 1080f) {
      this.destroy();
    }
  }

  // Check, and return, if missile is currently live
  public boolean isLive() {
    return this.live;
  }

  // When reaching the ground or hit by ABM
  public void destroy() {
    this.live = false;
  }

  public PVector getPosition() {
    return this.currPos;
  }
}
