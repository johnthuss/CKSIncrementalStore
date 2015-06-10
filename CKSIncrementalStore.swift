//
//  CloudKitIncrementalStore.swift
//  
//
//  Created by Nofel Mahmood on 26/03/2015.
//
//

import CoreData
import CloudKit
import ObjectiveC

let CKSIncrementalStoreSyncEngineFetchChangeTokenKey="CKSIncrementalStoreSyncEngineFetchChangeTokenKey"
class CKSIncrementalStoreSyncEngine: NSObject {
    
    static let defaultEngine=CKSIncrementalStoreSyncEngine()
    var localStoreMOC:NSManagedObjectContext?
    
    func getLocalChanges()->[AnyObject]
    {
        var entityNames=self.localStoreMOC?.persistentStoreCoordinator?.managedObjectModel.entities.map({(entity)->String in
            
            return (entity as! NSEntityDescription).name!
        })
        
        var changedObjectIDs:[AnyObject]=[]
        
        for name in entityNames!
        {
            var fetchRequest=NSFetchRequest(entityName: name)
            var predicate = NSPredicate(format: "%K = %@ || %K = %@", CKSIncrementalStoreLocalStoreChangeTypeAttributeName,CKSLocalStoreRecordChangeType.RecordUpdated.rawValue,CKSIncrementalStoreLocalStoreChangeTypeAttributeName,CKSLocalStoreRecordChangeType.RecordDeleted.rawValue)
            fetchRequest.resultType=NSFetchRequestResultType.DictionaryResultType
            fetchRequest.propertiesToFetch = [CKSIncrementalStoreLocalStoreRecordIDAttributeName]
            var error:NSErrorPointer=nil
            var results = self.localStoreMOC?.executeFetchRequest(fetchRequest, error: error)
            if error == nil && results?.count > 0
            {
                changedObjectIDs.extend(results!)
            }
        }
        
        return [AnyObject]()
    }
    func performSync()
    {
        var fetchChangeToken:AnyObject?
        if NSUserDefaults.standardUserDefaults().objectForKey(CKSIncrementalStoreSyncEngineFetchChangeTokenKey) != nil
        {
            fetchChangeToken=NSUserDefaults.standardUserDefaults().objectForKey(CKSIncrementalStoreSyncEngineFetchChangeTokenKey)
        }
        
        var fetchChangesOperation = CKFetchRecordChangesOperation(recordZoneID: CKRecordZone(zoneName: CKSIncrementalStoreCloudDatabaseCustomZoneName).zoneID, previousServerChangeToken: fetchChangeToken! as! CKServerChangeToken)
        
        fetchChangesOperation.recordChangedBlock=({(record)->Void in
            
        })
        
        fetchChangesOperation.recordWithIDWasDeletedBlock=({(recordID)->Void in
            
        })
        fetchChangesOperation.fetchRecordChangesCompletionBlock=({(serverChangeToken,clientChangeToken,error)->Void in
            
            if error == nil
            {
                
            }
            
        })
        var operationQueue = NSOperationQueue()
        operationQueue.addOperation(fetchChangesOperation)
    }
}
class CKSIncrementalStoreSyncPushNotificationHandler
{
    static let defaultHandler=CKSIncrementalStoreSyncPushNotificationHandler()
    
    func handlePush(#userInfo:[NSObject : AnyObject])
    {
        var ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        if ckNotification.notificationType == CKNotificationType.RecordZone
        {
            var recordZoneNotification = CKRecordZoneNotification(fromRemoteNotificationDictionary: userInfo)
            if recordZoneNotification.recordZoneID.zoneName == CKSIncrementalStoreCloudDatabaseCustomZoneName
            {
                
            }
            
        }
    }
}

let CKSIncrementalStoreDatabaseType="CKSIncrementalStoreDatabaseType"
let CKSIncrementalStorePrivateDatabaseType="CKSIncrementalStorePrivateDatabaseType"
let CKSIncrementalStorePublicDatabaseType="CKSIncrementalStorePublicDatabaseType"

let CKSIncrementalStoreCloudDatabaseCustomZoneName="CKSIncrementalStore_OnlineStoreZone"

let CKSIncrementalStoreCloudDatabaseCustomZoneIDKey = "CKSIncrementalStoreCloudDatabaseCustomZoneIDKey"

let CKSIncrementalStoreCloudDatabaseSyncSubcriptionName="CKSIncrementalStore_Sync_Subcription"


let CKSIncrementalStoreLocalStoreChangeTypeAttributeName="changeType"
let CKSIncrementalStoreLocalStoreRecordIDAttributeName="recordID"

enum CKSLocalStoreRecordChangeType:Int16
{
    case RecordNoChange = 0
    case RecordUpdated  = 1
    case RecordDeleted  = 2
}

class CKSIncrementalStore: NSIncrementalStore {
    
