#import "GameScene.h"
#import "UFO.h"

// Acceleration constant multiplier
#define ACCELERATION_MULTIPLIER 1500.0

#pragma mark - GameScene

@implementation GameScene
{
    // Declaring a private CMMotionManager instance variable
    CMMotionManager *_accManager;
    
    // Declare accelerometer data variable
    CMAccelerometerData *_accData;
    
    // Declare acceleration variable
    CMAcceleration _acceleration;

    // Declare the initial acceleration variable
    CMAcceleration _initialAcceleration;
    
    // Declaring a private CCSprite instance variable
    CCSprite *_scientist;
    
    // Declare global variable for screen size
    CGSize _screenSize;
    
    // Declare a private CCParticleSystem instance variable
    CCParticleSystem *_fire;
    
    // Declare an array of UFOs
    NSMutableArray *_arrayUFOs;
    
    // Max number of UFOs in scene
    int _numUFOs;

    // Declare array of green lasers
    NSMutableArray *_arrayLaserGreen;
    
    // Max number of lasers in scene
    int _numLaserGreen;

    // Array of removable laser beams
    NSMutableArray *_lasersGreenToRemove;
    
    // Array of removable UFOs
    NSMutableArray *_ufosToRemove;

    // Declare array of red lasers
    NSMutableArray *_arrayLaserRed;
    
    // Max number of lasers in scene
    int _numLaserRed;
    
    // Array of removable laser beams
    NSMutableArray *_lasersRedToRemove;
    
    // Declare number of lives
    int _numLives;
    
    // Array of life rectangles
    NSMutableArray *_arrayLives;
}

#pragma mark - Create scene

+ (GameScene *)scene
{
	return [[self alloc] init];
}

#pragma mark - Initalizing and configuring the game

- (id)init
{
    // Apple recommend assigning self with supers return value
    self = [super init];
    if (!self) return(nil);
    
    // Initialize motion manager
    _accManager = [[CMMotionManager alloc] init];
    
    // Initialize the scientist
    _scientist = [CCSprite spriteWithImageNamed:@"scientist.png"];
    
    _screenSize = [CCDirector sharedDirector].viewSize;
    
    _scientist.position = CGPointMake(_screenSize.width/2, _scientist.contentSize.height);
    [self addChild:_scientist z:1];
    
    // Configure parallax effect
    [self configureParallaxEffect];
    
    // Init the fire particle
    _fire = [CCParticleFire node];
    
    // Place the fire at the middle of the scientist's back
    _fire.position = CGPointMake(_scientist.position.x, _scientist.position.y);
    
    // Add the particle system to the scene
    [self addChild:_fire z:1];
    
    // Configure the particle system
    _fire.totalParticles = 200;
    _fire.life = 3.3;
    _fire.lifeVar = 0.5;
    _fire.emissionRate = _fire.totalParticles/_fire.life;
    _fire.startSize = 50.0;
    _fire.startSizeVar = 1.0;
    _fire.endSize = 10.0;
    _fire.endSizeVar = 2.0;
    _fire.angle = 270.0;
    _fire.duration = CCParticleSystemDurationInfinity;
    _fire.sourcePosition = CGPointMake(0, -10);
    _fire.speed = 50.0;
    _fire.speedVar = 1.0;
    _fire.posVar = CGPointMake(10, 0);
    
    // Initialize the array of UFOs
    _numUFOs = 3;
    _arrayUFOs = [NSMutableArray arrayWithCapacity:_numUFOs];
    
    // Schedule the UFOs spawn method
    [self schedule:@selector(spawnUFO) interval:5.0f];
    
    // Initialize the array of green lasers
    _numLaserGreen = 5;
    _arrayLaserGreen = [NSMutableArray arrayWithCapacity:_numLaserGreen];
    
    self.userInteractionEnabled = YES;
    
    // Initialize removable objects arrays
    _lasersGreenToRemove = [NSMutableArray array];
    _ufosToRemove = [NSMutableArray array];
    _lasersRedToRemove = [NSMutableArray array];
    
    // Initialize max number of red lasers
    _numLaserRed = 15;
    
    // Initialize the array of red lasers
    _arrayLaserRed = [NSMutableArray arrayWithCapacity:_numLaserRed];
    
    // Shoot red lasers
    [self schedule:@selector(shootRedLaser:) interval:2.0f];
    
    // Initialize number of lifes and array
    _numLives = 10;
    _arrayLives = [NSMutableArray arrayWithCapacity:_numLaserRed];
    
    // Draw life bar
    [self initLifeBar];
    
    return self;
}

