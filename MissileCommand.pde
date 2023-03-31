/*******************************************************************************
* Missile Command - by Timmothy White, Steven Brown, and Benjamin Burton
* for COSC101 Assessment 3. 
* 
* This program is heavily influenced by the original Missile Command game.
* The player is the sole defender of six planetary cities which are being
* attacked from an unknown location, with interplanetary missiles. 
* The player controls a turret which can fire anti-ballistic missiles and 
* must use these to defend the cities from waves of attacks by the power of
* the left mouse button. 
* 
* As the waves progress, incoming missiles get faster, and the score for
* hitting them also increases. 
* If the player survives until wave 6, the enemy gets un upgrade and starts
* using smart bombs which evade the normal antiballistic missiles. Luckily, 
* just at this time, the turret is upgraded with a special weapon (accessed
* by clicking the right mouse button) which is capable of countering the smart 
* bombs - but the player shouldn't use them too quickly! They are in short 
* supply. 
*
* We have implemented a title screen, endless wave system, gameover screen, 
* multiple classes, and PVectors. We have attempted to make the game scalable, 
* but it has been designed to run at 1920x1080 resolution.
* All sound and music in the game were created by Benjamin Burton except 
* level-music-2.mp3, which was composed by Vincent Chambers and used with
* permission. Copyright AllyWay Music St Clair Sydney. 
* Visuals that were not drawn by us have been referenced in the code. 
*******************************************************************************/

import processing.sound.*;

/*******************************************************************************
* Global variables                                                             *
*******************************************************************************/
Sound s; // To control Sound library
int abmsRemaining, abmBatteries, abmsLoaded, refireDelay, score, wave,
  targetFrameRate, cityDestructionFrames, abmExplosionFrames, cityHitFrame,
  currEM, scoreMultiplier, messageStartFrame, messageDuration, cityIdx,
  waveBeginFrame, waveEndFrame, startFrame, messageColour, gameOverFrame,
  esbsInWave, currESB, specialsRemaining;
String message;
PImage[] cityDestruction, abmExplosion;
PShape bgShape; // Red portion of the background image
PShape missileShape, turretArm, specialAttackShape;
boolean weaponCooldown, started, frame, countingAmmo, countingCities, cityHit,
  showMessage, betweenWaves, gameOver, specialAttackInProgress;