    lazy var cachedValues:NSMutableDictionary={
        return NSMutableDictionary()
    }()
    
    var database:CKDatabase?
    var cloudDatabaseCustomZoneID:CKRecordZoneID?
    
    var backingPersistentStoreCoordinator:NSPersistentStoreCoordinator?
    lazy var backingMOC:NSManagedObjectContext={
        
        var moc=NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        moc.persistentStoreCoordinator=self.backingPersistentStoreCoordinator
        moc.retainsRegisteredObjects=true
        return moc
    }()
    
    override class func initialize()
    {
        NSPersistentStoreCoordinator.registerStoreClass(self, forStoreType: self.type)
    }
    override init(persistentStoreCoordinator root: NSPersistentStoreCoordinator, configurationName name: String?, URL url: NSURL, options: [NSObject : AnyObject]?) {
        
        self.database=CKContainer.defaultContainer().privateCloudDatabase
        
        if options != nil && options![CKSIncrementalStoreDatabaseType] != nil
        {
            var optionValue: AnyObject?=options![CKSIncrementalStoreDatabaseType]
            
            if optionValue! as! String == CKSIncrementalStorePublicDatabaseType
            {
                self.database=CKContainer.defaultContainer().publicCloudDatabase
            }
            
        }
        
        super.init(persistentStoreCoordinator: root, configurationName: name, URL: url, options: options)
        
    }
    
    class var type:String{
        return NSStringFromClass(self)
    }
    
    override func loadMetadata(error: NSErrorPointer) -> Bool {
        
        self.metadata=[
            NSStoreUUIDKey:NSProcessInfo().globallyUniqueString,
            NSStoreTypeKey:self.dynamicType.type
        ]
        
        var storeURL=self.URL
//        self.createCKSCloudDatabaseCustomZone()

        if true
        {
            var model:AnyObject=(self.persistentStoreCoordinator?.managedObjectModel.copy())!
            for e in model.entities
            {
                var entity=e as! NSEntityDescription
                
                if entity.superentity != nil
                {
                    continue
                }
                
                var recordIDAttributeDescription = NSAttributeDescription()
                recordIDAttributeDescription.name=CKSIncrementalStoreLocalStoreRecordIDAttributeName
                recordIDAttributeDescription.attributeType=NSAttributeType.StringAttributeType
                recordIDAttributeDescription.indexed=true
                
                var recordChangeTypeAttributeDescription = NSAttributeDescription()
                recordChangeTypeAttributeDescription.name=CKSIncrementalStoreLocalStoreChangeTypeAttributeName
                recordChangeTypeAttributeDescription.attributeType=NSAttributeType.Integer16AttributeType
                recordChangeTypeAttributeDescription.indexed=true
                
                entity.properties.append(recordIDAttributeDescription)
                entity.properties.append(recordChangeTypeAttributeDescription)
                
            }
            self.backingPersistentStoreCoordinator=NSPersistentStoreCoordinator(managedObjectModel: model as! NSManagedObjectModel)
        }
        
        var error: NSError? = nil
        if self.backingPersistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error)! == nil
        {
            print("Backing Store Error \(error)")
            return false
        }
        
        return true

    }
    func createCKSCloudDatabaseCustomZone()
    {
        var zone = CKRecordZone(zoneName: CKSIncrementalStoreCloudDatabaseCustomZoneName)
        
        self.database?.saveRecordZone(zone, completionHandler: { (zoneFromServer, error) -> Void in
            
            if error != nil
            {
                println("CKSIncrementalStore Custom Zone creation failed")
            }
            else
            {
                self.cloudDatabaseCustomZoneID=zone.zoneID
                self.createCKSCloudDatabaseCustomZoneSubcription()
            }
            
        })
    }
    func createCKSCloudDatabaseCustomZoneSubcription()
    {
        var subcription:CKSubscription = CKSubscription(zoneID: self.cloudDatabaseCustomZoneID, subscriptionID: CKSIncrementalStoreCloudDatabaseSyncSubcriptionName, options: nil)
        
        var subcriptionNotificationInfo = CKNotificationInfo()
        subcriptionNotificationInfo.alertBody=""
        subcriptionNotificationInfo.shouldSendContentAvailable = true
        subcription.notificationInfo=subcriptionNotificationInfo
        subcriptionNotificationInfo.shouldBadge=false
        
        var subcriptionsOperation=CKModifySubscriptionsOperation(subscriptionsToSave: [subcription], subscriptionIDsToDelete: nil)
        subcriptionsOperation.database=self.database
        subcriptionsOperation.modifySubscriptionsCompletionBlock=({ (modified,created,error) -> Void in
            
            if error != nil
            {
                println("Error \(error.localizedDescription)")
            }
            else
            {
                println("Successfull")
            }
            
        })
        
        var operationQueue = NSOperationQueue()
        operationQueue.addOperation(subcriptionsOperation)
    }
    
