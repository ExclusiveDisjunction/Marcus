//
//  MarcusTests.swift
//  MarcusTests
//
//  Created by Hollan Sellars on 3/1/26.
//

import Testing
import Marcus
import CoreData

struct MarcusTests {

    @Test
    func loadDebugStore() async throws {
        let container = DataStack.shared.debugContainer;
        
        let count = try await container.viewContext.perform {
            let appCount = try container.viewContext.count(for: JobApplication.fetchRequest());
            
            return appCount;
        }
        
        #expect(count != 0);
    }

}
