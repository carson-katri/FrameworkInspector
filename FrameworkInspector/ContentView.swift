//
//  ContentView.swift
//  FrameworkInspector
//
//  Created by Carson Katri on 12/18/20.
//

import SwiftUI

struct ContentView: View {
    @State private var pickFile = false
    @State private var symbols: [(mangled: String, demangled: String)]?
    @AppStorage("tbd") private var file: URL?
    @State private var fileError: Error?
    @State private var query: String = ""
    
    var body: some View {
        NavigationView {
            List {
                if let fileError = fileError {
                    Text(fileError.localizedDescription)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(5)
                }
                HStack {
                    Button("Choose .tbd") { pickFile = true }
                    if let symbols = symbols {
                        Text("\(symbols.count) Symbols")
                    }
                }
                if let symbols = symbols {
                    ForEach(
                        symbols.filter { query == "" || $0.demangled.lowercased().contains(query.lowercased()) },
                        id: \.mangled
                    ) { type in
                        NavigationLink(destination: LazyView {
                            if let type = String(type.mangled.dropFirst(3).dropLast(2)).typeFromMangledName() {
                                ScrollView {
                                    VStack {
                                        TypeInfoInspector(type: type)
                                        Spacer()
                                    }
                                }
                            } else {
                                Text("Couldn't get type from the mangled name.")
                            }
                        }) {
                            VStack(alignment: .leading) {
                                Text(type.demangled)
                                Text(type.mangled)
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                    }
                }
            }
                .listStyle(SidebarListStyle())
        }
            .onAppear {
                if let file = file,
                   let tbd = try? String(contentsOf: file) {
                    symbols = parse(tbd)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.primaryAction) {
                    TextField("Search", text: $query)
                        .frame(width: 200)
                }
            }
            .fileImporter(isPresented: $pickFile, allowedContentTypes: [.text], allowsMultipleSelection: false) { res in
                switch res {
                case let .success(files):
                    guard let first = files.first,
                          let tbd = try? String(contentsOf: first)
                    else { return }
                    file = first
                    symbols = parse(tbd)
                    fileError = nil
                case let .failure(error):
                    fileError = error
                }
            }
    }
    
    func parse(_ tbd: String) -> [(mangled: String, demangled: String)] {
        let regex = try! NSRegularExpression(pattern: #"symbols:\s+\[[^\]]*\]"#)
        let symbolLists = regex.matches(in: tbd, range: NSRange(location: 0, length: (tbd as NSString).length))
            .map {
                (tbd as NSString).substring(with: $0.range).split(separator: "[")[1]
            }
        return symbolLists
            .map {
                $0.split(separator: ",")
                    .compactMap {
                        let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "'", with: "")
                        return (
                            mangled: trimmed,
                            demangled: demangle(trimmed)
                        )
                    }
            }
            .reduce([], +)
    }
}