#pragma mark - Starting and stopping accelerometer manager

// Start receiving accelerometer events
- (void)onEnter {
    [super onEnter];
    [_accManager startAccelerometerUpdates];
}

// Stop receiving accelerometer events
- (void)onExit {
    [super onExit];
    [_accManager stopAccelerometerUpdates];
}

#pragma mark - Scheduled update method

-(void) update:(CCTime)delta{
    
    // Getting accelerometer data
    _accData = _accManager.accelerometerData;
    
    // Getting acceleration
    _acceleration = _accData.acceleration;
    
    // As soon as we get acceleration store it as the initial acceleration to compensate
    if (_initialAcceleration.x == 0 && _initialAcceleration.y == 0 && _acceleration.x != 0 && _acceleration.y != 0) {
        _initialAcceleration = _acceleration;
    }
    
    // Calculating next position on 'x' axis
    CGFloat nextXPosition = _scientist.position.x + (_acceleration.x - _initialAcceleration.x) * ACCELERATION_MULTIPLIER * delta;
    
    // Calculating next position on 'y' axis
    CGFloat nextYPosition = _scientist.position.y + (_acceleration.y - _initialAcceleration.y) * ACCELERATION_MULTIPLIER * delta;
    
    // Avoiding positions out of bounds
    nextXPosition = clampf(nextXPosition, _scientist.contentSize.width / 2, self.contentSize.width - _scientist.contentSize.width / 2);
    nextYPosition = clampf(nextYPosition, _scientist.contentSize.height / 2, self.contentSize.height - _scientist.contentSize.height / 2);
    
    _scientist.position = CGPointMake(nextXPosition, nextYPosition);
    
    // Make the fire follow the scientist
    _fire.position = CGPointMake(_scientist.position.x, _scientist.position.y);
    
    // Collision detection
    [self detectCollisions];

}

#pragma mark - Configuring parallax effect

