#import "MineField.h"
#import "MineSquare.h"
#include <time.h>

#define testRow(row,i) (row-1+i/3)
#define testCol(col,i) (col-1+i%3)

#define isZeroProb(p) (p < 0.001)
#define isOneProb(p) (p > 0.999)

@implementation MineField

@synthesize perimeterSize;
@synthesize minesRemaining;
@synthesize detonated;
@synthesize deactived;

// Return the square at specified row and column
- (MineSquare*) squareAtRow: (ushort) row column: (ushort) column {
	return [[squares objectAtIndex: row] objectAtIndex: column];
}

- (void) updateRemainAtRow: (ushort) row column: (ushort) column {
	MineSquare *sq = [self squareAtRow:row column:column];
	if (![sq adjacent]) return;
	int adjRemain=[sq adjacent];
	for (int i=0; i<9; i++) {
		if (i!=4 && testRow(row,i)>=0 && testRow(row,i)<perimeterSize && testCol(column,i)>=0 && testCol(column,i)<perimeterSize) {
			// set adjRemain to adjacent cells
			MineSquare* adjSq = [self squareAtRow: testRow(row,i) column: testCol(column,i)];
			if ([adjSq flagged]) {
				adjRemain--;
			}
		}
	}
	[sq setAdjRemain:adjRemain];
}

// Step on a square: Lose or recurse
- (void) stepOnRow: (ushort) row column: (ushort) column {
	MineSquare* sq = [self squareAtRow: row column: column];
	
	// don't allow flagged mines to be pressed
	if ([sq flagged]) return;
	
	if ([sq isMine]) {
		detonated = YES; // Lose!
	} else {
		++recurseId;
		NSLog(@"step on: %d %d", row, column);
		[self recurseFromRow: row column: column];
		
		if (squaresRemaining == 0) {
			deactived = YES;
		}
	}
}

// Recurse through mine squares showing empty areas after a square is stepped on
- (void) recurseFromRow: (ushort) row column: (ushort) column {
	if (column < 0 || column >= perimeterSize || row < 0 || row >= perimeterSize) return;
	
	MineSquare* sq = [self squareAtRow: row column: column];
	
	//NSLog(@"Checking %d %d", row, column);
	
	if ([sq recurseId] >= recurseId) {
		//NSLog(@"Already recursed %d %d", row, column);
		return;
	}
	
	if (![sq isMine] && ![sq flagged]) {
		if (![sq empty]) --squaresRemaining;
		
		[sq setEmpty: YES];
		//NSLog(@"Remaining: %d r%d c%d", squaresRemaining, row, column);
	}
	if ([sq adjacent]) {
		//NSLog(@"Found adj at: %d %d", row, column);
		[self updateRemainAtRow:row column:column];
		for (int i=0; i<9; i++) {
			if (testRow(row,i)>=0 && testRow(row,i)<perimeterSize && testCol(column,i)>=0 && testCol(column,i)<perimeterSize) {
				[self updateProbabilityAroundRow:testRow(row,i) column:testCol(column,i)];
			}
		}
		return;
	}
	
	[sq setRecurseId: recurseId];
	
	[self recurseFromRow: row column: column - 1];
	[self recurseFromRow: row column: column + 1];
	[self recurseFromRow: row - 1 column: column];
	[self recurseFromRow: row + 1 column: column];
	[self recurseFromRow: row - 1 column: column -1];
	[self recurseFromRow: row - 1 column: column +1];
	[self recurseFromRow: row + 1 column: column -1];
	[self recurseFromRow: row + 1 column: column +1];
}

