//
//  MPCustomClassPG.m
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MPCustomClassScrubDruid.h"
#import "MPCustomClass.h"
#import "PatherController.h"
#import "PlayerDataController.h"
#import "Mob.h"
#import "BlacklistController.h"
#import "MPSpell.h"
#import "MPMover.h"
#import "Player.h"
#import "Unit.h"
#import "MPTimer.h"


@implementation MPCustomClassScrubDruid
@synthesize wrath, mf, motw, rejuv, healingTouch, thorns, listSpells, listParty, timerGCD, timerRefreshParty, timerBuffCheck, timerSpellScan;

- (id) initWithController:(PatherController*)controller {
	if ((self = [super initWithController:controller])) {
		
		self.wrath = nil;
		self.mf    = nil;
		self.motw  = nil;
		self.rejuv = nil;
		self.healingTouch = nil;
		self.thorns = nil;

		self.listSpells = nil;
		
		self.listParty = nil;
		
		
		self.timerGCD =  [MPTimer timer:1000]; // 1 sec cooldown
		[timerGCD forceReady]; // start off ready
		
		self.timerRefreshParty = [MPTimer timer:300000];  // 5 minutes
		[timerRefreshParty forceReady];
		
		self.timerBuffCheck = [MPTimer timer:3000];  // every 3 seconds
		[timerBuffCheck forceReady];
		
		self.timerSpellScan = [MPTimer timer:300000]; // 5 minutes
		[timerSpellScan forceReady];
		
		state = CCCombatPreCombat;
	}
	return self;
}

- (void) dealloc
{
	[wrath release];
	[mf release];
	[motw release];
	[rejuv release];
	[healingTouch release];
	[thorns release];
    [timerGCD release];
	[timerRefreshParty release];
	[timerBuffCheck release];
	[timerSpellScan release];
	[listSpells release];
	[listParty release];
	
    [super dealloc];
}

#pragma mark -



- (NSString *) name {
	return @"ScrUb Druid";
}



- (void) preCombatWithMob: (Mob *) aMob atDistance:(float) distanceToMob {
	
	// preCombatWithMob:atDistance:  is called numerous times for 
	// your CC to determine what to do on approaching your target (at various distances)
	
	//// let's make sure we have our buffs up:
	PlayerDataController *me = [PlayerDataController sharedController];
	Player *myToon = [me player];
	if( ![thorns unitHasBuff:myToon]) {
		[me setPrimaryTarget:myToon];
		[thorns cast];
	}
	
	if( ![motw unitHasBuff:myToon]) {
		[me setPrimaryTarget:myToon];
		[motw cast];
	}
	
	state = CCCombatPreCombat;
}

- (MPCombatState) killTarget: (Mob*) mob {
	
	
	
	// if player isDead
	PlayerDataController *me = [PlayerDataController sharedController];
	if (([me isDead] ) || ([me isGhost])) {
		return CombatStateDied;
	} // end if
	

	

	
	
	
	
	
	
	// switch state
	switch (state) {
			
		////
		//// This is our first action in combat.  Use this for any opening moves
		////
		case CCCombatPreCombat:
			currentMob = mob;
			
			if ([currentMob isDead] ) {
				
				PGLog(@" CCCombatPreCombat : given mob is already dead.... returning Mistake.");
				return CombatStateMistake;
			}
			
			
			
			//// Perform initial opening move here:
			
			
			
			state = CCCombatCombat;
			return CombatStateInCombat;
			break;
			
			
			
			
			
		////
		//// We are now in combat performing "normal" combat operations  
		////
		case CCCombatCombat:

			//// 
			//// Check for Combat/Mob Status
			////
			
			//// if [mob isDead]
			if ([mob isDead]) {
				
				PGLog(@"  ccKillTarget: mob is Dead ");
				state = CCCombatPreCombat;  // reset my combat to do initial attack.
				
				NSArray *mobList = [self mobsAttackingMe];
				
				// if attackQueue is empty then all done.
				if ( [mobList count] < 1 ) {
					
					// return CombatSuccess
					return CombatStateSuccess;
					
				} else {
					// there are more to deal with:
					
					// currentMob = currentTarget
					self.currentMob = [mobList objectAtIndex:0]; // <-- choose by some criteria

					// return CombatSuccessWithAdd
					return CombatStateSuccessWithAdd;
					
				} // end if
				
			} // end if
			
			//// check for Evading => Bugged
			// if( ![unit isInCombat] || [unit isEvading] || ![unit isAttackable] ) {
			if( [mob isEvading] || ![mob isAttackable] ) { 
				return CombatStateBugged;
			}

			
	
			// if unit ended up blacklisted ... bail
			if ([[patherController blacklistController] isBlacklisted:mob]) {
				PGLog(@"   Mob ended up Blacklisted.  You can ask CombatController why ... ");
				return CombatStateBugged;
			}
			
			
			
			
			
			////
			//// all the status checks are passed, so attack!
			////
			
			// face target
			PGLog(@"     --> Facing Target");
			MPMover *mover = [MPMover sharedMPMover];
			MPLocation *targetLocation = (MPLocation *)[mob position];
			[mover moveTowards:targetLocation within:33.0f facing:targetLocation];

			
			//// make sure we stop here!
			
			
			int error = 0;
			
			//// do my healing checks here:
			
			
			
			
			
			// make sure I'm targeting the target:
//			PlayerDataController *me = [PlayerDataController sharedController];
			if ([me targetID] != [mob GUID]) {
				PGLog(@"     --> Setting Target : myTarget[0x%X]  mob[0x%X]",[me targetID], [mob lowGUID]);
				[me setPrimaryTarget:mob];
			}
			
			PGLog(@"  Casting:");
			
			if ([timerGCD ready]) {
				PGLog( @"   timerGGD ready");
			
				if( ![me isCasting] ) {
					PGLog( @"   me !casting");
					
					
					if ([mf canCast]) {
						
						if (![mf unitHasDebuff:mob]) {
							
							error = [mf cast];
							if (!error) {
								[timerGCD start];
								return CombatStateInCombat;
							}
							
						}
					} 
					else {
						PGLog( @"   MF : !canCast");
					}
					
					
					if ([wrath canCast]) {
						PGLog(@"    Wrath: canCast");
						
						// cast
						error = [wrath cast];
						if(!error){
							[timerGCD start];
							return CombatStateInCombat;
						}
						PGLog(@"    ---> wrath cast error[%d]", error);
						
					}
				
				}
				
				
			}

			return CombatStateInCombat;
			break;
		default:
			break;
	}

	
	// shouldn't get to here!  One of the above should proc.
	return CombatStateDied;
}