-(void) configureParallaxEffect{
    
    // Create the layers that will take part in the parallax effect
    CCSprite *parallaxBackground1 = [CCSprite spriteWithImageNamed:@"background1.png"];
    CCSprite *parallaxBackground2 = [CCSprite spriteWithImageNamed:@"background2.png"];
    CCSprite *parallaxBackground3 = [CCSprite spriteWithImageNamed:@"background3.png"];
    CCSprite *parallaxBackground4 = [CCSprite spriteWithImageNamed:@"background4.png"];
    CCSprite *parallaxBackground5 = [CCSprite spriteWithImageNamed:@"background1.png"];
    
    CCSprite *parallaxClouds1 = [CCSprite spriteWithImageNamed:@"clouds1.png"];
    CCSprite *parallaxClouds2 = [CCSprite spriteWithImageNamed:@"clouds2.png"];
    CCSprite *parallaxClouds3 = [CCSprite spriteWithImageNamed:@"clouds1.png"];
    CCSprite *parallaxClouds4 = [CCSprite spriteWithImageNamed:@"clouds2.png"];
    
    CCSprite *parallaxLowerClouds1 = [CCSprite spriteWithImageNamed:@"clouds2.png"];
    CCSprite *parallaxLowerClouds2 = [CCSprite spriteWithImageNamed:@"clouds1.png"];
    CCSprite *parallaxLowerClouds3 = [CCSprite spriteWithImageNamed:@"clouds2.png"];
    CCSprite *parallaxLowerClouds4 = [CCSprite spriteWithImageNamed:@"clouds1.png"];
    
    // Modify the sprites anchor point
    parallaxBackground1.anchorPoint = CGPointMake(0, 0);
    parallaxBackground2.anchorPoint = CGPointMake(0, 0);
    parallaxBackground3.anchorPoint = CGPointMake(0, 0);
    parallaxBackground4.anchorPoint = CGPointMake(0, 0);
    parallaxBackground5.anchorPoint = CGPointMake(0, 0);
    
    parallaxClouds1.anchorPoint = CGPointMake(0, 0);
    parallaxClouds2.anchorPoint = CGPointMake(0, 0);
    parallaxClouds3.anchorPoint = CGPointMake(0, 0);
    parallaxClouds4.anchorPoint = CGPointMake(0, 0);
    
    parallaxLowerClouds1.anchorPoint = CGPointMake(0, 0);
    parallaxLowerClouds2.anchorPoint = CGPointMake(0, 0);
    parallaxLowerClouds3.anchorPoint = CGPointMake(0, 0);
    parallaxLowerClouds4.anchorPoint = CGPointMake(0, 0);
    
    // Modify opacity
    parallaxLowerClouds1.opacity = 0.3;
    parallaxLowerClouds2.opacity = 0.3;
    parallaxLowerClouds3.opacity = 0.3;
    parallaxLowerClouds4.opacity = 0.3;
    
    parallaxClouds1.opacity = 0.8;
    parallaxClouds2.opacity = 0.8;
    parallaxClouds3.opacity = 0.8;
    parallaxClouds4.opacity = 0.8;
    
    // Define start positions
    CGPoint backgroundOffset1 = CGPointZero;
    CGPoint backgroundOffset2 = CGPointMake(0, parallaxBackground1.contentSize.height);
    CGPoint backgroundOffset3 = CGPointMake(0, parallaxBackground1.contentSize.height + parallaxBackground2.contentSize.height);
    CGPoint backgroundOffset4 = CGPointMake(0, parallaxBackground1.contentSize.height + parallaxBackground2.contentSize.height + parallaxBackground3.contentSize.height);
    CGPoint backgroundOffset5 = CGPointMake(0, parallaxBackground1.contentSize.height + parallaxBackground2.contentSize.height + parallaxBackground3.contentSize.height + parallaxBackground4.contentSize.height);
    
    CGPoint lowerClouds1Offset = CGPointMake(0, _screenSize.height);
    CGPoint lowerClouds2Offset = CGPointMake(0, _screenSize.height + 3 * parallaxBackground1.contentSize.height);
    CGPoint lowerClouds3Offset = CGPointMake(0, _screenSize.height + 6 * parallaxBackground1.contentSize.height);
    CGPoint lowerClouds4Offset = CGPointMake(0, _screenSize.height + 9 * parallaxBackground1.contentSize.height);
    
    CGPoint clouds1Offset = CGPointMake(0, _screenSize.height);
    CGPoint clouds2Offset = CGPointMake(0, _screenSize.height + 3 * parallaxBackground1.contentSize.height);
    CGPoint clouds3Offset = CGPointMake(0, _screenSize.height + 6 * parallaxBackground1.contentSize.height);
    CGPoint clouds4Offset = CGPointMake(0, _screenSize.height + 9 * parallaxBackground1.contentSize.height);
    
    // Initialize parallax node
    CCParallaxNode *parallaxNode = [CCParallaxNode node];
    
    // Add parallax children defining z-order, ratio and offset
    [parallaxNode addChild:parallaxBackground1 z:0 parallaxRatio:CGPointMake(0, 1) positionOffset:backgroundOffset1];
    [parallaxNode addChild:parallaxBackground2 z:0 parallaxRatio:CGPointMake(0, 1) positionOffset:backgroundOffset2];
    [parallaxNode addChild:parallaxBackground3 z:0 parallaxRatio:CGPointMake(0, 1) positionOffset:backgroundOffset3];
    [parallaxNode addChild:parallaxBackground4 z:0 parallaxRatio:CGPointMake(0, 1) positionOffset:backgroundOffset4];
    [parallaxNode addChild:parallaxBackground5 z:0 parallaxRatio:CGPointMake(0, 1) positionOffset:backgroundOffset5];
    
    [parallaxNode addChild:parallaxLowerClouds1 z:1 parallaxRatio:CGPointMake(0, 2) positionOffset:lowerClouds1Offset];
    [parallaxNode addChild:parallaxLowerClouds2 z:1 parallaxRatio:CGPointMake(0, 2) positionOffset:lowerClouds2Offset];
    [parallaxNode addChild:parallaxLowerClouds3 z:1 parallaxRatio:CGPointMake(0, 2) positionOffset:lowerClouds3Offset];
    [parallaxNode addChild:parallaxLowerClouds4 z:1 parallaxRatio:CGPointMake(0, 2) positionOffset:lowerClouds4Offset];
    
    [parallaxNode addChild:parallaxClouds1 z:2 parallaxRatio:CGPointMake(0, 3) positionOffset:clouds1Offset];
    [parallaxNode addChild:parallaxClouds2 z:2 parallaxRatio:CGPointMake(0, 3) positionOffset:clouds2Offset];
    [parallaxNode addChild:parallaxClouds3 z:2 parallaxRatio:CGPointMake(0, 3) positionOffset:clouds3Offset];
    [parallaxNode addChild:parallaxClouds4 z:2 parallaxRatio:CGPointMake(0, 3) positionOffset:clouds4Offset];
    
    [self addChild:parallaxNode];
    
    // Create a move action
    CCActionMoveBy *move1 = [CCActionMoveBy actionWithDuration:24 position:CGPointMake(0, -(parallaxBackground1.contentSize.height + parallaxBackground2.contentSize.height + parallaxBackground3.contentSize.height + parallaxBackground4.contentSize.height))];
    
    CCActionMoveBy *move2 = [CCActionMoveBy actionWithDuration:0 position:CGPointMake(0, parallaxBackground1.contentSize.height + parallaxBackground2.contentSize.height + parallaxBackground3.contentSize.height + parallaxBackground4.contentSize.height)];
    
    // Create a sequence with both movements
    CCActionSequence *sequence = [CCActionSequence actionWithArray:@[move1, move2]];
    
    // Create an infinite loop for the movement action
    CCActionRepeatForever *loop = [CCActionRepeatForever actionWithAction:sequence];
    
    // Run the action
    [parallaxNode runAction:loop];
}

