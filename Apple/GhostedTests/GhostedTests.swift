//
//  MarcusTests.swift
//  MarcusTests
//
//  Created by Hollan Sellars on 3/1/26.
//

import Testing
import CoreData

import ExDisj
import Ghosted

struct GhostedTests {

    @Test
    func loadDebugStore() async throws {
        let container = try await DataStack.debugContainer();
        
        let count = try await confirmation { complete in
            try await container.viewContext.perform {
                let appCount = try container.viewContext.count(for: JobApplication.fetchRequest());
                
                complete();
                return appCount;
            }
        }
        
        #expect(count != 0);
    }

}
