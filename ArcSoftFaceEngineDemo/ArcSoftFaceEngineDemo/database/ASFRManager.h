//
//  ASFRManager.h
//

#import <Foundation/Foundation.h>
#import "ASFRPerson.h"

@interface ASFRManager : NSObject

@property (nonatomic, strong, readonly) NSArray* allPersons;
@property (nonatomic, assign) NSUInteger frModelVersion;

- (BOOL)addPerson:(ASFRPerson*)person;

- (NSUInteger)getNewPersonID;

- (BOOL)updateAllPersonsFeatureData;

@end
