#if DEBUG
import CoreData
import Foundation
import SwiftData

/// Creates the full CloudKit schema in the Development environment, Debug builds only.
/// Launch a signed Debug build with `-initializeCloudKitSchema` once, then deploy the schema
/// to Production in CloudKit Console. Uses a separate throwaway store file.
enum CloudKitSchema {
    static func initializeIfRequested() {
        guard CommandLine.arguments.contains("-initializeCloudKitSchema") else { return }
        do {
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [BudgetItem.self, PayMethod.self]) else {
                print("CloudKitSchema: could not build the managed object model")
                return
            }
            let url = URL.temporaryDirectory.appending(path: "SchemaInit.sqlite")
            let description = NSPersistentStoreDescription(url: url)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: CloudSync.containerIdentifier)
            description.shouldAddStoreAsynchronously = false
            let container = NSPersistentCloudKitContainer(name: "SchemaInit", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            var loadError: Error?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError { throw loadError }
            // CloudKit may need the main run loop to finish account and zone setup.
            // Schema initialization blocks, so keep it off the app's launch thread.
            DispatchQueue.global(qos: .utility).async {
                do {
                    try container.initializeCloudKitSchema(options: [])
                    print("CloudKitSchema: initialized the Development schema")
                } catch {
                    print("CloudKitSchema: failed: \(error)")
                }
            }
        } catch {
            print("CloudKitSchema: failed: \(error)")
        }
    }
}
#endif
