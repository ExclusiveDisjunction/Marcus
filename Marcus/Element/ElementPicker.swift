//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import CoreData

public struct ElementPicker<T> : View where T: Identifiable & NamedElement & NSManagedObject {
    public init(
        _ target: Binding<T?>,
        withSorting: [SortDescriptor<T>] = [],
        withPredicate: NSPredicate? = nil,
        onNil: LocalizedStringKey = "(Pick One)"
    ) {
        self._target = target
        self.onNil = onNil;
        self._choices = FetchRequest(sortDescriptors: withSorting, predicate: withPredicate)
    }
    
    @FetchRequest private var choices: FetchedResults<T>;
    
    @Binding private var target: T?;
    @State private var id: T.ID?;
    private let onNil: LocalizedStringKey;
    
    public var body: some View {
        Picker("", selection: $id) {
            Text(onNil)
                .italic()
                .tag(nil as T.ID?)
            
            ForEach(choices) { choice in
                Text(choice.name)
                    .tag(choice.id)
            }
        }.labelsHidden()
            .onChange(of: id) { _, newId in
                guard let id = newId else {
                    self.target = nil;
                    return;
                }
                
                self.target = choices.first(where: { $0.id == id } )
            }
    }
}

public struct EnumPicker<T> : View where T: CaseIterable & Identifiable & Displayable, T.AllCases: RandomAccessCollection, T.ID == T {
    @Binding public var value: T;
    
    public var body: some View {
        Picker("", selection: $value) {
            ForEach(T.allCases) { element in
                Text(element.display).tag(element)
            }
        }.labelsHidden()
    }
}
