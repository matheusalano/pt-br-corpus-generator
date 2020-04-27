//
//  FriendsTranslateValidation.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 10/08/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

final class FriendsTranslateValidation {
    
    private let service = TranslateAPI()
    private let rows: [String]
    
    init() {
        let url =  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("PUCRS/pt-br-corpus-generator/friends-final.csv")
        
        guard let file = try? String(contentsOfFile: url.path, encoding: .utf8) else {
            fatalError("File not found.")
        }
        
        rows = file.components(separatedBy: "\n")
    }
    
    func start() {
        
        let corpusGenerator = CorpusGenerator(filename: "friends-final-2.csv")
        let subtitleParser = FriendsSubtitleParser()
        
        func addNewLine(column: ColumnFinal) {
            corpusGenerator.addNewLine(id: column.id,
                                       scene_id: column.scene_id,
                                       person: column.person,
                                       en_us_line: column.en_us_line,
                                       pt_br_line: column.pt_br_line,
                                       filename: column.filename)
        }
        
        let index = corpusGenerator.getLastIndex() ?? 1
        
        print("### Starting at index \(index) ###")
        
        var queuedRows: [ColumnFinal] = []
        var globalCharCount = 1905943
        
        for row in rows[index...] {
            guard let columns: ColumnFinal = Helper.splitCSVColumns(row: row) else {
                fatalError()
            }
            
            guard columns.pt_br_line == "" else {
                if queuedRows.isEmpty {
                    addNewLine(column: columns)
                } else {
                    queuedRows.append(columns)
                }
                continue
            }
            
            queuedRows.append(columns)
            
            var onlyEnglishLines = queuedRows.filter({ $0.pt_br_line == "" })
            let queuedLines = onlyEnglishLines.map({ $0.en_us_line })
            let charCount = queuedLines.map({ $0.count }).reduce(0, +)
            
            if queuedLines.count == 128 || (rows.last == row) {
                
                let result = service.translateLines(lines: queuedLines)
                
                switch result {
                case .success(let translations):
                    for i in translations.translations.indices {
                        onlyEnglishLines[i].pt_br_line = translations.translations[i].translatedText
                    }
                    
                    subtitleParser.preLoadSubtitles(files: onlyEnglishLines.map({ $0.filename }), language: .portuguese)
                    
                    onlyEnglishLines = onlyEnglishLines.concurrentMap({ column in
                        var newCol = column
                        if let sub = subtitleParser.getSubtitle(from: column.pt_br_line, filename: column.filename, language: .portuguese) {
                            newCol.pt_br_line = "SUB-TRANS: \(sub.line)"
                        } else {
                            newCol.pt_br_line = "ONLY-TRANS: \(column.pt_br_line)"
                        }
                        return newCol
                    })
                    
                    queuedRows.forEach({ (column) in
                        if let x = onlyEnglishLines.first(where: { $0.id == column.id }) {
                            addNewLine(column: x)
                        } else {
                            addNewLine(column: column)
                        }
                    })
                    queuedRows = []
                    globalCharCount += charCount
                    print("### 🤩🤩🤩 TRANSLATED: \(charCount) characters -- TOTAL: \(globalCharCount) characters ###")
                    
                case .failure(let error):
                    print("### 😭😭😭 ERROR: \(error.localizedDescription) ###")
                    fatalError()
                }        
            }
        }
    }
}
