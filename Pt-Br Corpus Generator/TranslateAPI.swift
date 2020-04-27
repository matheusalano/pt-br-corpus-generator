//
//  TranslateAPI.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 09/08/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

struct TranslatedTexts: Decodable {
    struct TranslatedText: Decodable {
        let translatedText: String
    }
    
    let translations: [TranslatedText]
}

final class TranslateAPI {
    
    private let session = URLSession.shared
    private let stringUrl = "https://translation.googleapis.com/v3/projects/bilingual-chatbot:translateText"
    private var authentication: String = ""
    
    init() {
        updateAuthentication()
    }
    
    func translateLines(lines: [String]) -> Result<TranslatedTexts, Error> {
        return translateLines(retry: 0, lines: lines)
    }
    
    private func translateLines(retry: Int, lines: [String]) -> Result<TranslatedTexts, Error> {
        guard let url = URL(string: stringUrl) else {
            return .failure(NSError(domain: "Error: cannot create URL", code: 10))
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = getHeaderFields()
        urlRequest.httpBody = getHttpBody(contents: lines)
        
        print("### 🚀🚀🚀 REQUEST BODY: \(String(data: urlRequest.httpBody!, encoding: .utf8) ?? "") ###")
        
        let (data, response, error) = session.synchronousDataTask(with: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            updateAuthentication()
            return translateLines(retry: retry, lines: lines)
        }
        
        guard error == nil else {
            print("### 🤦‍♀️🤦‍♀️🤦‍♀️ RESPONSE ERROR: \(error!.localizedDescription) ###")
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                sleep(300)
                return translateLines(retry: retry, lines: lines)
            }
            
            return (retry < 3) ? translateLines(retry: retry + 1, lines: lines) : .failure(error!)
        }
        guard let responseData = data else {
            return (retry < 3) ? translateLines(retry: retry + 1, lines: lines) : .failure(NSError(domain: "Error: did not receive data", code: 10))
        }
        
        print("### 💁‍♀️💁‍♀️💁‍♀️ RESPONSE BODY: \(String(data: responseData, encoding: .utf8) ?? "") ###")
        
        do {
            let translation = try JSONDecoder().decode(TranslatedTexts.self, from: responseData)
            return .success(translation)
        } catch let error {
            return .failure(error)
        }
    }
    
    private func getHeaderFields() -> [String:String] {
        
        return [
            "Content-Type": "application/json",
            "Accept-Charset": "utf-8",
            "Authorization": "Bearer \(authentication)"
        ]
    }
    
    private func getHttpBody(contents: [String]) -> Data? {
        let data: [String: Any] = [
            "sourceLanguageCode": "en",
            "targetLanguageCode": "pt",
            "contents": contents
        ]
        
        return try? JSONSerialization.data(withJSONObject: data, options: [])
    }
    
    private func updateAuthentication() {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["--login", "-c", "/Users/matheusalano/PUCRS/pt-br-corpus-generator/GoogleScript"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        authentication = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

extension URLSession {
    func synchronousDataTask(with url: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: url) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}
