#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum {
    
    typeUFOGreen = 0,
    typeUFORed,
    typeUFOPurple
    
} UFOTypes;

@interface UFO : CCSprite {
    
}

// Declare property for number of hits
@property (readwrite, nonatomic) int numHits;

// Declare property for type of UFO
@property (readonly, nonatomic) UFOTypes ufoType;

// Declare method to init UFOs
-(id) initWithHits:(int)hits;

// Declare method to init UFOs with type
-(id) initWithType:(UFOTypes)type;

// Declare check method
-(BOOL) checkNumHits;

@end