#pragma mark - Spawn UFOs

-(void)spawnUFO {
    
    if ([_arrayUFOs count] < _numUFOs){
        // Create a new UFO
        int type = arc4random_uniform(3);
        UFO *ufo = [[UFO alloc] initWithType:type];
        
        // Set inital UFO position
        ufo.position = CGPointMake(ufo.contentSize.width / 2, _screenSize.height + ufo.contentSize.height / 2);
        
        // Adding the new UFO to the array
        [_arrayUFOs addObject:ufo];
        
        // Adding the UFO to the scene
        [self addChild:ufo];
        
        //Creating movement actions
        CCActionMoveTo *actionMoveInitialPosition = [CCActionMoveTo actionWithDuration:0.6 position:CGPointMake(ufo.position.x, _screenSize.height - ufo.contentSize.height / 2)];
        
        CCActionMoveTo *actionMoveRight1 = [CCActionMoveTo actionWithDuration:0.3 position:CGPointMake(_screenSize.width - ufo.contentSize.width / 2, _screenSize.height - ufo.contentSize.height / 2)];
        
        CCActionMoveTo *actionMoveDownLeft = [CCActionMoveTo actionWithDuration:0.3 position:CGPointMake(ufo.contentSize.width / 2, _screenSize.height - 2 * ufo.contentSize.height)];
        
        CCActionMoveTo *actionMoveRight2 = [CCActionMoveTo actionWithDuration:0.6 position:CGPointMake(_screenSize.width - ufo.contentSize.width / 2, _screenSize.height - 2 * ufo.contentSize.height)];
        
        CCActionSequence *ufoSequence = [CCActionSequence actionWithArray:@[actionMoveInitialPosition, actionMoveRight1, actionMoveDownLeft, actionMoveRight2]];
        
        // Repeat movemevent infinitely
        CCActionRepeatForever *ufoLoop = [CCActionRepeatForever actionWithAction:ufoSequence];
        
        // Run the UFO movement
        [ufo runAction:ufoLoop];
    }
}

