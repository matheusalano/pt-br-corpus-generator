//
//  Cornell.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 08/11/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

private struct Turn {
    let id: Int
    let sceneId: Int
    let character: String
    let line: String
}

private struct Line {
    let character: String
    let text: String
}

final class Cornell {
    
    func start() {
        
        print("\nOptions: \n1 - Generate Dataset\n2 - Generate Translation\n")
        print("Enter the option: ")
        let option = readLine() ?? ""
        
        if option == "1" {
            let conversations = getConversations()
            let corpusGenerator = CorpusGenerator(filename: "cornell-dataset.csv")
            
            for conv in conversations {
                corpusGenerator.addNewLine(id: "\(conv.id)",
                                           scene_id: "\(conv.sceneId)",
                                           person: conv.character,
                                           en_us_line: conv.line.replacingOccurrences(of: "\"", with: ""),
                                           pt_br_line: "",
                                           filename: "-")
            }
        } else if option == "2" {
            let translation = CornellTranslationGenerator()
            translation.start()
        }
    }
    
    private func getLines() -> [String: Line] {
        let url =  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("PUCRS/pt-br-corpus-generator/Dataset/cornell/movie_lines.txt")
        
        guard let file = try? String(contentsOfFile: url.path, encoding: .ascii) else {
            fatalError("File not found.")
        }
        
        let rows: [String] = file.components(separatedBy: "\n")
        var lines: [String: Line] = [:]
        
        for row in rows {
            guard row.count > 0 else { continue }
            let parts = row.replacingOccurrences(of: "\n", with: "").components(separatedBy: " +++$+++ ")
            lines[parts[0]] = Line(character: parts[3], text: parts[4])
        }
        
        return lines
    }
    
    private func getConversations() -> [Turn] {
        let url =  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("PUCRS/pt-br-corpus-generator/Dataset/cornell/movie_conversations.txt")
        
        guard let file = try? String(contentsOfFile: url.path, encoding: .ascii) else {
            fatalError("File not found.")
        }
        
        let rows: [String] = file.components(separatedBy: "\n")
        let lines = getLines()
        
        var turns: [Turn] = []
        var id = 0
        var sceneId = 0
        
        for row in rows {
            guard row.count > 0 else { continue }
            let parts = row.replacingOccurrences(of: "\n", with: "").components(separatedBy: " +++$+++ ")
            var lineIds = parts[3]
            lineIds.removeAll(where: { [" ", "'", "[", "]"].contains($0) })
            guard lineIds.components(separatedBy: ",").map({ lines[$0]!.text }).contains("") == false else { continue }
            sceneId += 1
            for lineId in lineIds.components(separatedBy: ",") {
                id += 1
                let line = lines[lineId]!
                turns.append(Turn(id: id, sceneId: sceneId, character: line.character, line: line.text))
            }
        }
        
        return turns
    }
}
