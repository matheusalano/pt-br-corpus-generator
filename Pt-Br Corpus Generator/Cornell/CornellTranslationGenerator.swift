//
//  CornellTranslationGenerator.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 09/11/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

final class CornellTranslationGenerator {
    
    private let service = TranslateAPI()
    private let rows: [String]
    
    init() {
        let url =  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("PUCRS/pt-br-corpus-generator/cornell-dataset.csv")
        
        guard let file = try? String(contentsOfFile: url.path, encoding: .utf8) else {
            fatalError("File not found.")
        }
        
        rows = file.components(separatedBy: "\n")
    }
    
    func start() {
        
        let corpusGenerator = CorpusGenerator(filename: "cornell-dataset-2.csv")
        
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
        var globalCharCount = 12232566
        
        for row in rows[index...] {
            guard let columns: ColumnFinal = Helper.splitCSVColumns(row: row) else {
                fatalError()
            }
            
            queuedRows.append(columns)
            
            let queuedLines = queuedRows.map({ $0.en_us_line })
            let charCount = queuedLines.map({ $0.count }).reduce(0, +)
            
            if queuedLines.count == 128 || (rows.last == row) {
                
                let result = service.translateLines(lines: queuedLines)
                
                switch result {
                case .success(let translations):
                    for i in translations.translations.indices {
                        queuedRows[i].pt_br_line = translations.translations[i].translatedText
                    }
                    
                    queuedRows.forEach({ (column) in
                        addNewLine(column: column)
                    })
                    queuedRows = []
                    globalCharCount += charCount
                    print("### 🤩🤩🤩 TRANSLATED: \(charCount) characters -- TOTAL: \(globalCharCount) characters ###")
                    sleep(2)
                    
                case .failure(let error):
                    print("### 😭😭😭 ERROR: \(error.localizedDescription) ###")
                    fatalError()
                }
            }
        }
    }
}
