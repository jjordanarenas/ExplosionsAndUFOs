#import "UFO.h"

@implementation UFO

#pragma mark - Initialize UFO with number of hits

-(id) initWithHits:(int)hits{
    
    // Initialize UFO sprite specifying an image
    self = [super initWithImageNamed:@"ufo_green.png"];
    
    if (!self) return(nil);
    
    // Initialize number of hits
    _numHits = hits;
    
    return self;
}

#pragma mark - Initialize UFO with type

-(id) initWithType:(UFOTypes)type {
    // Set the ufo type
    _ufoType = type;
    
    NSString *textureName;
    int numHits;
    
    switch (_ufoType) {
        case typeUFOGreen:
            // Assign textureName and numHits values
            textureName = @"ufo_green.png";
            numHits = 3;
            break;
        case typeUFORed:
            // Assign textureName and numHits values
            textureName = @"ufo_red.png";
            numHits = 5;
            break;
        case typeUFOPurple:
            // Assign textureName and numHits values
            textureName = @"ufo_purple.png";
            numHits = 7;
            break;
            
        default:
            break;
    }
    
    // Initialize UFO sprite specifying texture image
    self = [super initWithImageNamed:textureName];
    
    if (!self) return(nil);
    
    // Initialize number of hits
    _numHits = numHits;
    
    return self;
}

#pragma mark - Check number of hits left

-(BOOL) checkNumHits{
    
    if(_numHits == 0) {
        // Remove UFO from scene and return TRUE
        [self removeFromParent];
        return TRUE;
    }
    
    return FALSE;
}

@end
