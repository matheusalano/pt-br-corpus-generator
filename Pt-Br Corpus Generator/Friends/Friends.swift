//
//  Friends.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 07/11/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

final class Friends {
    
    func start() {

        let url =  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("PUCRS/pt-br-corpus-generator/Dataset/friends-original.csv")

        guard let file = try? String(contentsOfFile: url.path, encoding: .utf8) else {
            fatalError("File not found.")
        }

        let corpusGenerator = CorpusGenerator()
        let rows: [String] = file.components(separatedBy: "\n")

        let index: Int
        if let idx = corpusGenerator.getLastIndex() {
            index = idx + 1
        } else {
            index = 2
        }

        if index >= rows.count {
            print("\nOptions: \n1 - Translate Validation\n2 - Review Validation\n")
            print("Enter the option: ")
            let option = readLine() ?? ""
            
            if option == "1" {
                let translateValidation = FriendsTranslateValidation()
                translateValidation.start()
            } else if option == "2" {
                let reviewValidation = FriendsReviewValidation()
                reviewValidation.start()
            }
        } else {
            let subtitleParser = FriendsSubtitleParser()
            var hits = 0
            var misses = 0

            print("### Starting at index \(index) ###")

            rows[index...].forEach { (row) in
                guard let columns: ColumnOriginal = Helper.splitCSVColumns(row: row) else {
                    fatalError()
                }
                
                if
                    let english = subtitleParser.getSubtitle(from: columns.line, filename: columns.filename, language: .english),
                    let ptbr = subtitleParser.getSubtitle(from: english, filename: columns.filename, language: .portuguese) {
                    
                    corpusGenerator.addNewLine(id: columns.id,
                                               scene_id: columns.scene_id,
                                               person: columns.person,
                                               en_us_line: english.line,
                                               pt_br_line: ptbr.line,
                                               filename: columns.filename)
                    hits += 1
                } else {
                    
                    corpusGenerator.addNewLine(id: columns.id,
                                               scene_id: columns.scene_id,
                                               person: columns.person,
                                               en_us_line: columns.line,
                                               pt_br_line: "",
                                               filename: columns.filename)
                    misses += 1
                }
            }

            print("TOTAL: \(hits + misses)")
            print("HITS: \(hits)")
            print("MISSES: \(misses)")
        }
    }
}
