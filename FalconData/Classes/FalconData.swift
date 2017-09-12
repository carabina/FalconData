//  FalconData
//
//  Created by gelopfalcon@gmail.com on 09/11/2017.
//  Copyright (c) 2017 gelopfalcon@gmail.com. All rights reserved.
//

import Foundation
import CoreData
import SugarRecord

public class Storage: NSObject {
    private var database: CoreDataDefaultStorage
    public var dataBaseName: String {
        didSet {
            database = Storage.defaultStorage(withName: dataBaseName)
            
        }
    }
    static let shared = Storage()
    
    private override init() {
        self.dataBaseName = "default"
        self.database = Storage.defaultStorage(withName: dataBaseName)
    }
    
    
    static func defaultStorage(withName name:String) -> CoreDataDefaultStorage {
        let store = CoreDataStore.named(name)
        let bundle = Bundle(for: Storage.classForCoder())
        let model = CoreDataObjectModel.merged([bundle])
        return try! CoreDataDefaultStorage(store: store, model: model)
    }
    
    func fetch<T: NSManagedObject>(ofType type: T.Type, filterBy predicate: NSPredicate? = nil) -> [T] {
        var request = FetchRequest<T>()
        
        if let predicate = predicate {
            request = request.filtered(with: predicate)
        }
        
        let objects = try? self.database.fetch(request)
        return objects != nil ? objects! : []
    }
    
    func create<T: NSManagedObject>(ofType type: T.Type, insert:  @escaping (T)->Void) -> T? {
        return try? self.database.operation({ (context, save) -> T in
            let object: T = try! context.create()
            insert(object)
            save()
            
            return object
        })
    }
    
    func update<T: NSManagedObject>(_ type: T.Type, matching predicate: NSPredicate, with updates: @escaping (T) -> Void) throws {
        try self.database.operation({ (context, save) -> Void in
            guard let object = try context.request(type).filtered(with: predicate).fetch().first else { return }
            
            updates(object)
            save()
        })
    }
    
    func remove<T: NSManagedObject>(_ type: T.Type, matching predicate: NSPredicate) throws {
        try self.database.operation({ (context, save) -> Void in
            guard let object = try context.request(type).filtered(with: predicate).fetch().first else { return }
            
            try context.remove(object)
            save()
        })
    }
    
    func reset() throws {
        try self.database.removeStore()
    }
    
}