    override func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> AnyObject? {
        
        
        if request.requestType==NSPersistentStoreRequestType.FetchRequestType
        {
            var fetchRequest:NSFetchRequest=request as! NSFetchRequest
            return self.executeInResponseToFetchRequest(fetchRequest, context: context, error: error)
        }
        else if request.requestType==NSPersistentStoreRequestType.SaveRequestType
        {
            var saveChangesRequest:NSSaveChangesRequest=request as! NSSaveChangesRequest
            return self.executeInResponseToSaveChangesRequest(saveChangesRequest, context: context, error: error)
        }
        else
        {
            var exception=NSException(name: "Unknown Request Type", reason: "Unknown Request passed to NSManagedObjectContext", userInfo: nil)
            exception.raise()
        }
        
        return []
    }

    override func newValuesForObjectWithID(objectID: NSManagedObjectID, withContext context: NSManagedObjectContext, error: NSErrorPointer) -> NSIncrementalStoreNode? {
        
        var recordID:String = self.referenceObjectForObjectID(objectID) as! String
        var fetchRequest = NSFetchRequest(entityName: (objectID.entity.name)!)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@", CKSIncrementalStoreLocalStoreRecordIDAttributeName,recordID)
        var error:NSErrorPointer = nil
        var results = self.backingMOC.executeFetchRequest(fetchRequest, error: error)
        
        if error == nil && results?.count > 0
        {
            var managedObject:NSManagedObject = results?.first as! NSManagedObject
            var keys = managedObject.entity.attributesByName.keys.array.filter({(key)->Bool in
                
                if (key as! String) == CKSIncrementalStoreLocalStoreRecordIDAttributeName || (key as! String) == CKSIncrementalStoreLocalStoreChangeTypeAttributeName
                {
                    return false
                }
                return true
            })
            println("Keys \(keys.description)")
            var values = managedObject.dictionaryWithValuesForKeys(keys)
            println("Values \(values)")
            var incrementalStoreNode = NSIncrementalStoreNode(objectID: objectID, withValues: values, version: 1)
            
            println("IncrementalStoreNode \(incrementalStoreNode)")
            return incrementalStoreNode
        }
        
        return nil
//        var uniqueIdentifier:NSString=self.identifier(objectID) as! NSString
//        var object:CKRecord?
//        var checkInCache: AnyObject?=self.cachedValues.objectForKey(uniqueIdentifier)
//        if((checkInCache) != nil)
//        {
//            object=checkInCache as? CKRecord
//        }
//        else
//        {
//            var operationQueue:NSOperationQueue=NSOperationQueue()
//            var recordIDIdentifier:AnyObject=self.identifier(objectID)
//            var recordID:CKRecordID=CKRecordID(recordName: recordIDIdentifier as! String)
//        var fetchRecordsOperation:CKFetchRecordsOperation=CKFetchRecordsOperation(recordIDs: [CKRecordID(recordName: recordIDIdentifier as! String)])
//        
//            fetchRecordsOperation.fetchRecordsCompletionBlock=({(recordIDs,error)-> Void in
//                
//                if error==nil
//                {
//                    var recordsDictionary:NSDictionary=recordIDs as NSDictionary
//                    var record:CKRecord=recordsDictionary.objectForKey(recordID) as! CKRecord
//                    self.cachedValues.setObject(record, forKey: record.recordID.recordName)
//                    object=record as CKRecord
//
//                }
//            })
//            operationQueue.addOperation(fetchRecordsOperation)
//            operationQueue.waitUntilAllOperationsAreFinished()
//        }
//        var keys:NSArray=object!.allKeys() as NSArray
//        var values:NSMutableDictionary=NSMutableDictionary()
//        var relationships:NSDictionary=objectID.entity.relationshipsByName as NSDictionary
//        
//        for key in keys
//        {
//            var objectForKey: AnyObject!=object!.objectForKey(key as! String)
//            if objectForKey is CKReference
//            {
//                var reference:CKReference=objectForKey as! CKReference
//                var referenceEntity:NSRelationshipDescription=relationships.objectForKey(key) as! NSRelationshipDescription
//                var referenceObjectID:NSManagedObjectID=self.objectID(reference.recordID.recordName, entity: referenceEntity.destinationEntity!) as NSManagedObjectID
//                values.setValue(referenceObjectID, forKey: key as! String)
//            }
//            else
//            {
//                values.setValue(objectForKey, forKey: key as! String)
//            }
//        }
//        var incrementalStoreNode:NSIncrementalStoreNode=NSIncrementalStoreNode(objectID: objectID, withValues: values as [NSObject : AnyObject], version: 1)
//        return incrementalStoreNode
    }
    
