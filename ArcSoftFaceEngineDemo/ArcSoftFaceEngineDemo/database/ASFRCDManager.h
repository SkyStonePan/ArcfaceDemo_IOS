//
//  AFRCDManager.h
//  
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ASFRPerson;

@interface ASFRCDManager : NSObject

@property (readonly, assign, nonatomic) NSUInteger maxPersonID;

- (id)init;
- (void)reset; // clear memory cache

- (NSArray*)allPersons;
- (BOOL)addPerson:(ASFRPerson*)person;

- (void)setFrModelVersion:(NSUInteger)frModelVersion;
- (NSUInteger)getFrModeVersion;
- (BOOL)updatePersonFeatureData:(NSArray*)arrayPersons;

@end
