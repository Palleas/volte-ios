//
//  Attachment+CoreDataProperties.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-11-01.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import CoreData

extension Attachment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment");
    }

    @NSManaged public var mimeType: String?
    @NSManaged public var data: NSData?
    @NSManaged public var message: Message?

}
