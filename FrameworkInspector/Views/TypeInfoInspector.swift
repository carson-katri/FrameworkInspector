//
//  TypeInfoInspector.swift
//  FrameworkInspector
//
//  Created by Carson Katri on 12/18/20.
//

import SwiftUI
import Runtime

struct TypeInfoInspector: View {
    let info: TypeInfo?
    let level: Int
    
    init(type: Any.Type, level: Int = 0) {
        self.info = try? typeInfo(of: type)
        self.level = level
    }
    
    @ViewBuilder
    var content: some View {
        if let info = info {
            ForEach(info.properties, id: \.name) { prop in
                DisclosureGroup {
                    TypeInfoInspector(type: prop.type, level: level + 1)
                } label: {
                    HStack {
                        Text(prop.name)
                        Text(String(describing: prop.type))
                            .opacity(0.8)
                    }
                }
            }
            ForEach(
                Array(
                    info.genericTypes
                        .filter { genericType in !info.properties.contains(where: { $0.type == genericType }) }
                        .enumerated()
                ),
                id: \.offset
            ) { type in
                DisclosureGroup {
                    TypeInfoInspector(type: type.element, level: level + 1)
                } label: {
                    Text("<\(String(describing: type.element))>")
                        .opacity(0.8)
                }
            }
            ForEach(
                info.cases,
                id: \.name
            ) { c in
                DisclosureGroup {
                    if let payloadType = c.payloadType {
                        TypeInfoInspector(type: payloadType, level: level + 1)
                    }
                } label: {
                    HStack(spacing: 0) {
                        Text(".\(c.name)")
                        if let payloadType = c.payloadType {
                            Text("(")
                            Text(String(describing: payloadType))
                                .opacity(0.8)
                            Text(")")
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        if let info = info {
            VStack {
                if level == 0 {
                    DisclosureGroup(String(describing: info.type)) {
                        content
                            .padding(.leading)
                    }
                } else {
                    content
                        .padding(.leading)
                }
            }
        }
    }
}
