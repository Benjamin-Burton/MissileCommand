/*******************************************************************************
* Star class
* An object for representing stars drawn to the background. 
* Randomly varies their position and brightness a small amount.  
*******************************************************************************/
class Star {

  PVector originalPosition, currPosition;
  color starColor;
  float maxBrightness;
  private boolean grayscale;

  // Constructor:
  // Parameters:
  //    float: the x coordinate of the star
  //    float: the y coordinate of the star
  //    color: the colour of the star
  //    float: the maximum brightness of the star (sets alpha val)
  Star(float x, float y, color starColor, float maxBrightness) {
    this.originalPosition = new PVector(x, y);
    this.currPosition = new PVector(x, y);
    this.starColor = starColor;
    this.maxBrightness = maxBrightness;
    this.grayscale = false;
  }
  
  // used to set greyscale version of star for game over screen
  public void setGrayscale(boolean state) {
    this.grayscale = state;
  }
  
  // draws the star to the screen
  void display() {
    noStroke();
    fill(starColor);
    rect(this.currPosition.x, this.currPosition.y, 5, 5);
  }

  // varies the position on the screen
  void update() {
    this.currPosition.x += random(-3, 3);

    // randomly change alpha value 4 times per second
    if (frameCount % (targetFrameRate / 4f) == 0) {
      // Get the color values from starColor
      float alphaVal = alpha(this.starColor);

      // Randomly change the alpha value
      alphaVal = constrain(
        alphaVal += int(random(-2, 3)) * 16, 
        maxBrightness - 64, 
        maxBrightness
        );

      // Reassign the starColor
      if (this.grayscale) {
        this.starColor = 
          color(159, alphaVal);
      } else {
        this.starColor = color(255, 255, 0, alphaVal);
      }
    }
  }
}