// Toggle flagged value
- (void) toggleFlagAtRow: (ushort) row column: (ushort) column {
	MineSquare* sq = [self squareAtRow: row column: column];
	
	BOOL flagValue = [sq flagged] ? NO : YES;
	
	if (flagValue == NO) ++minesRemaining;
	else if (minesRemaining >= 1) --minesRemaining;
	
	[sq setFlagged: flagValue];

	for (int i=0; i<9; i++) {
		if (i!=4 && testRow(row,i)>=0 && testRow(row,i)<perimeterSize && testCol(column,i)>=0 && testCol(column,i)<perimeterSize) {
			// set adjRemain to adjacent cells
			[self updateRemainAtRow:testRow(row,i) column:testCol(column,i)];
		}
	}
	
	for (int i=0; i<9; i++) {
		if (i!=4 && testRow(row,i)>=0 && testRow(row,i)<perimeterSize && testCol(column,i)>=0 && testCol(column,i)<perimeterSize) {
			[self updateProbabilityAroundRow:testRow(row,i) column:testCol(column,i)];
		}
	}
	
}

// Resize the board and place mines
- (void) setSize: (ushort) size andMineCount: (ushort) mineCount {
	ushort remainingMines = minesRemaining = mineCount;
	ushort i, j;
	short x, y;
	ushort sizeSquared = size * size;
	
	squaresRemaining = sizeSquared - remainingMines;
	
	perimeterSize = size;
	recurseId = 0;
	detonated = deactived = NO;
	
	srand(time(NULL));
	
	squares = [[NSMutableArray alloc] init];
	
	// create matrix size x size
	for (i = 0; i < size; i++) {
		NSMutableArray* arr = [[NSMutableArray alloc] init];
		
		for (j = 0; j < size; j++) {
			// calculate probability of isMine
			float p=((float)mineCount)/size/size;
			MineSquare* sq = [[MineSquare alloc] init];
			[sq setProbability:p];
			
			[arr addObject: sq];
		}
		
		[squares addObject: arr];
	}
	
	for (i = j = 0; remainingMines;) {
		// randomly place mines
		if (rand() % sizeSquared < 1 && remainingMines > 0) {
			MineSquare* sq = [self squareAtRow: i column: j];
			
			// skip if square is already a mine
			if (![sq isMine]) {
				[sq setIsMine: YES];

				for (x = -1; x <= 1; x++) {
					for (y = -1; y <= 1; y++) {
						if (	(x == 0 && y == 0)
							||	i + x < 0
							||	j + y < 0
							||	i + x >= perimeterSize
							||	j + y >= perimeterSize
						) continue;
						
						NSLog(@"Added adj at row: %d col: %d", i + x, j + y);
						MineSquare* adjSq = [self squareAtRow: i + x column: j + y];
						[adjSq setAdjRemain: [adjSq adjRemain] + 1];
						[adjSq setAdjacent: [adjSq adjacent] + 1];
					}
				}
				
				--remainingMines;
				//NSLog(@"Added log at row: %d col: %d remaining: %d", i, j, remainingMines);
			}
		}
		
		j++;
		if (j >= size) {
			j = 0;
			i++;
		}
		if (i >= size) i = 0;
	}
}

- (void) updateProbabilityAroundRow: (ushort) row column: (ushort) column
{
	ushort uncertainSquares=8;
	MineSquare* sq = [self squareAtRow:row column:column];
	if (![sq empty]||[sq flagged]) {
		return;
	}
	for (int i=0; i<9; i++) {
		if (i!=4 && testRow(row,i)>=0 && testRow(row,i)<perimeterSize && testCol(column,i)>=0 && testCol(column,i)<perimeterSize) {
			MineSquare* adjSq = [self squareAtRow: testRow(row,i) column: testCol(column,i)];
			if ([adjSq flagged]||[adjSq empty])
				uncertainSquares--;
		}
	}
	float probability = ((float)[sq adjRemain])/uncertainSquares;
	if (isOneProb(probability))
		probability = 1;
	else if(isZeroProb(probability))
		probability = 0;
	
	for (int i=0; i<9; i++) {
		if (i!=4 && testRow(row,i)>=0 && testRow(row,i)<perimeterSize && testCol(column,i)>=0 && testCol(column,i)<perimeterSize) {
			MineSquare* adjSq = [self squareAtRow: testRow(row,i) column: testCol(column,i)];
			if (![adjSq flagged]&&![adjSq empty]) {
				if ((!isZeroProb([adjSq probability])&&probability>[adjSq probability])||isZeroProb(probability))
					[adjSq setProbability:probability];
			}
		}
	}
}

@end
