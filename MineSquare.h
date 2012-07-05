#import <Cocoa/Cocoa.h>

@interface MineSquare : NSObject {
	BOOL isMine;
	BOOL flagged;
	BOOL empty;
	unsigned short adjacent;
	unsigned short adjRemain;
	unsigned int recurseId;
	float probability;
}

@property (readwrite) BOOL isMine;
@property (readwrite) BOOL flagged;
@property (readwrite) BOOL empty;
@property (readwrite) unsigned short adjacent;
@property (readwrite) unsigned short adjRemain;
@property (readwrite) unsigned int recurseId;
@property (readwrite) float probability;

@end
