//
//  FriendsSubtitleParser.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 05/07/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

fileprivate struct Constants {
    static let datasetPath = "PUCRS/pt-br-corpus-generator/Dataset/"
    static let englishFolder = "\(datasetPath)FRIENDS-en-us/"
    static let portugueseFolder = "\(datasetPath)FRIENDS-pt-br/"
}

struct Subtitle {
    struct Time {
        let beginTime: Int
        let endTime: Int
    }
    
    let id: Int
    var times: [Time]
    let line: String
}

enum Language {
    case english, portuguese
}

final class FriendsSubtitleParser {
    
    private let fileManager = FileManager.default
    private var englishSubtitles: [String: [Subtitle]] = [:]
    private var portugueseSubtitles: [String: [Subtitle]] = [:]
    
    var range = 300
    var similarityAcceptance = 0.25
    
    func preLoadSubtitles(files: [String], language: Language) {
        for file in files {
            guard (language == .english ? englishSubtitles : portugueseSubtitles)[file] == nil else { continue }
            
            let season = String(file.prefix(2))
            let newFileName = file.replacingOccurrences(of: ".txt", with: ".srt")
            var path = "\(language == .english ? Constants.englishFolder : Constants.portugueseFolder)\(season)/\(newFileName)"
            path = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(path).path
            
            let subtitles = parseSubtitles(from: path.trimmingCharacters(in: .whitespacesAndNewlines), language: language)
            if language == .english { englishSubtitles[file] = subtitles } else { portugueseSubtitles[file] = subtitles }
        }
    }
    
    /**
     It finds the subtitle whose line is the most similar with the line passed by parameter.
     
     - returns:
     The subtitle whose line is the most similar with the line.
     
     - parameters:
        - line: The string used to find the most similar subtitle.
        - filename: The name of the file where the subtitle is stored.
        - language: The language to define which file must be used. Portuguese or English.
     */
    func getSubtitle(from line: String, filename: String, language: Language) -> Subtitle? {
        var subtitles: [Subtitle]
        
        if let subs = (language == .english ? englishSubtitles : portugueseSubtitles)[filename] {
            subtitles = subs
        } else {
            let season = String(filename.prefix(2))
            let newFileName = filename.replacingOccurrences(of: ".txt", with: ".srt")
            var path = "\(language == .english ? Constants.englishFolder : Constants.portugueseFolder)\(season)/\(newFileName)"
            path = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(path).path
            
            subtitles = parseSubtitles(from: path.trimmingCharacters(in: .whitespacesAndNewlines), language: language)
            if language == .english { englishSubtitles[filename] = subtitles } else { portugueseSubtitles[filename] = subtitles }
        }
        
        return getMostSimilarSubtitle(from: subtitles, line: line)
    }
    
    /**
     It finds the subtitle whose times is the most similar with the subitle's times passed by parameter.
     
     - returns:
     The subtitle whose times is the most similar with the subitle's times.
     
     - parameters:
        - subtitle: The subtitle used to find the most similar subtitle.
        - filename: The name of the file where the subtitle is stored.
        - language: The language to define which file must be used. Portuguese or English.
     */
    func getSubtitle(from subtitle: Subtitle, filename: String, language: Language) -> Subtitle? {
        var subtitles: [Subtitle]
        
        if let subs = (language == .english ? englishSubtitles : portugueseSubtitles)[filename] {
            subtitles = subs
        } else {
            let season = String(filename.prefix(2))
            let newFileName = filename.replacingOccurrences(of: ".txt", with: ".srt")
            var path = "\(language == .english ? Constants.englishFolder : Constants.portugueseFolder)\(season)/\(newFileName)"
            path = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(path).path
            
            subtitles = parseSubtitles(from: path.trimmingCharacters(in: .whitespacesAndNewlines), language: language)
            if language == .english { englishSubtitles[filename] = subtitles } else { portugueseSubtitles[filename] = subtitles }
        }
        
        if subtitle.times.count == 1 {
            if let eqv = subtitles.first(where: {
                (subtitle.times[0].beginTime - range)...(subtitle.times[0].beginTime + range) ~= $0.times[0].beginTime &&
                    (subtitle.times[0].endTime - range)...(subtitle.times[0].endTime + range) ~= $0.times[0].endTime }) {
                
                return eqv
            /*} else if let eqv = subtitles.first(where: {
                (subtitle.times[0].beginTime - range)...(subtitle.times[0].beginTime + range) ~= $0.times[0].beginTime ||
                    (subtitle.times[0].endTime - range)...(subtitle.times[0].endTime + range) ~= $0.times[0].endTime }) {
                
                return eqv */
            } else {
                return nil
            }
        } else {
            var newLines: [String] = []
            let maxMisses = Int(round(Double(subtitle.times.count) * 0.3))
            var misses = 0
            
            searchTimes: for time in subtitle.times {
                if let eqv = subtitles.first(where: {
                    (time.beginTime - range)...(time.beginTime + range) ~= $0.times[0].beginTime &&
                    (time.endTime - range)...(time.endTime + range) ~= $0.times[0].endTime &&
                    !newLines.contains($0.line) }) {
                    
                    newLines.append(eqv.line)
                } else if let eqv = subtitles.first(where: {
                    (time.beginTime - range)...(time.beginTime + range) ~= $0.times[0].beginTime ||
                    (time.endTime - range)...(time.endTime + range) ~= $0.times[0].endTime &&
                    !newLines.contains($0.line) }) {
                    
                    if misses > maxMisses { break searchTimes }
                    misses += 1
                    newLines.append(eqv.line)
                } else {
                    newLines.removeAll()
                    break searchTimes
                }
            }
            if newLines.isEmpty { return nil }
            let newLine = newLines.joined(separator: " ")
            
            return Subtitle(id: subtitle.id, times: subtitle.times, line: newLine)
        }
    }
    
