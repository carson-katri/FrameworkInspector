//
//  LazyView.swift
//  FrameworkInspector
//
//  Created by Carson Katri on 12/18/20.
//

import SwiftUI

struct LazyView<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
    }
}
