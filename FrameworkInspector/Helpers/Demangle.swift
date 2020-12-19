// Copyright 2020 Carton contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import Foundation

@_silgen_name("swift_demangle")
public func _stdlib_demangleImpl(
  mangledName: UnsafePointer<CChar>?,
  mangledNameLength: UInt,
  outputBuffer: UnsafeMutablePointer<CChar>?,
  outputBufferSize: UnsafeMutablePointer<UInt>?,
  flags: UInt32
) -> UnsafeMutablePointer<CChar>?

func demangle(_ mangledName: String) -> String {
  mangledName.utf8CString.withUnsafeBufferPointer { mangledNameUTF8CStr in
    let demangledNamePtr = _stdlib_demangleImpl(
      mangledName: mangledNameUTF8CStr.baseAddress,
      mangledNameLength: UInt(mangledNameUTF8CStr.count - 1),
      outputBuffer: nil,
      outputBufferSize: nil,
      flags: 0
    )

    if let demangledNamePtr = demangledNamePtr {
      let demangledName = String(cString: demangledNamePtr)
      free(demangledNamePtr)
      return demangledName
        .replacingOccurrences(of: " Swift.", with: " ")
        .replacingOccurrences(of: "(Swift.", with: "(")
        .replacingOccurrences(of: "<Swift.", with: "<")
    }
    return mangledName
  }
}

extension String {
    func typeFromMangledName() -> Any.Type? {
        let mangledName = data(using: .utf8)!
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: mangledName.count)
        let stream = OutputStream(toBuffer: buffer, capacity: mangledName.count)
        stream.open()
        mangledName.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> () in
            stream.write(pointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: mangledName.count)
        }
        stream.close()
        return _getTypeByMangledNameInContext(
            UnsafePointer(buffer),
            UInt(mangledName.count),
            genericContext: nil,
            genericArguments: nil
        )
    }
}
