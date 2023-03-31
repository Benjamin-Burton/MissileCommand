/*******************************************************************************
* EnemySmartBomb class
* An object for representing smart bombs attacking the player's cities from
* the top of the screen.
* When created, the smartbomb will target a random city and appear form a random
* point along the top of the screen. 
* It will only target cities that have not yet been destroyed, and will move
* away from antiballistic missiles fire at it.
* Can only be destroyed by the player's SpecialAttack.
*******************************************************************************/
public class EnemySmartBomb {

  private PVector initPos, currPos, targetPos, velocity, closestAbmPos;
  private float speed;
  private boolean live, movingAway;
  private int movingAwayFrameCount;


  //Constructor
  public EnemySmartBomb() {

    // Randomly generate a starting position for the smart bomb
    this.initPos = new PVector(
      random(0, width), 
      random(-(height / 3f), -(height / 12f))
    );

    // Set the currPos to the initial position
    this.currPos = new PVector(initPos.x, initPos.y);

    // Target a random standing city
    City targetCity = standingCities.get((int)random(0, standingCities.size()));
    this.targetPos = targetCity.getLocation();

    // The velocity is computed as the normal direction from the starting
    // position to the target
    this.velocity = PVector.sub(this.targetPos, this.currPos).normalize();

    // Set smart bomb speed
    this.speed = 6 / (targetFrameRate / 30f);

    // Smart bomb starts live
    this.live = true;
  }

  public void draw() {
    /* Draw the SmartBomb */
    fill(230);
    ellipse(this.currPos.x, this.currPos.y, 20, 20);
    fill(random(0,255),random(0,255),random(0,255),150);
    ellipse(this.currPos.x, this.currPos.y, 25, 25);
    textSize(12);
    textAlign(CENTER, CENTER);
    fill(0);
    text("X", this.currPos.x, this.currPos.y);
  }

  public void update() {
    if (!this.isLive()) {
      return;
    }

    this.advance();
  }

  // updates the position of the smart bomb, and handles
  // moving away from player abms
  public void advance() {
    // find the closest abm
    this.closestAbmPos = null;
    
    for (AntiballisticMissile abm : abms) {
      if (this.closestAbmPos == null) {
        this.closestAbmPos = abm.getCurrPos();
      }
      if (this.currPos.dist(abm.currPos) <
          this.currPos.dist(this.closestAbmPos)) {
              this.closestAbmPos = abm.getCurrPos();
          }
    }
    // if too close, move away 
    if (this.closestAbmPos != null && this.currPos.dist(this.closestAbmPos) < 100
        && !this.movingAway) {
        this.velocity = PVector.sub(this.closestAbmPos, this.currPos).normalize().mult(-1);
        this.movingAway = true;
        this.movingAwayFrameCount = 0;
        } else if (this.movingAway) {
        this.movingAwayFrameCount++;
        if (this.movingAwayFrameCount == 8) {
          this.movingAway = false; 
        }
    } else {
      // otherwise, continue to travel toward target
      this.velocity = PVector.sub(this.targetPos, this.currPos).normalize();
    }
    
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
  
  // Set target a random standing city
  public void setTarget() {
    City targetCity = standingCities.get((int)random(0, standingCities.size()));
    this.targetPos = targetCity.getLocation();
  }
}