    override func obtainPermanentIDsForObjects(array: [AnyObject], error: NSErrorPointer) -> [AnyObject]? {
        
        return array.map({ (object)->NSManagedObjectID in
            
            var insertedObject:NSManagedObject = object as! NSManagedObject
            return self.newObjectIDForEntity(insertedObject.entity, referenceObject: NSUUID().UUIDString)
            
        })
    }
    // MARK : Request Methods
    func executeInResponseToFetchRequest(fetchRequest:NSFetchRequest,context:NSManagedObjectContext,error:NSErrorPointer)->NSArray
    {
        var predicate = NSPredicate(format: "%K != %@", CKSIncrementalStoreLocalStoreChangeTypeAttributeName,NSNumber(short: CKSLocalStoreRecordChangeType.RecordDeleted.rawValue))
        
        if fetchRequest.predicate != nil
        {
            fetchRequest.predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [(fetchRequest.predicate)!,predicate])
        }
        else
        {
            fetchRequest.predicate = predicate
        }
        
        var error:NSErrorPointer = nil
        var resultsFromLocalStore = self.backingMOC.executeFetchRequest(fetchRequest, error: error)
        if error == nil && resultsFromLocalStore?.count > 0
        {
            resultsFromLocalStore = resultsFromLocalStore?.map({(result)->NSManagedObject in
                
                var managedObject:NSManagedObject = result as! NSManagedObject
                var objectID = self.newObjectIDForEntity((fetchRequest.entity)!, referenceObject: managedObject.valueForKey(CKSIncrementalStoreLocalStoreRecordIDAttributeName)!)
                var object = context.objectWithID(objectID)
                println(object.dictionaryWithValuesForKeys((self.persistentStoreCoordinator?.managedObjectModel.entitiesByName[(object.entity.name)!]?.attributesByName.keys.array)!))
                return object
            })
            
            return resultsFromLocalStore!
        }
        return []
//        var ckOperation:CKQueryOperation=self.cloudKitRequestOperationFromFetchRequest(fetchRequest, context: context) as! CKQueryOperation
//        
//        ckOperation.database=self.database
//        var record:CKRecord?
//        var results:NSMutableArray=NSMutableArray()
//        ckOperation.recordFetchedBlock=({ (record) -> Void in
//            
//            var ckRecord:CKRecord=record!
//            var objectID=self.objectID(ckRecord.recordID.recordName, entity: fetchRequest.entity!)
//            self.cachedValues.setObject(ckRecord, forKey: ckRecord.recordID.recordName)
//            var object=context.objectWithID(objectID)
//            results.addObject(object)
//        })
//        
//        var operationQueue:NSOperationQueue=NSOperationQueue()
//        operationQueue.addOperation(ckOperation)
//        operationQueue.waitUntilAllOperationsAreFinished()
//        return results

    }

    func executeInResponseToSaveChangesRequest(saveRequest:NSSaveChangesRequest,context:NSManagedObjectContext,error:NSErrorPointer)->NSArray
    {
        // Inserted Objects
        self.insertObjectsInBackingStore(Array(context.insertedObjects))
        
        // Updated Objects
        self.setObjectsInBackingStore(Array(context.updatedObjects), toChangeType: CKSLocalStoreRecordChangeType.RecordUpdated)
        
        // Deleted Objects
        self.setObjectsInBackingStore(Array(context.deletedObjects), toChangeType: CKSLocalStoreRecordChangeType.RecordDeleted)
        
        var error:NSErrorPointer = nil
        self.backingMOC.save(error)
        
//        var operation:CKModifyRecordsOperation=self.cloudKitModifyRecordsOperationFromSaveChangesRequest(saveRequest, context: context)
//
//        operation.database=self.database
//        var savedRecords:NSArray?
//        var deletedRecords:NSArray?
//        operation.modifyRecordsCompletionBlock=({(savedRecords,deletedRecords,error)->Void in
//            
//            if(error==nil)
//            {
//                NSLog("Saved Changes Successfully")
//            }
//            else
//            {
//                NSLog("All Changes Not Saved Successfully \(error)")
//            }
//        })
//        var operationQueue=NSOperationQueue()
//        operationQueue.addOperation(operation)
//        operationQueue.waitUntilAllOperationsAreFinished()
        
        return NSArray()
    }

    func insertObjectsInBackingStore(objects:Array<AnyObject>)
    {
        for object in objects
        {
            var managedObject:NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName(((object as! NSManagedObject).entity.name)!, inManagedObjectContext: self.backingMOC) as! NSManagedObject
            var keys = (object as! NSManagedObject).entity.attributesByName.keys.array
            var dictionary = object.dictionaryWithValuesForKeys(keys)
            managedObject.setValuesForKeysWithDictionary(dictionary)
            managedObject.setValue(self.referenceObjectForObjectID((object as! NSManagedObject).objectID), forKey: CKSIncrementalStoreLocalStoreRecordIDAttributeName)
            managedObject.setValue(NSNumber(short: CKSLocalStoreRecordChangeType.RecordUpdated.rawValue), forKey: CKSIncrementalStoreLocalStoreChangeTypeAttributeName)
        }
    }
    func setObjectsInBackingStore(objects:Array<AnyObject>,toChangeType changeType:CKSLocalStoreRecordChangeType)
    {
        var objectsByEntityNames:Dictionary<String,Array<AnyObject>> = Dictionary<String,Array<AnyObject>>()
        for object in objects
        {
            var managedObject = object as! NSManagedObject
            if objectsByEntityNames[(managedObject.entity.name)!] == nil
            {
                objectsByEntityNames[(managedObject.entity.name)!] = [managedObject]
            }
            else
            {
                objectsByEntityNames[(managedObject.entity.name)!]?.append(managedObject)
            }
        }
        
        var objectEntityNames = objectsByEntityNames.keys.array
        for key in objectEntityNames
        {
            var objectsInEntity:Array<AnyObject> = objectsByEntityNames[key]!
            var fetchRequestForBackingObjects = NSFetchRequest(entityName: key)
            var cksRecordIDs = Array(objectsInEntity).map({(object)->String in
                
                var managedObject:NSManagedObject = object as! NSManagedObject
                return self.referenceObjectForObjectID(managedObject.objectID) as! String
            })
            fetchRequestForBackingObjects.predicate = NSPredicate(format: "%K IN %@", CKSIncrementalStoreLocalStoreRecordIDAttributeName,cksRecordIDs)
            var error:NSErrorPointer = nil
            var results = self.backingMOC.executeFetchRequest(fetchRequestForBackingObjects, error: error)
            
            if error == nil && results?.count > 0
            {
                for var i=0; i<results?.count; i++
                {
                    var managedObject:NSManagedObject = results![i] as! NSManagedObject
                    var updatedObject:NSManagedObject = objectsInEntity[i as Int] as! NSManagedObject
                    var keys = self.persistentStoreCoordinator?.managedObjectModel.entitiesByName[(managedObject.entity.name)!]?.attributesByName.keys.array
                    var dictionary = updatedObject.dictionaryWithValuesForKeys(keys!)
                    managedObject.setValuesForKeysWithDictionary(dictionary)
                    managedObject.setValue(NSNumber(short: changeType.rawValue), forKey: CKSIncrementalStoreLocalStoreChangeTypeAttributeName)
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    

    // MARK : Mapping Methods

    func cloudKitModifyRecordsOperationFromSaveChangesRequest(saveChangesRequest:NSSaveChangesRequest,context:NSManagedObjectContext)->CKModifyRecordsOperation
    {
        var allObjects:NSArray=NSArray()
        if((saveChangesRequest.insertedObjects) != nil)
        {
            allObjects=allObjects.arrayByAddingObjectsFromArray((saveChangesRequest.insertedObjects! as NSSet).allObjects)
        }
        if((saveChangesRequest.updatedObjects) != nil)
        {
            allObjects=allObjects.arrayByAddingObjectsFromArray((saveChangesRequest.updatedObjects! as NSSet).allObjects)
        }
        
        var ckRecordsToModify:NSMutableArray=NSMutableArray()
        
        for managedObject in allObjects
        {
            ckRecordsToModify.addObject(self.ckRecordFromManagedObject(managedObject as! NSManagedObject))
        }
        
        var deletedObjects:NSArray=NSArray()
        if((saveChangesRequest.deletedObjects) != nil)
        {
            deletedObjects=deletedObjects.arrayByAddingObjectsFromArray((saveChangesRequest.deletedObjects! as NSSet).allObjects)
        }
        var ckRecordsToDelete:NSMutableArray=NSMutableArray()
        for managedObject in deletedObjects
        {
            ckRecordsToDelete.addObject(self.ckRecordFromManagedObject(managedObject as! NSManagedObject).recordID)
        }
        
        var ckModifyRecordsOperation:CKModifyRecordsOperation=CKModifyRecordsOperation(recordsToSave: ckRecordsToModify as [AnyObject], recordIDsToDelete: ckRecordsToDelete as [AnyObject])
        
        ckModifyRecordsOperation.database=self.database
        return ckModifyRecordsOperation
    }
    
    func cloudKitRequestOperationFromFetchRequest(fetchRequest:NSFetchRequest,context:NSManagedObjectContext)->NSOperation
    {
        var requestPredicate:NSPredicate=NSPredicate(value: true)
        if (fetchRequest.predicate != nil)
        {
            requestPredicate=fetchRequest.predicate!
        }
        
        var query:CKQuery=CKQuery(recordType: fetchRequest.entityName, predicate: requestPredicate)
        if (fetchRequest.sortDescriptors != nil)
        {
            query.sortDescriptors=fetchRequest.sortDescriptors!
        }
        
        var queryOperation:CKQueryOperation=CKQueryOperation(query: query)
        queryOperation.resultsLimit=fetchRequest.fetchLimit
        if (fetchRequest.propertiesToFetch != nil)
        {
            queryOperation.desiredKeys=fetchRequest.propertiesToFetch
        }
        queryOperation.database=self.database
        return queryOperation
    }
    
    func ckRecordFromManagedObject(managedObject:NSManagedObject)->CKRecord
    {
        var identifier:NSString=self.identifier(managedObject.objectID) as! NSString
        var recordID:CKRecordID=CKRecordID(recordName: identifier as String)
        var record:CKRecord=CKRecord(recordType: managedObject.entity.name, recordID: recordID)

        var attributes:NSDictionary=managedObject.entity.attributesByName as NSDictionary
        var relationships:NSDictionary=managedObject.entity.relationshipsByName as NSDictionary
        
        for var i=0;i<attributes.allKeys.count;i++
        {
            var key:String=attributes.allKeys[i] as! String
            var valueForKey:AnyObject?=managedObject.valueForKey(key)
            
            if valueForKey is NSString
            {
                record.setObject(valueForKey as! NSString, forKey: key)
            }
            else if valueForKey is NSDate
            {
                record.setObject(valueForKey as! NSDate, forKey: key)
            }
            else if valueForKey is NSNumber
            {
                record.setObject(valueForKey as! NSNumber, forKey: key)
            }
        }
       for var i=0;i<relationships.allKeys.count;i++
        {
            var key:String=relationships.allKeys[i] as! String
            var relationship:NSRelationshipDescription=relationships.objectForKey(i) as! NSRelationshipDescription
            
            if relationship.toMany==false
            {
                var valueForKey:AnyObject?=managedObject.valueForKey(key)
                var id: AnyObject=self.identifier(valueForKey!.objectID)
                var ckRecordID:CKRecordID=CKRecordID(recordName: id as! String)
                var ckReference:CKReference=CKReference(recordID: ckRecordID, action: CKReferenceAction.DeleteSelf)
                record.setObject(ckReference, forKey: key)
            }

        }
        
        return record
        
    }
    func identifier(objectID:NSManagedObjectID)->AnyObject
    {
        return self.referenceObjectForObjectID(objectID)
    }
    func objectID(identifier:String,entity:NSEntityDescription)->NSManagedObjectID
    {
        var objectID:NSManagedObjectID=self.newObjectIDForEntity(entity, referenceObject: identifier)
        return objectID
    }
    

}
