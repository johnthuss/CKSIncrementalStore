//
//  Task.swift
//  CKSIncrementalStoreDemo
//
//  Created by Nofel Mahmood on 19/07/2015.
//  Copyright (c) 2015 CloudKitSpace. All rights reserved.
//

import Foundation
import CoreData

class Task: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var tags: NSSet

}
