//
//  FriendsReviewValidation.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 01/08/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

final class FriendsReviewValidation {
    
    private let rows: [String]
    
    init() {
        let url =  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("PUCRS/pt-br-corpus-generator/friends-final.csv")
        
        guard let file = try? String(contentsOfFile: url.path, encoding: .utf8) else {
            fatalError("File not found.")
        }
        
        rows = file.components(separatedBy: "\n")
    }
    
    /**
     It starts review validation with more flexibe parameters.
     When the portuguese version is found, a `REVIEW:` prefix is added in order to identify the lines that require revision.
     */
    func start() {
        
        let corpusGenerator = CorpusGenerator(filename: "friends-final-2.csv")
        let subtitleParser = FriendsSubtitleParser()
        
        subtitleParser.range = 600
        subtitleParser.similarityAcceptance = 0.3
        
        let index: Int
        if let idx = corpusGenerator.getLastIndex() {
            index = idx
        } else {
            index = 1
        }
        
        print("### Starting at index \(index) ###")
        
        for row in rows[index...] {
            guard let columns: ColumnFinal = Helper.splitCSVColumns(row: row) else {
                corpusGenerator.addNewLine(row)
                continue
            }
            
            func addNewLine(eng: String, ptbr: String) {
                corpusGenerator.addNewLine(id: columns.id,
                                           scene_id: columns.scene_id,
                                           person: columns.person,
                                           en_us_line: eng,
                                           pt_br_line: ptbr,
                                           filename: columns.filename)
            }
            
            guard columns.pt_br_line == "" else {
                addNewLine(eng: columns.en_us_line, ptbr: columns.pt_br_line)
                continue
            }
            
            if
                let english = subtitleParser.getSubtitle(from: columns.en_us_line, filename: columns.filename, language: .english),
                let ptbr = subtitleParser.getSubtitle(from: english, filename: columns.filename, language: .portuguese) {
                
                addNewLine(eng: columns.en_us_line, ptbr: "REVIEW: \(ptbr.line)")
            } else {
                addNewLine(eng: columns.en_us_line, ptbr: "")
            }
        }
    }
}