- (BOOL) rest {

	PlayerDataController *player = [PlayerDataController sharedController];
	
	// if !inCombat
	if (![player isInCombat]) {
		
		// if health < healthTrigger  || mana < manaTrigger
		if ( ([player percentHealth] <= 99 ) || ([player percentMana] <= 99) ) {
			
			PGLog(@"Should do something during Rest Phase");
			
			return NO; // must not be done yet ... 
			
		} // end if
	}
	return YES;
}



- (void) runningAction {
	
	// make sure our spell list is updated
	if ([timerSpellScan ready] ) {
		
		for(MPSpell *spell in listSpells) {
			PGLog(@"reloading spell[%@]", [spell name]);
			[spell loadPlayerSettings];
		}
		[timerSpellScan reset];
	}
	
	// make sure our list of party members is updated
	if ([timerRefreshParty ready]) {
		
		self.listParty = [[PlayerDataController sharedController] partyMembers];
		
		PGLog(@" refreshing Party Members: count[%d]", [listParty count]);
		[timerRefreshParty reset];
	}
	
	
	// check everyone for Buffs
	PlayerDataController *me = [PlayerDataController sharedController];
	if ([timerBuffCheck ready]) {
		
		//// Check if party members have buffs
		for( Player* player in listParty) {
		
			PGLog(@"checking party member buffs [%@]", [player name]);
			if( ![thorns unitHasBuff:(Unit*)player]) {
				[me setPrimaryTarget:player];
				[thorns cast];
				[timerBuffCheck reset];
				return;
			}
			
			if( ![motw unitHasBuff:(Unit *)player]) {
				[me setPrimaryTarget:player];
				[motw cast];
				[timerBuffCheck reset];
				return;
			}
		}
		
		//// personal buffs
		Unit *myCharacter = [[PlayerDataController sharedController] player];
		if( ![thorns unitHasBuff:myCharacter]) {
			[me setPrimaryTarget:myCharacter];
			[thorns cast];
			[timerBuffCheck reset];
			return;
		}
		
		if( ![motw unitHasBuff:(Unit *)myCharacter]) {
			[me setPrimaryTarget:myCharacter];
			[motw cast];
			[timerBuffCheck reset];
			return;
		}
	
		[timerBuffCheck reset];
	}
	
}



- (void) setup {
	
	self.wrath = [MPSpell wrath];
	self.mf    = [MPSpell moonfire];
	self.motw  = [MPSpell motw];
	self.rejuv = [MPSpell rejuvenation];
	self.healingTouch = [MPSpell healingTouch];
	self.thorns = [MPSpell thorns];
	
	
	NSMutableArray *spells = [NSMutableArray array];
	[spells addObject:wrath];
	[spells addObject:mf];
	[spells addObject:motw];
	[spells addObject:rejuv];
	[spells addObject:healingTouch];
	[spells addObject:thorns];
	self.listSpells = [spells copy];
	
	self.listParty = [[PlayerDataController sharedController] partyMembers];
	
}



#pragma mark -

+ (id) classWithController: (PatherController *) controller {
	
	return [[[MPCustomClassScrubDruid alloc] initWithController:controller] autorelease];
}
@end