    /**
     It parses the file converting it to a list of subtitles.
     
     - returns:
     The subtitles found at the file specified.
     
     - parameters:
        - path: The path where the file should be found.
        - language: The language to define which file must be used. Portuguese or English.
     */
    private func parseSubtitles(from path: String, language: Language) -> [Subtitle] {
        guard let contentsOfFile = (try? String(contentsOfFile: path, encoding: .utf8)) ?? (try? String(contentsOfFile: path, encoding: .isoLatin1)) else {
            print("### Couldn't find file from path: \(path) ###")
            exit(1)
        }
        
        var subtitles: [Subtitle] = []
        
        var contents = contentsOfFile.components(separatedBy: "\r\n\r\n")
        
        let separator = (contents.count <= 1) ? "\n" : "\r\n"
        if contents.count <= 1 { contents = contentsOfFile.components(separatedBy: "\n\n") }
        
        contents.forEach({
            if !$0.isEmpty {
                var components = $0.components(separatedBy: separator)
                let id = Int(components[0])!
                let times = components[1].components(separatedBy: " --> ")
                let lines = components[2...].map({ lineCleaning(line: $0, language: language) })
                let line = lines.joined(separator: " ")
                
                if line.isEmpty { return }
                
                var subtitle = Subtitle(id: id, times: [], line: line)
                subtitle.times.append(Subtitle.Time(beginTime: times[0].milliseconds(), endTime: times[1].milliseconds()))
                subtitles.append(subtitle)
            }
        })
        
        if language == .english {
            subtitles = mergeSubtitlesIfNeeded(subtitles)
        }
        
        return subtitles
    }
    
    /**
     It may find the most similar subtitle from a subtitle list. It uses the Levenshtein algorithm to compare the lines.
     
     - returns:
     The subtitle whose line is the most similar with the line passed by parameter.
     
     - parameters:
        - subtitles: The subtitles where the chosen subtitle must be found.
        - line: The line used to find the most similar subtitle.
     */
    private func getMostSimilarSubtitle(from subtitles: [Subtitle], line: String) -> Subtitle? {
        let levenshteinValues = subtitles.map({ line.levenshtein($0.line) })
        var index = -1
        for i in levenshteinValues.indices {
            if Double(levenshteinValues[i]) < (Double(line.count) * similarityAcceptance) {
                if index != -1 {
                    index = (levenshteinValues[index] < levenshteinValues[i]) ? index : i
                } else {
                    index = i
                }
            }
        }
        
        if index != -1 {
            
            return subtitles[index]
        } else if let sub = findSubtitlesFromPrefix(subtitles: subtitles, line: line) {
            
            return sub
        } else if let sub = findSubtitlesFromSuffix(subtitles: subtitles, line: line) {
            
            return sub
        } else if let subIdx = subtitles.firstIndex(where: { line.contains($0.line) }) {
            
            return findSubtitlesContainedInLine(subIdx, subtitles: subtitles, line: line)
        } else {
            
            return nil
        }
    }
    
    /**
     It may find the most similar subtitle from a subtitle list. It starts from the subtitle whose line is a prefix of the line passed by parameter.
     It concatenates the subtitles until their lines is almost equal to the parameter line.
     
     - returns:
     The subtitle whose line is the most similar with the line passed by parameter.
     
     - parameters:
        - subtitles: The subtitles where the chosen subtitle must be found.
        - line: The line used to find the most similar subtitle.
     */
    private func findSubtitlesFromPrefix(subtitles: [Subtitle], line: String) -> Subtitle? {
        guard let index = subtitles.firstIndex(where: { line.hasPrefix($0.line) }), index < (subtitles.count - 1) else { return nil }
        
        var subs = [subtitles[index]]
        var currLine = subs[0].line
        var currLevenshtein = line.levenshtein(currLine)
        for i in (index + 1)...(subtitles.count - 1) {
            let newLevenshtein = line.levenshtein(currLine + subtitles[i].line)
            if Double(newLevenshtein) < Double(line.count) * similarityAcceptance {
                subs.append(subtitles[i])
                return Subtitle(id: subs.last!.id, times: subs.map({ $0.times }).flatMap({ $0 }), line: currLine + subtitles[i].line)
            } else if newLevenshtein < currLevenshtein {
                currLine = currLine + subtitles[i].line
                currLevenshtein = newLevenshtein
                subs.append(subtitles[i])
            } else {
                return nil
            }
        }
        return nil
    }
    
