//
//  CorpusGenerator.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 05/07/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

final class CorpusGenerator {
    
    private let fileManager = FileManager.default
    private let fileURL: URL
    
    init(filename: String = "friends-final.csv") {
        let downloadsURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("PUCRS/pt-br-corpus-generator/")
        fileURL = downloadsURL.appendingPathComponent(filename)
        let colums = "id;scene_id;person;en_us_line;pt_br_line;filename"
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: colums.data(using: .utf8), attributes: nil)
        }
    }
    
    /**
     It adds a new line at the end of the file specified by the init parameter. The parameters are related to the columns on the CSV file.
     */
    func addNewLine(id: String, scene_id: String, person: String, en_us_line: String, pt_br_line: String, filename: String) {
        let en_line = en_us_line.contains(";") ? "\"" + en_us_line.replacingOccurrences(of: "\"", with: "") + "\"" : en_us_line
        let pt_line = pt_br_line.contains(";") ? "\"" + pt_br_line.replacingOccurrences(of: "\"", with: "") + "\"" : pt_br_line
        
        let line = "\n\(id);\(scene_id);\(person);\(en_line);\(pt_line);\(filename)"
        guard let data = line.data(using: .utf8) else { return }
        
        let fileHandle = FileHandle(forWritingAtPath: fileURL.path)
        fileHandle?.seekToEndOfFile()
        fileHandle?.write(data)
        fileHandle?.closeFile()
    }
    
    /**
     It adds a new raw line at the end of the file specified by the init parameter. It doesn't need any paratemeter.
     */
    func addNewLine(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        
        let fileHandle = FileHandle(forWritingAtPath: fileURL.path)
        fileHandle?.seekToEndOfFile()
        fileHandle?.write(data)
        fileHandle?.closeFile()
    }
    
    /**
     It returns the last index of the file specified by the init parameter.
     */
    func getLastIndex() -> Int? {
        guard let file = try? String(contentsOfFile: fileURL.path, encoding: .utf8) else { return nil }
        
        let rows = file.components(separatedBy: "\n")
        
        return rows.count
    }
    
    /**
     It prints all the hits, reviews and misses found on the file specified by the init parameter.
     */
    func printHitsAndMisses() {
        guard let file = try? String(contentsOfFile: fileURL.path, encoding: .utf8) else { return }
        
        let rows = file.components(separatedBy: "\n")
        var hits = 0
        var reviews = 0
        var onlyTrans = 0
        var subTrans = 0
        var misses = 0
        
        rows.forEach {
            let components = $0.components(separatedBy: ";")
            if components[4] != "" {
                if components[4].hasPrefix("REVIEW:") { reviews += 1 }
                else if components[4].hasPrefix("ONLY-TRANS:") { onlyTrans += 1 }
                else if components[4].hasPrefix("SUB-TRANS:") { subTrans += 1 }
                else { hits += 1 }
            } else {
                misses += 1
            }
        }
        
        print("TOTAL: \(hits + reviews + subTrans + onlyTrans + misses)")
        print("HITS: \(hits)")
        print("REVIEWS: \(reviews)")
        print("ONLY-TRANS: \(onlyTrans)")
        print("SUB-TRANS: \(subTrans)")
        print("MISSES: \(misses)")
    }
    
    func compareIdentifiers(with filename: String) {
        let downloadsURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("PUCRS/pt-br-corpus-generator/")
        let otherFileURL = downloadsURL.appendingPathComponent(filename)
        
        guard
            let file = try? String(contentsOfFile: fileURL.path, encoding: .utf8),
            let otherFile = try? String(contentsOfFile: otherFileURL.path, encoding: .utf8)
        else {
            fatalError("File not found.")
        }
        
        let rows: [String] = file.components(separatedBy: "\n")
        let otherRows: [String] = otherFile.components(separatedBy: "\n")
        
        for i in rows.indices {
            if rows[i].components(separatedBy: ";").first! != otherRows[i].components(separatedBy: ";").first! {
                print("INDEX: \(i) -- ID: \(rows[i].components(separatedBy: ";").first!) -- OTHERID: \(otherRows[i].components(separatedBy: ";").first!)")
            }
        }
    }
}