#pragma mark - Handling touches

-(void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    
    if ([_arrayLaserGreen count] < _numLaserGreen){
        // Create green laser and setting its position
        CCSprite *laserGreen = [CCSprite spriteWithImageNamed:@"laser_green.png"];
        laserGreen.position = CGPointMake(_scientist.position.x + _scientist.contentSize.width / 4, _scientist.position.y + _scientist.contentSize.height / 2);
        
        // Add laser to array of lasers
        [_arrayLaserGreen addObject:laserGreen];
        
        // Add the laser to the scene
        [self addChild:laserGreen];
        
        // Declare laser speed
        float laserSpeed = 400.0;
        
        // Calculate laser's final position
        CGPoint nextPosition = CGPointMake(laserGreen.position.x, _screenSize.height + laserGreen.contentSize.height / 2);
        
        // Calculate duration
        float laserDuration = ccpDistance(nextPosition, laserGreen.position) / laserSpeed;
        
        // Move laser sprite out of the screen
        CCActionMoveTo *actionLaserGreen = [CCActionMoveTo actionWithDuration:laserDuration position:nextPosition];
        
        // Action to be executed when the laser reaches its final position
        CCActionCallBlock *callDidMove = [CCActionCallBlock actionWithBlock:^{
            
            // Remove laser from array and scene
            [_arrayLaserGreen removeObject:laserGreen];
            [self removeChild:laserGreen];
            
        }];
        
        CCActionSequence *sequenceLaserGreen = [CCActionSequence actionWithArray:@[actionLaserGreen, callDidMove]];
        
        [laserGreen runAction:sequenceLaserGreen];
    }
}

#pragma mark - Detecting and managing collisions

-(void)detectCollisions {
    
    CCSprite *laserGreen;
    
    // For each UFO on the scene
    for(UFO *ufo in _arrayUFOs) {
        
        // For each laser beam shot
        for (laserGreen in _arrayLaserGreen){
            
            // Detect laserGreen-ufo collision
            if (CGRectIntersectsRect(ufo.boundingBox, laserGreen.boundingBox)) {
                
                // Stopping laser beam actions
                [laserGreen stopAllActions];
                
                // Adding the object to the removable objects array
                [_lasersGreenToRemove addObject:laserGreen];
                
                // Remove the laser from the scene
                [self removeChild:laserGreen];
                
                // Decrease UFO's number of hits
                ufo.numHits--;
                
                // Check if numHits is 0
                if ([ufo checkNumHits]) {
                    // Stopping ufo actions
                    [ufo stopAllActions];
                    
                    // Adding the object to the removable objects array
                    [_ufosToRemove addObject:ufo];
                }
            }
        }
        // Remove objects from array
        [_arrayLaserGreen removeObjectsInArray:_lasersGreenToRemove];
    }
    // Remove objects from array
    [_arrayUFOs removeObjectsInArray:_ufosToRemove];
    
    CCSprite *laserRed;
    
    // For each red laser beam shot
    for (laserRed in _arrayLaserRed){
        
        // Detect laserRed-scientist collision
        if (CGRectIntersectsRect(_scientist.boundingBox, laserRed.boundingBox)) {
            
            // Stopping laser beam actions
            [laserRed stopAllActions];
            
            // Adding the object to the removable objects array
            [_lasersRedToRemove addObject:laserRed];
            
            // Remove the laser from the scene
            [self removeChild:laserRed];
            
            // If there are lives left
            if (_numLives > 0) {
                
                // Remove upper life rectangle
                [self removeChild:[_arrayLives objectAtIndex:_numLives-1]];
                
                // Remove rectangle from array
                [_arrayLives removeObjectAtIndex:_numLives-1];
                
                // Decrease number of lives
                _numLives--;
            }

        }
    }
    // Remove objects from array
    [_arrayLaserRed removeObjectsInArray:_lasersRedToRemove];

}


