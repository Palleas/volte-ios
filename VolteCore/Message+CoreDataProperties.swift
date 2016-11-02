//
//  Message+CoreDataProperties.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-11-01.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import CoreData

extension Message {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message");
    }

    @NSManaged public var uid: Int32
    @NSManaged public var content: String?
    @NSManaged public var author: String?
    @NSManaged public var postedAt: NSDate?
    @NSManaged public var attachments: NSSet?

}

// MARK: Generated accessors for attachments
extension Message {

    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: Attachment)

    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: Attachment)

    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)

}