    /**
     It may find the most similar subtitle from a subtitle list. It searchs the line backwards from the subtitle whose line is a suffix of the line passed by parameter.
     It concatenates the subtitles until their lines is almost equal to the parameter line.
     
     - returns:
     The subtitle whose line is the most similar with the line passed by parameter.
     
     - parameters:
        - subtitles: The subtitles where the chosen subtitle must be found.
        - line: The line used to find the most similar subtitle.
     */
    private func findSubtitlesFromSuffix(subtitles: [Subtitle], line: String) -> Subtitle? {
        guard let index = subtitles.firstIndex(where: { line.hasSuffix($0.line) }), index > 1 else { return nil }
        
        var subs = [subtitles[index]]
        var currLine = subs[0].line
        var currLevenshtein = line.levenshtein(currLine)
        for i in (0...(index - 1)).reversed() {
            let newLevenshtein = line.levenshtein(subtitles[i].line + currLine)
            if Double(newLevenshtein) < Double(line.count) * similarityAcceptance {
                subs.insert(subtitles[i], at: 0)
                return Subtitle(id: subs.last!.id, times: subs.map({ $0.times }).flatMap({ $0 }), line: subtitles[i].line + currLine)
            } else if newLevenshtein < currLevenshtein {
                currLine = subtitles[i].line + currLine
                currLevenshtein = newLevenshtein
                subs.insert(subtitles[i], at: 0)
            } else {
                return nil
            }
        }
        return nil
    }
    
    private func findSubtitlesContainedInLine(_ index: Int, subtitles: [Subtitle], line: String) -> Subtitle? {
        guard index > 1 && index < (subtitles.count - 1) else { return nil }
        
        var subs = [subtitles[index]]
        var currLine = subs[0].line
        var currLevenshtein = line.levenshtein(currLine)
        
        for i in (index + 1)...(subtitles.count - 1) {
            let newLevenshtein = line.levenshtein(currLine + subtitles[i].line)
            if Double(newLevenshtein) < Double(line.count) * similarityAcceptance {
                currLine = currLine + subtitles[i].line
                currLevenshtein = newLevenshtein
                subs.append(subtitles[i])
                if line.levenshtein(subtitles[index - 1].line + currLine) < currLevenshtein {
                    break
                } else {
                    return Subtitle(id: subs.last!.id, times: subs.map({ $0.times }).flatMap({ $0 }), line: currLine)
                }
            } else if newLevenshtein < currLevenshtein {
                currLine = currLine + subtitles[i].line
                currLevenshtein = newLevenshtein
                subs.append(subtitles[i])
            } else {
                break
            }
        }
        
        for i in (0...(index - 1)).reversed() {
            let newLevenshtein = line.levenshtein(subtitles[i].line + currLine)
            if Double(newLevenshtein) < Double(line.count) * similarityAcceptance {
                subs.insert(subtitles[i], at: 0)
                return Subtitle(id: subs.last!.id, times: subs.map({ $0.times }).flatMap({ $0 }), line: subtitles[i].line + currLine)
            } else if newLevenshtein < currLevenshtein {
                currLine = subtitles[i].line + currLine
                currLevenshtein = newLevenshtein
                subs.insert(subtitles[i], at: 0)
            } else {
                break
            }
        }
        
        return nil
    }
    
    private func lineCleaning(line: String, language: Language) -> String {
        var newLine = line.replacingOccurrences(of: "- ", with: "")
        newLine = newLine.replacingOccurrences(of: #"(.+: )|(\[.+\])"#, with: "", options: .regularExpression)
        newLine = newLine.replacingOccurrences(of: "<i>", with: "")
        newLine = newLine.replacingOccurrences(of: "</i>", with: "")
        
        if language == .portuguese {
            newLine = newLine.replacingOccurrences(of: "...", with: "")
        }
        
        return newLine
    }
    
    private func mergeSubtitlesIfNeeded(_ subtitles: [Subtitle]) -> [Subtitle] {
        var newSubtitles: [Subtitle] = []
        
        var index = 0
        for i in subtitles.indices {
            if i < index { continue }
            
            if (subtitles.count > i + 1) && subtitles[i].line.hasSuffix("...") && subtitles[i + 1].line.hasPrefix("...") {
                let newLine = subtitles[i].line.replacingOccurrences(of: "...", with: "") + " " + subtitles[i + 1].line.replacingOccurrences(of: "...", with: "")
                var newSubtitle = Subtitle(id: subtitles[i].id, times: [], line: newLine)
                newSubtitle.times.append(subtitles[i].times[0])
                newSubtitle.times.append(subtitles[i + 1].times[0])
                newSubtitles.append(newSubtitle)
                index = i + 2
            } else {
                newSubtitles.append(subtitles[i])
                index = i
            }
        }
        
        return newSubtitles
    }
}
