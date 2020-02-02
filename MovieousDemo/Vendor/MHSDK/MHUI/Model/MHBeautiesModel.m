//
//  MHBeautiesModel.m


#import "MHBeautiesModel.h"

@implementation MHBeautiesModel
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.imgName forKey:@"beautyImage"];
    [aCoder encodeObject:self.beautyTitle forKey:@"beautyTitle"];
    [aCoder encodeObject:self.originalValue forKey:@"value"];
    [aCoder encodeObject:@(self.isSelected) forKey:@"isSelected"];
    [aCoder encodeObject:@(self.type) forKey:@"beautyType"];
    [aCoder encodeObject:@(self.aliment) forKey:@"watermarkAliment"];



}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.imgName = [aDecoder decodeObjectForKey:@"beautyImage"];
        self.beautyTitle = [aDecoder decodeObjectForKey:@"beautyTitle"];
        self.originalValue = [aDecoder decodeObjectForKey:@"value"];
        self.type = (NSInteger)[aDecoder decodeObjectForKey:@"beautyType"];
        self.aliment = (NSInteger)[aDecoder decodeObjectForKey:@"watermarkAliment"];
        self.isSelected = [aDecoder decodeObjectForKey:@"isSelected"];

    }
    return self;
}


@end
