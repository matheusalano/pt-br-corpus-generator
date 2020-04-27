//
//  Helper.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 01/08/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

enum ColumnType {
    case original, final
}

struct ColumnFinal {
    let id: String
    let scene_id: String
    let person: String
    let en_us_line: String
    var pt_br_line: String
    let filename: String
}

struct ColumnOriginal {
    let id: String
    let scene_id: String
    let person: String
    let gender: String
    let original_line: String
    let line: String
    let metadata: String
    let filename: String
}

final class Helper {
    
    static func splitCSVColumns(row: String) -> ColumnFinal? {
        let columns: [String] = Helper.splitCSVColumns(row: row)
        
        guard columns.count == 6 else { return nil }
        
        return ColumnFinal(id: columns[0],
                           scene_id: columns[1],
                           person: columns[2],
                           en_us_line: columns[3],
                           pt_br_line: columns[4],
                           filename: columns[5])
    }
    
    static func splitCSVColumns(row: String) -> ColumnOriginal? {
        let columns: [String] = Helper.splitCSVColumns(row: row)
        
        guard columns.count == 8 else { return nil }
        
        return ColumnOriginal(id: columns[0],
                              scene_id: columns[1],
                              person: columns[2],
                              gender: columns[3],
                              original_line: columns[4],
                              line: columns[5],
                              metadata: columns[6],
                              filename: columns[7])
    }
    
    private static func splitCSVColumns(row: String) -> [String] {
        var columns: [String] = []
        
        if row.range(of: "\"") != nil {
            var textToScan = row
            var value:NSString?
            var textScanner = Scanner(string: textToScan)
            while textScanner.string != "" {
                if (textScanner.string as NSString).substring(to: 1) == "\"" {
                    textScanner.scanLocation += 1
                    textScanner.scanUpTo("\"", into: &value)
                    textScanner.scanLocation += 1
                } else {
                    textScanner.scanUpTo(";", into: &value)
                }
                
                columns.append(value! as String)
                
                if textScanner.scanLocation < textScanner.string.count {
                    textToScan = (textScanner.string as NSString).substring(from: textScanner.scanLocation + 1)
                } else {
                    textToScan = ""
                }
                textScanner = Scanner(string: textToScan)
            }
        } else {
            columns = row.components(separatedBy: ";")
        }
        
        return columns
    }
}

final class ThreadSafe<A> {
    private var _value: A
    private let queue = DispatchQueue(label: "ThreadSafe")
    init(_ value: A) {
        self._value = value
    }
    
    var value: A {
        return queue.sync { _value }
    }
    
    func atomically(_ transform: (inout A) -> ()) {
        queue.sync {
            transform(&self._value)
        }
    }
}

extension Array {
    func concurrentMap<B>(_ transform: @escaping (Element) -> B) -> [B] {
        let result = ThreadSafe(Array<B?>(repeating: nil, count: count))
        DispatchQueue.concurrentPerform(iterations: count) { idx in
            let element = self[idx]
            let transformed = transform(element)
            result.atomically {
                $0[idx] = transformed
            }
        }
        return result.value.map { $0! }
        
    }
}
