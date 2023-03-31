/*******************************************************************************
* City class    
* An object for representing one of the player's cities.
* There are always 6 cities at the bottom of the screen. If this city is hit
* by an enemey attack, it is detected and this.destroyed will be set to true, 
* in which case the city will draw itself as rubble. 
* If all 6 cities are destroyed, the game is over.
*******************************************************************************/
class City {
  // xPos is variable, city width is 5% of canvas width, yPos is 85% of canvas
  // height, city (max) height is 2/30 of canvas height.

  // Cities are made up of 8 buildings, each building (width / 160) wide.

  private PVector location;
  private PShape shape;
  private boolean destroyed;
  private int destructionFrame, destructionBegin;

  /* Constructor
  *     Parameter:
  *       float - the x coordinate of the city 
  */
  public City(float xPos) {
    this.location = new PVector(xPos, height * 0.85);
    this.shape = standing();
    this.destroyed = false;
    this.destructionFrame = -1;
  }
  
  // Used to create the shape of the city when it is not destroyed.
  public PShape standing() {
    PShape s =  createShape();
    
    s.beginShape();
      s.fill(95, 111, 231);
      s.noStroke();
      s.vertex(0, 0);
      s.vertex(0, -22);
      s.vertex(12, -22);
      s.vertex(12, -48);
      s.vertex(24, -48);
      s.vertex(24, -70);
      s.vertex(36, -70);
      s.vertex(36, -54);
      s.vertex(48, -54);
      s.vertex(48, -38);
      s.vertex(60, -38);
      s.vertex(60, -60);
      s.vertex(72, -60);
      s.vertex(72, -72);
      s.vertex(84, -72);
      s.vertex(84, -24);
      s.vertex(96, -24);
      s.vertex(96, 0);
    s.endShape(CLOSE);
    s.scale(width / 1920f, height / 1080f);

    return s;
  }
  
  // Used to create the shape of the city when it is destroyed.
  public PShape destroyed() {
    PShape s =  createShape();
    
    s.beginShape();
      s.fill(95);
      s.noStroke();
      s.vertex(0, 0);
      s.vertex(0, -6);
      s.vertex(12, -6);
      s.vertex(12, -10);
      s.vertex(24, -10);
      s.vertex(24, -14);
      s.vertex(36, -14);
      s.vertex(36, -8);
      s.vertex(48, -8);
      s.vertex(48, -12);
      s.vertex(60, -12);
      s.vertex(60, -10);
      s.vertex(72, -10);
      s.vertex(72, -14);
      s.vertex(84, -14);
      s.vertex(84, -8);
      s.vertex(96, -8);
      s.vertex(96, 0);
    s.endShape(CLOSE);
    s.scale(width / 1920f, height / 1080f);

    return s;
  }

  // If the city is hit by a missile, it is destroyed
  public void destroy() {
    this.destroyed = true;
    this.shape = destroyed();
    cityHit = true;
    cityHitFrame = frameCount;
    
    destroyCity.play();
    
    this.destructionFrame++;
    this.destructionBegin = frameCount;
  }

  /* Handles drawing the city in all its states - standing, destroyed,
  *  or being destroyed. 
  */ 
  public void draw() {

    shapeMode(CORNER);
    shape(this.shape, this.location.x, this.location.y);

    if (
      this.destructionFrame >= 0
      && this.destructionFrame < cityDestructionFrames
    ) {
      imageMode(CENTER);
      image(
        cityDestruction[this.destructionFrame],
        // Tranform coordinates to center animation
        this.location.x + width * 0.025f,
        this.location.y - height * (42 / 1080f)
      );
      
      if (
        (frameCount - this.destructionBegin)
        % (float)(targetFrameRate / (cityDestructionFrames / 1.5))
        < 1 
      ) {
        this.destructionFrame++;
      }
    }
  }
  
  /* Detects a collision between an enemy missile and the city using
  *  an algorithm adapted from:
  *  Parameter: 
  *  PVector - the current position of the missile.
  *  "Polygon/Point Collision Detection" by Jeffrey Thompson
  *  (http://www.jeffreythompson.org/collision-detection/poly-point.php)
  *  under CC BY-NC-SA 4.0 
  *  (https://creativecommons.org/licenses/by-nc-sa/4.0/) */
  public boolean detectCollision(PVector missile) {
    boolean collision = false;
    
    // early exit for efficiency
    if (missile.y < height * 0.75) return collision;
    
    PVector[] city = transformCoords(this.shape);

    for (int i = 0; i < city.length; i++) {
      int j = i + 1; // The next vertex in the shape

      // If i is last vertex, the next vertice j is the first vertex
      if (j == city.length) {
        j = 0;
      }

      PVector v1 = city[i]; // Vertex 1
      PVector v2 = city[j]; // Vertex 2

      /** Based on (https://en.wikipedia.org/wiki/Jordan_curve_theorem), if the
       *  collision boolean is reversed an even number of times, no collision
       *  has occured and conversely if the collision boolean is reversed an odd
       *  number of times, collision has occured.
       */
      if (
        (
        (v1.y >= missile.y && v2.y < missile.y)
        ||
        (v1.y < missile.y && v2.y >= missile.y)
        )
        &&
        (missile.x < (v2.x - v1.x) * (missile.y - v1.y) / (v2.y - v1.y) + v1.x))
      {
        collision = !collision; // Reverse the current state of collision
      }
    }

    if (collision) {
      this.destroy();
    }

    return collision;
  }

  // Take the vertices, which are defined in relation to the bottom-left point
  // of the city on a 1920*1080 canvas, and transform them to fit the canvas 
  public PVector[] transformCoords(PShape s) {
    PVector[] transformed = new PVector[s.getVertexCount()];

    for (int i = 0; i < transformed.length; i++) {
      transformed[i] = new PVector(
        this.location.x + width * (s.getVertex(i).x / 1920f),
        this.location.y + height * (s.getVertex(i).y / 1080f)
      );
    }

    return transformed;
  }

  public boolean isDestroyed() {
    return this.destroyed;
  }

  // Returns the point at the bottom-center of the city
  public PVector getLocation() {
    // Adjust x to center of city
    PVector adjustedLocation = new PVector(
      this.location.x + width * 0.025, // x coordinate
      this.location.y                  // y coordinate
    );    

    return adjustedLocation;
  }
  
  // this is used to set the colour of the city to orange
  // when it is being counted between waves.
  public void count() {
    this.shape.setFill(#FFBF17);
  }
  
  /* For testing, remove later */
  public void dummyKill() {
    this.destroyed = true;
    this.shape = destroyed();
  }

  /* For testing purposes, to be removed later */
  public void reset() {
    this.shape = standing();
    this.destroyed = false;
    this.destructionFrame = -1;
  }
}
