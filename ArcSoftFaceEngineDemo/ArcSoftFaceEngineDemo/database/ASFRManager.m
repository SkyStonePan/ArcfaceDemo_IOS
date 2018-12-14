//
//  ASFRManager.m
//

#import "ASFRManager.h"
#import "ASFRCDManager.h"

@interface ASFRManager ()
{
    
}

@property (atomic, assign) NSUInteger maxPersonId;
@property (nonatomic, strong) ASFRCDManager* cdManager;
@property (nonatomic, strong, readwrite) NSMutableArray* allPersons;

@end

@implementation ASFRManager


- (instancetype)init
{
    if (self = [super init]) {
        _cdManager = [[ASFRCDManager alloc] init];
        
        _frModelVersion = [_cdManager getFrModeVersion];
        _allPersons = [NSMutableArray arrayWithArray:[_cdManager allPersons]];
        _maxPersonId = _cdManager.maxPersonID;
    }
    
    return self;
}

- (BOOL)addPerson:(ASFRPerson*)person
{
    [_allPersons addObject:person];
    
    return [_cdManager addPerson:person];
}

- (NSUInteger)getNewPersonID
{
    self.maxPersonId += 1;
    return self.maxPersonId;
}

- (void)setFrModelVersion:(NSUInteger)frModelVersion
{
    _frModelVersion = frModelVersion;
    _cdManager.frModelVersion = frModelVersion;
}

- (BOOL)updateAllPersonsFeatureData
{
    return [_cdManager updatePersonFeatureData:_allPersons];
}
@end