#pragma mark - Shoot red laser beams

-(void)shootRedLaser:(CCTime) delta {
    
    CCSprite *laserRed;
    
    // Shoot lasers if there are UFOs in scene and isn't reached the max number of red lasers
    if ([_arrayUFOs count] > 0 && [_arrayLaserRed count] < _numLaserRed){
        
        // For each UFO on the scene
        for(UFO *ufo in _arrayUFOs) {
            
            // Create red laser sprite
            laserRed = [CCSprite spriteWithImageNamed:@"laser_red.png"];
            
            // Set red laser position
            laserRed.position = CGPointMake(ufo.position.x, ufo.position.y - ufo.contentSize.height / 2);
            
            // Add laser to array of lasers
            [_arrayLaserRed addObject:laserRed];
            
            // Add laser to scene
            [self addChild:laserRed];
            
            // Declare laser speed
            float laserSpeed = 600.0;
            
            // Calculate laser's final position
            CGPoint nextPosition = CGPointMake(laserRed.position.x, -laserRed.contentSize.height / 2);
            
            // Calculate duration
            float laserDuration = ccpDistance(nextPosition, laserRed.position) / laserSpeed;
            
            // Move red laser sprite out of the screen
            CCActionMoveTo *actionLaserRed = [CCActionMoveTo actionWithDuration:laserDuration position:nextPosition];
            
            // Action to be executed when the red laser reaches its final position
            CCActionCallBlock *callDidMove = [CCActionCallBlock actionWithBlock:^{
                
                // Remove laser from array and scene
                [_arrayLaserRed removeObject:laserRed];
                [self removeChild:laserRed];
                
            }];
            
            CCActionSequence *sequenceLaserRed = [CCActionSequence actionWithArray:@[actionLaserRed, callDidMove]];
            
            // Run action sequence
            [laserRed runAction:sequenceLaserRed];
        }
    }
}

#pragma mark - Drawing life bar

-(void)initLifeBar {
    
    //Initializing position and size values
    float positionX = 10.0;
    float positionY = 40.0;
    float rectHeight = 10.0;
    float rectWidth = 0.0;
    
    // Creating array of vertices
    CGPoint vertices[4];
    
    // Declaring draw node
    CCDrawNode *rectNode;
    
    for(int i = 0; i < _numLives; i++) {
        // Update position and width
        positionY += 15.0;
        rectWidth += 5.0;
        
        // Set values for next rectangle
        vertices[0] = CGPointMake(positionX, positionY); //bottom-left
        vertices[1] = CGPointMake(positionX, positionY + rectHeight); //top-left
        vertices[2] = CGPointMake(positionX + rectWidth, positionY + rectHeight); //top-right
        vertices[3] = CGPointMake(positionX + rectWidth, positionY); //bottom-right
        
        // Draw a polygon by specifying its vertices
        rectNode = [CCDrawNode node];
        rectNode.anchorPoint = CGPointMake(0.0, 0.0);
        [rectNode drawPolyWithVerts:vertices count:4 fillColor:[CCColor greenColor] borderWidth:1.0 borderColor:[CCColor blackColor]];
        
        // Add rectangle to scene
        [self addChild:rectNode];
        
        // Add rectangle to array
        [_arrayLives addObject:rectNode];
        
    }
}


@end
