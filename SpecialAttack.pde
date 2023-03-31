/*******************************************************************************
* SpecialAttack missile class
* An object for representing the player's special attack (right click) 
* Travels quickly to the position clicked, and detonates there, destroying
* any EnemySmartBombs in the area. Does not destroy EnemyMissiles. 
* If the special attack missile collides with an enemy missiles while it is
* travelling towards its target, it is destroyed without detonating.
*******************************************************************************/
public class SpecialAttack {
  
  private PShape shape;
  private PVector currPos, targetPos, velocity;
  private boolean reachedTarget, live, exploding;
  private float angle, speed, radius, explosionRadius;
  
  /* Constructor
  /      Parameter:
  /           PVector - the location of the target. */ 
  public SpecialAttack(PVector targetPos) {
    this.currPos = new PVector(width*0.5, height*0.77);
    this.targetPos = targetPos; // pass in where user clicked
    this.reachedTarget = false;
    this.velocity = PVector.sub(this.targetPos, this.currPos).normalize();
    this.speed = 40 / (targetFrameRate / 30f);
    this.angle = 0.05 * PI;
    this.radius = width * 0.005;
    this.explosionRadius = this.radius * 10;
    this.live = true;
    
    // create the special attack shape
    this.shape = createShape();
    this.shape.beginShape();
    this.shape.fill(8,249,255,180);
    this.shape.vertex(-this.radius,0);
    this.shape.vertex(-this.radius / 4, -this.radius / 4);
    this.shape.vertex(0,-this.radius);
    this.shape.vertex(this.radius / 4, -this.radius / 4);
    this.shape.vertex(this.radius, 0);
    this.shape.vertex(this.radius / 4, this.radius / 4);
    this.shape.vertex(0, this.radius);
    this.shape.vertex(-this.radius / 4, this.radius / 4);
    this.shape.vertex(-this.radius, 0);
    this.shape.endShape(CLOSE);
  
    // sound
    fireSpecial.play();
  }
  
  // updates the position of the SpecialAttack if it has not reached
  // its target
  public void update() {
    
    // Advance towards target by a factor of speed if not exploding
    if (!this.reachedTarget) {
      this.currPos.add(PVector.mult(this.velocity, this.speed));
      
      // Check for arrival at target position
      // Must check less than or equal to speed as may overshoot
      if (PVector.dist(this.currPos, this.targetPos) <= this.speed
        && !this.exploding) {
        // reached target!  
          
        // Copy the targetPos PVector object rather than
        // assigning currPos to targetPos in memory
        this.currPos = this.targetPos.copy();
        this.reachedTarget = true;
        this.detonate();
      }
    }
    
    // check for collision with ems - will instantly destroy attack 
    for (EnemyMissile em : activeEMs) {
      if (this.detectCollision(em.getPosition())) {
        this.live = false;
      }
    }
  }
  
  // draws the Special Attack. 
  // Handles the states of travelling to target and animation of
  // the explosion.
  public void draw() {
    if (!this.live) { return; }
    
    if (!this.exploding) {
      // rotate shape as we travel - note rotation accrues      
      this.shape.rotate(this.angle);
      shape(this.shape, currPos.x, currPos.y);  
    } else {
        // exploding
        fill(255,79,44,180);
        ellipse(this.currPos.x, this.currPos.y, this.explosionRadius, this.explosionRadius);
        stroke(255,79,44,80);
        strokeWeight(1);
        // EMP-like lines
        line(0, this.currPos.y, width, this.currPos.y);
        line(this.currPos.x, 0, this.currPos.x, height);
        
        this.explosionRadius -= this.radius / 2; // will be 0 after 20 frames
        noStroke();
        
        if (this.explosionRadius < 0) {
          this.exploding = false;
          this.live = false;
        }
    }
  }
  
  // Detonates the Special Attack, changes its state to exploding, and
  // destroys EnemySmartBombs in the area.
  public void detonate() {
    this.exploding = true;
    
    for (EnemySmartBomb esb : waveESBs) {
      if (this.detectCollision(esb.getPosition())) {
        esb.destroy();
      }
    }
    
    // sound
    if (fireSpecial.isPlaying()) {
      fireSpecial.stop();
    }
    detonateSpecial.play();
  }

  // detects collision, depending on state.
  // Parameter:
  //     PVector - the position of the object to check collision with.
  public boolean detectCollision(PVector em) {
    // this is used for checkign collision between the blast radius and a smart bomb
    if (this.reachedTarget) {
      return PVector.dist(this.currPos, em) <= this.radius * 4;
    }
    // otherwise, use this for checking collision with enemy missiles
    return PVector.dist(this.currPos, em) <= this.radius;
  }

  public boolean isLive() {
    return this.live;
  }
  
  public PVector getCurrPos() {
    return this.currPos;
  }
}
