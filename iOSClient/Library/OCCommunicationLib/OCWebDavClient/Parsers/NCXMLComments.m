//
//  NCXMLComments.m
//  Nextcloud
//
//  Created by Marino Faggiana on 08/08/19.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "NCXMLComments.h"

@interface NCXMLComments()

@property (nonatomic, strong) NSMutableString *xmlChars;
@property (nonatomic, strong) NSMutableDictionary *xmlBucket;

@end

@implementation NCXMLComments

/*
 * Method that init the parse with the xml data from the server
 * @data -> XML webDav data from the owncloud server
 */
- (void)initParserWithData: (NSData*)data{
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    
}


#pragma mark - XML Parser Delegate Methods


/*
 * Method that init parse process.
 */

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    if (!self.xmlChars) {
        self.xmlChars = [NSMutableString string];
    }
    
    [self.xmlChars setString:@""];
    
    if ([elementName isEqualToString:@"ocs"]) {
        self.xmlBucket = [NSMutableDictionary dictionary];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"statuscode"]) {
        self.statusCode = [self.xmlChars intValue];
    }

    if ([elementName isEqualToString:@"token"]) {
        self.token = [NSString stringWithString:self.xmlChars];
    }
    
    if ([elementName isEqualToString:@"message"]) {
        self.message = [NSString stringWithString:self.xmlChars];
    }
    
    if ([elementName isEqualToString:@"url"]) {
        self.url = [NSString stringWithString:self.xmlChars];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.xmlChars appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
    
    NSLog(@"Finish xml directory list parse");
}

@end