float bulletRadius, turretRadius, specialAttackRadius;
// Variables for title screen
boolean showTitleScreen;
PFont mainFont; // a bitmap/pixel font to match the aesthetic
color[][] titleCols = { // colour combinations to be used on title screen
  {#FF1700, #000000}, // red, black
  {#00E7FF, #FFFFFF}, // cyan, white
  {#00DF00, #FFEF00}, // green, yellow
  {#FF27FF, #000FFF}  // magenta, blue
};
int currColIdx, textColIdx, explosionColIdx, prevColIdx;
// array to hold 'explosions' that occur on title screen
PShape[] titleScreenExplosions;
SpecialAttack specialAttack;

// For the screen flashing when cities are destroyed
int[] screenFlashColour;

Star[] stars;
ArrayList<City> cities, standingCities;
ArrayList<AntiballisticMissile> abms;
ArrayList<EnemyMissile> waveEMs;
ArrayList<EnemyMissile> activeEMs;
ArrayList<EnemySmartBomb> waveESBs;
ArrayList<EnemySmartBomb> activeESBs;

// variables to hold music and sound effects
SoundFile titleMusic, levelMusic, fireAbm, detonateAbm, missilesIncoming, 
          destroyCity, gameOverSound, destroyMissile, countAmmo, 
          createSmartBomb, fireSpecial, detonateSpecial;

/*******************************************************************************
* setup() - initialise all required values and load shapes, images and sounds
* into memory.
*******************************************************************************/
void setup() {
  fullScreen();
  noCursor(); // Reticle drawn instead
 
  // Tried using built-in frameRate variable with undesirable results
  targetFrameRate = 60;
  frameRate(targetFrameRate);
  
  // To control elements from Sound library
  s = new Sound(this);
  s.volume(0.25); // a way to change the volume

  /** 
   *  The city 'nuke' animation was sourced from https://tenor.com/bL8Na.gif
   *  and made into frames to be used in Processing
   */
  cityDestructionFrames = 10;
  cityDestruction = new PImage[cityDestructionFrames];
  loadAnimation("cityDestruction", cityDestruction, "png");

  /** 
   *  The antiballistic missile explosion animation was sourced from
   *  https://i.gifer.com/3iCN.gif, modified and made into frames to be used in
   *  Processing
   */
  abmExplosionFrames = 14;
  abmExplosion = new PImage[abmExplosionFrames];
  loadAnimation("abmExplosion", abmExplosion, "png");

  // Font obtained from https://fonts.google.com/specimen/Press+Start+2P and
  // licensed under the Open Font License.
  mainFont = createFont("data/font/PressStart2P.ttf", 160);

  // Define the background shape
  bgShape = createShape();
  bgShape.beginShape();
  bgShape.fill(255, 0, 0);
  bgShape.noStroke();
  bgShape.vertex(0, height*0.95);
  bgShape.vertex(0, height*0.80);
  bgShape.vertex(width*0.05, height*0.80);
  bgShape.vertex(width*0.05, height*0.85);
  bgShape.vertex(width*0.95, height*0.85);
  bgShape.vertex(width*0.95, height*0.8);
  bgShape.vertex(width, height*0.8);
  bgShape.vertex(width, height*0.95);
  bgShape.endShape(CLOSE);
  
  // Initialise the array of stars to go over the background
  stars = new Star[36*3];
  createStars();

  // Define the missile shape
  /** Note: I found to have a PShape rotate around it's center rather than it's
   *  top-left point, simply setting shapeMode(CENTER) was insufficient.
   *  Instead, define the shape around (0, 0), that is have the center of the
   *  shape be at (0, 0).
   */
  // Define by pixel to make life easier
  missileShape = createShape();
  missileShape.beginShape();
  missileShape.noStroke();
  missileShape.vertex(-1, -9);
  missileShape.vertex(1, -9);
  missileShape.vertex(2, -6);
  missileShape.vertex(2, 2);
  missileShape.vertex(4, 5);
  missileShape.vertex(4, 7);
  missileShape.vertex(2, 7);
  missileShape.vertex(2, 9);
  missileShape.vertex(-2, 9);
  missileShape.vertex(-2, 7);
  missileShape.vertex(-4, 7);
  missileShape.vertex(-4, 5);
  missileShape.vertex(-2, 2);
  missileShape.vertex(-2, -6);
  missileShape.endShape(CLOSE);
  // After defined by pixel, scale it to the correct size
  missileShape.scale(width / 1920f, height / 1080f);

  // Define the turret-arm shape
  turretArm = createShape();
  turretArm.beginShape();
  turretArm.fill(255);
  turretArm.noStroke();
  turretArm.vertex(0,0);
  turretArm.vertex(-width*0.003,0);
  turretArm.vertex(-width*0.003,-height*0.035);
  turretArm.vertex(width*0.003,-height*0.035);
  turretArm.vertex(width*0.003,0);
  turretArm.endShape(CLOSE);
  
  // define the special attack shape
  // (only used for displaying as ammunition)
  specialAttackRadius = width * 0.005;
  specialAttackShape = createShape();
    specialAttackShape.beginShape();
    specialAttackShape.fill(8,249,255,180);
    specialAttackShape.vertex(-specialAttackRadius,0);
    specialAttackShape.vertex(-specialAttackRadius / 4, -specialAttackRadius / 4);
    specialAttackShape.vertex(0,-specialAttackRadius);
    specialAttackShape.vertex(specialAttackRadius / 4, -specialAttackRadius / 4);
    specialAttackShape.vertex(specialAttackRadius, 0);
    specialAttackShape.vertex(specialAttackRadius / 4, specialAttackRadius / 4);
    specialAttackShape.vertex(0, specialAttackRadius);
    specialAttackShape.vertex(-specialAttackRadius / 4, specialAttackRadius / 4);
    specialAttackShape.vertex(-specialAttackRadius,0);
    specialAttackShape.scale(1.15);
    specialAttackShape.endShape(CLOSE);
  
  // sets up the first wave ready to go
  startGame();
  
  // Initialise title screen requirements
  showTitleScreen = true;
  titleScreenExplosions = new PShape[0];
  
  // Initialise title screen 'explosions' animation
  screenFlashColour = new int[4]; // values for RGBA channels
  screenFlashColour[0] = 255;
  screenFlashColour[1] = (int)random(0, 256);
  screenFlashColour[2] = 0;
  if (screenFlashColour[1] == 255) {
    screenFlashColour[2] = 255;
  }
  screenFlashColour[3] = (int)random(111, 144);

  turretRadius = width * 0.01;
  bulletRadius = width * 8 / 1920f;
 
  // Load music and sound effects into memory
  titleMusic = new SoundFile(this, "data/sound/title-music.wav");
  levelMusic = new SoundFile(this, "data/sound/level-music-2.mp3");
  destroyCity = new SoundFile(this, "data/sound/destroy-city.wav");
  fireAbm = new SoundFile(this, "data/sound/fire-abm.wav");
  detonateAbm = new SoundFile(this, "data/sound/detonate-abm.wav");
  gameOverSound = new SoundFile(this, "data/sound/game-over-sound.wav");
  missilesIncoming = new SoundFile(this, "data/sound/missiles-incoming.wav");
  destroyMissile = new SoundFile(this, "data/sound/destroy-missile.wav");
  countAmmo = new SoundFile(this, "data/sound/count-ammo.wav");
  createSmartBomb = new SoundFile(this, "data/sound/create-smart-bomb.wav");
  fireSpecial = new SoundFile(this, "data/sound/fire-special.wav");
  detonateSpecial = new SoundFile(this, "data/sound/detonate-special.wav");
}

/*******************************************************************************
* draw() - execute the game loop
*******************************************************************************/
void draw() {
  // Draw the title screen while showTitleScreen boolean is true
  if (showTitleScreen) {
    titleScreen();
    return;
  }

  // Once the game has started
  if (started) {    
    if (!levelMusic.isPlaying()) {
      titleMusic.stop();
      levelMusic.loop();
    }

    
    // Allow firing ABMs again once less than 3 are active (provided some left)
    if (abms.size() < 3 && abmsRemaining > 0) {
      weaponCooldown = false;
    }
    
    // Draw all elements to the screen
    drawBackground(); //<>//
    drawZiggurat();
    drawAmmo();
    drawTurret();
    drawCities();
    drawScore();

    // Replace cursor with reticle (aka crosshairs)
    drawReticle();

    // Draw any message to the screen
    if (showMessage) {
      displayMessage();
    }

    if (frameCount <= startFrame + targetFrameRate) {
      return;
    }

    // update special attack
    if (specialAttackInProgress) {
      specialAttack.update();
      
      if (!specialAttack.isLive()) {
        specialAttackInProgress = false;
        specialAttack = null;
      } else {
        specialAttack.draw();
      }
    }

    updateABMs();
    // this updates the EMs which includes ending the wave
    // or starting a new wave
    updateEMs();  
    
    if (cityHit) {
      screenFlash();
    }

    // Perform collision detection
    collisionDetection();
    
    return;
  }

  if (gameOver) {
    gameOver();
    return;
  }

  // displays the background between showing the title screen
  // and playing the game
  drawBackground();
  drawZiggurat();
  drawStars();
  drawCities();
  if (showMessage) {
    displayMessage();
  }
  return;
}

/*******************************************************************************
* loadAnimation() Load animations procedurally. Used to load files in 
* /data/img with names of the structure <fileName>_<frameNumber>.<fileType>
* Parameters:
*   String, the stem part of file names of the animation to load
*   PImage[], the (global) array to populate with images
*   String, the file extension (not including ".")
*******************************************************************************/
void loadAnimation(String fileName, PImage[] imgArray, String fileType) {
  for (int i = 0; i < imgArray.length; i++) {
    imgArray[i] = loadImage(
      "data/img/" + fileName + "_" + i + "." + fileType
    );
  }
}

/*******************************************************************************
* startGame() - sets various variables to start-of-game states (after title
* screen or game over screen)
*******************************************************************************/
void startGame() {
  score = 0;
  wave = 0;
  currEM = -1;
  currESB = -1;
  started = false;
  gameOver = false;
  cities = new ArrayList<City>(); // There are always six cities in the game
  standingCities = new ArrayList<City>();
  createCities();
  cityIdx = 0;
  waveBeginFrame = frameCount;
  messageColour = 0;
  abms = new ArrayList<AntiballisticMissile>(); 
  esbsInWave = 0;
  abmsRemaining = 30;
  specialsRemaining = 0;
  weaponCooldown = false;
  cityHit = false;
  showMessage = false;
  betweenWaves = false;
  specialAttackInProgress = false;
}

/*******************************************************************************
* createStars() - used to initially create the Stars that appear in the 
* background display. These are implemented as objects of class Star. 
*******************************************************************************/
void createStars() {
  for (int row = 0; row < 6; row++) {
    for (int i = 0; i < 6; i++) {
      // bright star
      Star newStar = new Star(
        (width*0.02 + (i * (width * 0.18))) + random(-width*0.05, width*0.05), 
        10 + row * 100 + random(-height*0.05, height*0.05), 
        color(255, 255, 0, int(random(192, 256))), 
        255
      );

      // dim stars
      Star newDimStar = new Star(
        (width*0.02 + (i * (width * 0.18))) + random(-width*0.1, width*0.1), 
        10 + row * 100 + random(-height*0.1, height*0.1), 
        color(255, 255, 0, int (random(128, 192))), 
        191
      );

      // dimmer stars
      Star newDimmerStar = new Star(
        (width*0.02 + (i * (width * 0.18))) + random(-width*0.2, width*0.2), 
        10 + row * 100 + random(-height*0.2, height*0.2), 
        color(255, 255, 0, int(random(64, 128))), 
        127
      );

      stars[i + row*6] = newStar;
      stars[36 + i + row*6] = newDimStar; // adds dim star to end of array
      stars[72 + i + row*6] = newDimmerStar;
    }
  }
}

/*******************************************************************************
* createCities() - used to initially create the Stars that appear in the 
* background display. These are implemented as objects of class Star.                                                      *
*******************************************************************************/
void createCities() {
  for (int i = 0; i < 6; i++) {
    if (i < 3) {
      cities.add(new City((i + 1) * width * 200 / 1920f));
    } else {
      cities.add(
        new City((i + 1) * width * 200 / 1920f + width * 422 / 1920f)
      );
    }
  }

  standingCities.addAll(cities); // All cities begin as standing cities
}

/*******************************************************************************
* UpdateEMs() Updates the state of enemy missile objects and (optionally) array.
* Handles the creation of missiles as a wave progresses, adding more missiles
* and smart bombs as others are destroyed. Also handles the behaviour at the
* end of a wave: counting ammunition and remaining cities, updating the score,
* and beginning the next wave.
*******************************************************************************/
void updateEMs() {
  if (currEM == -1) { // Trigger to generate a new wave 
    if (betweenWaves) {
      // Add score for left over ammo and cities
      addEndOfWaveScore(); 
    }
    
    if (!betweenWaves) {
      // Wait a second after counting ammo and cities before next wave
      if (wave > 0 && frameCount <= waveBeginFrame + targetFrameRate / 2f) {
        return;
      }

      // Start a new wave
      newWave();
    }
    return;
  }

  /** if the current EM index is equal to the size of the wave index (less
    *  1 because indexes begin at 0), the wave is complete and no more EMs
    *  should be drawn to the screen
    */
  if (
    activeEMs.isEmpty() &&
    activeESBs.isEmpty() &&
    currEM >= waveEMs.size() &&
    currESB >= waveESBs.size()
  ) {
    waveEndFrame = frameCount;
    betweenWaves = true;
    countingAmmo = true;
    currEM = -1; // Reset counter for current EM
    currESB = -1; // Reset counter for current EM
    weaponCooldown = true; // Disable the ability to fire any weapons
    return;
  }

  /** The activeEMs array holds the EMs currently being drawn to the screen.
   *  When there are no more EMs being drawn to the screen and the wave is in
   *  progress then a random number, between 2 and 4 (remembering that
   *  random() does not choose the second parameter), of EMs are taken from the
   *  waveEMs array and drawn to the screen.
   */
  if (activeEMs.isEmpty()) {
    for (int i = 0; i < (int)random(2, 5); i++) {
      // Only add more acrive EMs if not exceeding wave EMs
      if (currEM < waveEMs.size()) {
        activeEMs.add(waveEMs.get(currEM));
        currEM++;
      }
    }

    // return;
  }
  
  // Add another smart bomb when there are none active and the time passed
  // is a multiple of 5 seconds
  if (frameCount % (targetFrameRate * 6) < 1) {
    if (currESB < waveESBs.size()) {
      waveESBs.get(currESB).setTarget();
      activeESBs.add(waveESBs.get(currESB));
      // play creation sound
      createSmartBomb.play();
      currESB++;
    }
  }
  
  /** To keep track of EMs that need to be removed from active EMs, a new
   *  ArrayList is created and, after checking whether the EM is live, removed
   *  from the active EMs array. Doing it this way avoids problems with removing
   *  indexes from the ArrayList which can cause ArrayIndexOutOfBounds and other
   *  unintentional issues to arise
   */
  ArrayList<EnemyMissile> destroyedEMs = new ArrayList<EnemyMissile>();
  ArrayList<EnemySmartBomb> destroyedESBs = new ArrayList<EnemySmartBomb>();

  // Update, draw and check destruction of all active enemy missiles
  for (EnemyMissile em : activeEMs) {
    if (em.isLive()) {
      em.update();
      em.draw();
    } else {
      // If the EM is not live, add it to the list of destroyed EMs to be
      // removed from active EMs
      destroyedEMs.add(em);
    }
  }

  // Update, draw and check destruction of all active enemy smart bombs
  for (EnemySmartBomb esb : activeESBs) {
    if (esb.isLive()) {
      esb.update();
      esb.draw();
    } else {
      destroyedESBs.add(esb);
    }
  }

  // Remove destroyed enemy missiles and smart bombs from the active arrays
  activeEMs.removeAll(destroyedEMs);
  activeESBs.removeAll(destroyedESBs);
}

/*******************************************************************************
* newWave() Start a new wave of enemy missiles. Resets ammuntion, rebuilds
* destoyed cities, handles the score multiplier, and creates between 12
* and 18 missiles for the next wave. Also updates the wave number message
* displayed at the bottom of the screen.
*******************************************************************************/
void newWave() {
  for (City city : standingCities) {
    city.reset();
  }

  abmsRemaining = 30;
  
  // Wait a second after replensishing ammo and cities before next wave
  if (wave > 0 && frameCount <= waveBeginFrame + targetFrameRate) {
    return;
  }

  wave++;
  
  // Set scoring multiplier (increments each odd wave number, up to 6)
  if (wave % 2 == 1) {
    scoreMultiplier++;
    scoreMultiplier = constrain(scoreMultiplier, 1, 6);
  }

  waveEMs = new ArrayList<EnemyMissile>(); // Create new array of EMs
  
  // Each wave has a random number of EMs, between 12 and 18
  // (remember random() chooses a number up to but excluding second argument)
  for (int i = 0; i < (int)random(12, 19); i++) {
    waveEMs.add(new EnemyMissile());
  }

  if (wave > 5) {
    if (wave % 2 == 0) {
      esbsInWave++;
      esbsInWave = constrain(esbsInWave, 1, 7);
    }
  }

  waveESBs = new ArrayList<EnemySmartBomb>();

  if (esbsInWave > 0) {
    for (int i = 0; i < esbsInWave; i++) {
      waveESBs.add(new EnemySmartBomb());
    }
  }


  // Needed for manual reset
  activeEMs = new ArrayList<EnemyMissile>();
  activeESBs = new ArrayList<EnemySmartBomb>();

  currEM++; // Increment current EM index to move to next if statement
  currESB++;
  missilesIncoming.play();
  
  // replenish special attacks
  specialsRemaining = ceil(esbsInWave * 1.5);

  // Unlock the mouse to be able to fire again
  weaponCooldown = false;

  // Display a message when a new wave is starting
  setMessage("Wave " + wave, 5);
}

/*******************************************************************************
* setMessage() Sets the message to be displayed at bottom of screen
* Parameters:
*    String: the message to be displayed
*    int: the amount of time the message should be displayed in milliseconds
*******************************************************************************/
void setMessage(String text, float duration) {
  // Set the start frame and duration
  messageStartFrame = frameCount;
  messageDuration = (int)(duration * targetFrameRate);
  
  // Set the message
  message = text;

  // Toggle drawing of message on
  showMessage = true;
}

/*******************************************************************************
* displayMessage() Draw the message set by setMessage() to the bottom of 
* the screen                                             
*******************************************************************************/
void displayMessage() {
  // Calculate how long current message has been displayed
  int messageFrames = frameCount - messageStartFrame;

  if (messageFrames % (targetFrameRate * 2) < 1) {
    messageColour = 0;
  } else if (messageFrames % targetFrameRate < 1) {
    messageColour = 1;
  }
  
  // Set the variables (fill, size, alignment)
  // Flash between red and black (not showing)
  
  if (messageColour == 0) {
    if (gameOver) {
      fill(#990000);
    } else {
      fill(255, 0, 0);
    }
  } else if (messageColour == 1) {
    fill(0, 0);
  }

  textSize(height * 24 / 1080f);
  textAlign(CENTER);

  // Draw the text
  text(message, width / 2, height * 0.99);

  // Turn drawing of message off after set duration
  if (frameCount >= messageStartFrame + messageDuration) {
    showMessage = false;
    messageColour = 0;
  }
}

/*******************************************************************************
* titleScreen() - handles the display of the title screen show at the beginning
* of the game. Randomly generates the colours and destruction of the title with
* explosions.
*******************************************************************************/
void titleScreen() {
  background(0);
  noStroke();

  textFont(mainFont);
  textSize(width * 144 / 1920f);
  textLeading(width * 216 / 1920f);
  textAlign(CENTER);
  
  if (!titleMusic.isPlaying()) {
    titleMusic.play();
  }
  
  if (frameCount <= 5 * targetFrameRate) {
    if (frameCount <= 2.5 * targetFrameRate) {
      fill(titleCols[0][0]);
      text("MISSILE\nCOMMAND", width / 2, height / 2);
    } else {
      if (frameCount % 5f < 1) {
        // index of new colours to use
        currColIdx = (int)(random(0, titleCols.length));

        // don't use the same colour twice in a row
        while (currColIdx == prevColIdx) {
          currColIdx = (int)(random(0, titleCols.length));
        }

        // Choose randomly between which colour in the set will be for text
        // and explosions, respectively
        textColIdx = (int)random(0, 2);
        explosionColIdx = 1 - textColIdx;

        prevColIdx = currColIdx;
      }

      /* Title */
      fill(titleCols[currColIdx][textColIdx]); // Text colour
      text("MISSILE\nCOMMAND", width / 2, height / 2);

      /* 'Explosions' */
      // Explosion colour
      color explosionCol = titleCols[currColIdx]
        [explosionColIdx];
      // radius of next eplosion to be added
      float explosionDiameter = random(width * 0.0125, width * 0.0375); 
      PShape explosionToAdd = createShape(
        ELLIPSE, 
        random(width * (330 / 1920f), width * (1572 / 1920f)), 
        random(height * (270 / 1080f), height * (848 / 1080f)), 
        explosionDiameter, 
        explosionDiameter
      );
      titleScreenExplosions =
        (PShape[])append(titleScreenExplosions, explosionToAdd);
      for (int i = 0; i < titleScreenExplosions.length; i++) {
        if (i > titleScreenExplosions.length - 24) {
          titleScreenExplosions[i].setFill(explosionCol);
        } else {
          titleScreenExplosions[i].setFill(color(0));
        }

        shape(titleScreenExplosions[i]);
      }
    }
  } else if (frameCount <= 5.5 * targetFrameRate) {
    // show the last screen for half a second
    return;
  } else if (frameCount >= 6 * targetFrameRate) {
     // blank screen for half a second
    showTitleScreen = false;
    setMessage("Press any mouse or keyboard button to start", 120);
  }
}

/*******************************************************************************
* drawBackground() - Draws the background to the screen, which includes the 
* ground the cities and central tower are built on, and the stars.
*******************************************************************************/
void drawBackground() {
  background(0);
  shapeMode(CORNER);
  if (gameOver) {
    bgShape.setFill(127);
  } else {
    bgShape.setFill(color(255, 0, 0));
  }
  shape(bgShape, 0, 0);
  drawStars();
}

/*******************************************************************************
* drawStars() - Draws the stars in memory to the screen and 
* updates their position every half a second (approx.).
*******************************************************************************/
void drawStars() {
  for (Star star : stars) {
    star.setGrayscale(gameOver);
    star.display();
    if (frameCount % (targetFrameRate / 2f) < 1) {
      star.update();
    }
  }
}

/*******************************************************************************
* drawZiggurat() - Draws the ziggurat (pyramidal tower ABMs are fired from) 
* to the screen
*******************************************************************************/
void drawZiggurat() {
  // adjust y value so that ziggurat is drawn with base @ y param
  float x = width / 2;
  float y = height * 0.85;
  y -= height * 0.01;
  float zigWidth = width * 0.165;
  rectMode(CENTER);
  noStroke();
  if (gameOver) {
    fill(127);
  } else {
    fill(255, 0, 0);
  }
  rect(x, y, zigWidth, height * 0.02); 
  y -= height * 0.02;
  rect(x, y, zigWidth * 2 / 3, height * 0.02);
  y -= height * 0.02;
  rect(x, y, zigWidth * 1 / 3, height * 0.02);
  rectMode(CORNER);
}

/*******************************************************************************
* drawTurret() - draw the central turret to the screen. Works out the angle at
* which the turret needs to be rotated so that it points toward the reticle.
*******************************************************************************/
void drawTurret() {
  rectMode(CENTER);
  fill(100, 100, 100);
  
  // calculate angle and draw turret arm
  float deltaX = mouseX - (width * 0.5);
  //float deltaY = abs(constrain(mouseY, 0, height * 0.775) - (height * 0.775));
  float deltaY = constrain(
    mouseY - (height * 0.76),
    (height * 0.76) * -1, -(height*0.03)
  );
  float theta = atan(deltaX/deltaY);
  turretArm.rotate(-theta);
  shape(turretArm, width*0.501, height*0.77);
  // return rotation to 0, otherwise rotation accrues
  /* Alternatively, you can use turretArm().resetMatrix() but same result */
  turretArm.rotate(theta); 
  // draws the turret housing
  fill(175, 175, 175);
  ellipse(
          width * 0.5, 
          height * 0.772, 
          turretRadius * 2, 
          turretRadius * 2
  );
  rect(
       width * 0.5, 
       height * 0.772 + turretRadius / 2, 
       turretRadius * 2, 
       height * 0.018
  );
  // Draws the windows
  stroke(80);
  strokeWeight(0.5);
  fill(#FFD900);
  rect(width * 0.5 - width * 0.002, 
       height * 0.773 + turretRadius / 2, 
       turretRadius / 4, 
       turretRadius / 4
  );
  rect(width * 0.5 + width * 0.002, 
       height * 0.773, 
       turretRadius / 4, 
       turretRadius / 4
  );
  noStroke(); 
}

/*******************************************************************************
* drawAmmo() - Draws ammo to the screen. The blocks on the bottom left represent
* 10 abms, with another 9 being displayed below the turret and one inside the
* turret ready to be fired. 
*******************************************************************************/
void drawAmmo() {
  // draw Specials
  for (int i = 0; i < specialsRemaining; i++) {
    shape(
      specialAttackShape,
      width * (1880 / 1920f) - (i * width * 0.015),
      height * 948 / 1080f
    );
  }
  
  if (abmsRemaining == 0) { 
    return;
  }

  abmBatteries = floor((abmsRemaining - 1) / 10);
  abmsLoaded = abmsRemaining % 10;
  if (abmsLoaded == 0) {
    abmsLoaded = 10 ;
  }

  // draw Ammo Blocks
  fill(100, 100, 100);
  for (int i = 0; i < abmBatteries; i++) {
    rect(
      width * 0.025 + (i * (width * 0.034)), 
      height * 940 / 1080f, 
      width * 0.03, 
      height * 16 / 1080f
    );
  }
    
  // Draw loaded ABMs
  float startY = height * 935 / 1080f;
  float startX = width / 2;
  float xOffset = width * 10 / 1920f;
  float yOffset = height * 10 / 1080f;
  
  shapeMode(CENTER);
  missileShape.setFill(143);

  for (int i = 0; i < abmsLoaded; i++) {
    switch (i) {
      case 0:
        shape(
          missileShape,
          startX,
          startY
        );
        break;
      case 1:
        shape(
          missileShape,
          startX - xOffset,
          startY + yOffset 
        );
        break;
      case 2:
        shape(
          missileShape,
          startX + xOffset,
          startY + yOffset 
        );
        break;
      case 3:
        shape(
          missileShape,
          startX - xOffset * 2,
          startY + yOffset * 2
        );
        break;
      case 4:
        shape(
          missileShape,
          startX,
          startY + yOffset * 2
        );
        break;
      case 5:
        shape(
          missileShape,
          startX + xOffset * 2,
          startY + yOffset * 2
        );
        break;
      case 6:
        shape(
          missileShape,
          startX - xOffset * 3,
          startY + yOffset * 3
        );
        break;
      case 7:
        shape(
          missileShape,
          startX - xOffset,
          startY + yOffset * 3
        );
        break;
      case 8:
        shape(
          missileShape,
          startX + xOffset,
          startY + yOffset * 3
        );
        break;
      case 9:
        shape(
          missileShape,
          startX + xOffset * 3,
          startY + yOffset * 3
        );
        break;
    }
  }
}

/*******************************************************************************
* drawCities() - Draws the cities in memory to the screen. The city object
* encapsulates information about whether the city is still standing, and which 
* shape to draw.
*******************************************************************************/
void drawCities() {
  for (City city : cities) {
    city.draw();
  }
}

/*******************************************************************************
* drawScore() - Draws the score to the top-center of the screen         
*******************************************************************************/
void drawScore() {
  // Font setup
  textFont(mainFont);
  textSize(width * 48 / 1920f);
  textAlign(CENTER);
  fill(#AE661A);

  // Draw the text
  text(score, width / 2, height * 60 / 1080f);
}

/*******************************************************************************
* drawReticle() - Draws the reticle in place of mouse cursor
*******************************************************************************/
void drawReticle() {
  stroke(255, 191);

  // thick lines
  strokeWeight(3);
  line(mouseX, mouseY - 8, mouseX, mouseY - 6); // top thick
  line(mouseX + 6, mouseY, mouseX + 8, mouseY); // right thick
  line(mouseX, mouseY + 6, mouseX, mouseY + 8); // bottom thick
  line(mouseX - 8, mouseY, mouseX - 6, mouseY); // left thick

  // thin lines
  strokeWeight(1);
  line(mouseX, mouseY - 6, mouseX, mouseY - 3); // top thin
  line(mouseX + 3, mouseY, mouseX + 6, mouseY); // right thin
  line(mouseX, mouseY + 3, mouseX, mouseY + 6); // bottom thin
  line(mouseX - 6, mouseY, mouseX - 3, mouseY); // left thin
  
  noStroke();
}

/*******************************************************************************
* collisionDetection() Check for collisions between objects and handles the
* behaviour as a result. 
*******************************************************************************/
void collisionDetection() {
  // Check ABM-enemy missile collisions
  for (AntiballisticMissile abm : abms) {
    for (EnemyMissile em : waveEMs) {
      if (abm.detectCollision(em.getPosition())) {
        if (em.isLive()) { // Needed to ensure only occurs once
          em.destroy();
          destroyMissile.play();
          score += 25 * scoreMultiplier;
        }
      }
    }
  }
  
 // Check for EnemySmartBomb-ABM collisions
  // (possibly possible if you shoot just right)
  for (AntiballisticMissile abm : abms) {
    for (EnemySmartBomb esb : waveESBs) {
      if (abm.detectCollision(esb.getPosition())) {
        if (esb.isLive()) { // Needed to ensure only occurs once
          esb.destroy();
          destroyMissile.play();
          score += 60 * scoreMultiplier;
        }
      }
    }
  }
  
  // Check for EnemySmartBomb-AntiSmartBombAttack collisions. 
  
  // Check enemy missile-city and smartbomb-city collisions
  for (City city : cities) {
    for (EnemyMissile em : waveEMs) {
      if (city.detectCollision(em.getPosition())) {
        em.destroy(); // The missile is destroyed along with the city
        standingCities.remove(city); // The city is removed from standing cities
      }
    }

    for (EnemySmartBomb esb : waveESBs) {
      if (city.detectCollision(esb.getPosition())) {
        esb.destroy();
        standingCities.remove(city);
      }
    }
  }

  if (standingCities.isEmpty()) {
    gameOverFrame = frameCount;
    setMessage("Press any mouse or keyboard button to restart", 120);
    gameOver();
  }
}

/*******************************************************************************
* screenFlash() - Flash the screen for more emphasis when a city is destroyed
* works by displaying transparent rectangles over the screen while the city
* is exploding.
*******************************************************************************/
void screenFlash() {
  noStroke();

  if ((frameCount - cityHitFrame) % (targetFrameRate / 30f) == 0) {
    screenFlashColour[1] = (int)random(0, 191);
    if (screenFlashColour[1] == 255) {
      screenFlashColour[2] = 255;
    }
    screenFlashColour[3] = (int)random(111, 144);
  }
  
  fill(
    screenFlashColour[0],
    screenFlashColour[1],
    screenFlashColour[2],
    screenFlashColour[3]
  );
  
  rectMode(CORNER);
  
  rect(0, 0, width, height);
  
  if (frameCount - cityHitFrame >= targetFrameRate) {
    cityHit = false;
  }
}

/*******************************************************************************
* updateABMs() - Updates the state of antiballistic missile objects and
* (optionally) array. If the ABM has finished exploding, it is removed from
* the global array abms. 
*******************************************************************************/
void updateABMs() {
  ArrayList<AntiballisticMissile> expendedABMs =
    new ArrayList<AntiballisticMissile>();
  
  for (AntiballisticMissile abm : abms) {
    if (!abm.isExpended()) {
      abm.update();
      abm.draw();
    } else {
      expendedABMs.add(abm);
    }
  }

  abms.removeAll(expendedABMs);
}

/*******************************************************************************  
* countRemainingAmmo - counts the ammunition and cities remaining at the end of 
* a wave. Updates the score and handles the updates in a timed way which creates
* a animated effect.
*******************************************************************************/
void addEndOfWaveScore() {
  // Wait a couple of seconds before starting the counting
  if (frameCount <= waveEndFrame + 2 * targetFrameRate) {
    return;
  }

  if (countingAmmo) {
    if (abmsRemaining > 0 && frameCount % (targetFrameRate / 6f) == 0) {
      abmsRemaining -=1;
      score += 5 * scoreMultiplier; 
      countAmmo.play();
      return;
    } else if (abmsRemaining == 0) {
      countingAmmo = false;
      countingCities = true;
      return;
    }
  }

  if (countingCities) {
    if (
      cityIdx < standingCities.size()
      && frameCount % (targetFrameRate / 3f) == 0
    ) {
      standingCities.get(cityIdx).count();
      countAmmo.play();
      score += 100 * scoreMultiplier;
      cityIdx++;
      return;
    } else if (cityIdx == standingCities.size()) {
      countingCities = false;
      cityIdx = 0;
    }
  }

  if (!countingAmmo && !countingCities) {
    waveBeginFrame = frameCount;
    betweenWaves = false;
  }
}

/*******************************************************************************  
* gameOver() - displays the game over screen.                                                                 *
*******************************************************************************/
void gameOver() {
  // Set gameOver boolean variable to true
  gameOver = true;
  started = false;
  
  // Stop playing BG music
  levelMusic.stop();

  drawBackground();
  drawZiggurat();
  drawCities();

  textAlign(CENTER);
  textSize(width * 112 / 1920f);
  fill(#990000);

  text("GAME OVER!", width / 2f, height / 3f);

  textSize(width * 54 / 1920f);
  text("All cities were destroyed", width / 2f, height / 2f);
  text("Your final score was " + score, width / 2f, height * 2 / 3f);

  if (showMessage) {
    displayMessage();
  }

  int gameOverSoundDuration = (int)(gameOverSound.duration() * targetFrameRate);

  // Play game over music
  if (!gameOverSound.isPlaying() && (int)frameCount < gameOverSoundDuration) {
    gameOverSound.play();
  }
}

/*******************************************************************************
* mousePressed() - Mouse event handlers. Left click fires ABM, right click 
* fire sthe special attack. Ensures that only 3 ABMs can be
* exploding at the same time, and that nothing can be fired during a special
* attack.                                                                     
*******************************************************************************/
void mousePressed() {
  if (showTitleScreen) {
    setMessage("Press any mouse or keyboard button to start", 120);
    showTitleScreen = false;
    return;
  }

  if (!showTitleScreen && !started && !gameOver) {
    started = true;
    startFrame = frameCount;
    showMessage = false;
    return;
  }

  if (gameOver) {
    gameOver = false;
    startGame();
    if (!titleMusic.isPlaying()) {
      titleMusic.play();
    }
    setMessage("Press any mouse or keyboard button to start", 120);
    return;
  }

  if (!weaponCooldown && !specialAttackInProgress) {
    if (mouseY < height * 0.8 && mouseButton == LEFT) { // ensure click is above ziggurat
      // Add new ABM to ArrayList with mouse coordinates
      abms.add(new AntiballisticMissile(new PVector(mouseX, mouseY)));

      // Decrease ammo by 1
      abmsRemaining--;

      // Disable ability to fire more ABMs if 3 already active or none left
      if (abms.size() >= 3 || abmsRemaining <= 0) {
        weaponCooldown = true;
      }
    }
  }

  if (!weaponCooldown && mouseButton == RIGHT && !specialAttackInProgress
      && specialsRemaining > 0) {
    specialAttackInProgress = true;
    specialAttack = new SpecialAttack(new PVector(mouseX, mouseY));
    specialsRemaining--;
  }
}

/*******************************************************************************
* keyPressed() - Keyboard event handlers. There is minimal keyboard input, 
* but the game does react to any key being pressed. 
*******************************************************************************/
void keyPressed() {
  if (showTitleScreen) {
    setMessage("Press any mouse or keyboard button to start", 120);
    showTitleScreen = false;
    return;
  }

  if (!showTitleScreen && !started && !gameOver) {
    started = true;
    startFrame = frameCount;
    showMessage = false;
    return;
  }

  if (gameOver) {
    gameOver = false;
    startGame();
    if (!titleMusic.isPlaying()) {
      titleMusic.play();
    }
    setMessage("Press any mouse or keyboard button to start", 120);
    return;
  }
}
