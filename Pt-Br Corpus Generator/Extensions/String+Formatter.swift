//
//  String+Formatter.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 24/07/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

extension String {
    
    private static var formatter = DateFormatter()
    
    func milliseconds(with format: String = "HH:mm:ss,SSS") -> Int {
        String.formatter.dateFormat = "HH:mm:ss,SSS"
        
        let calendar = Calendar.current
        
        let dt = calendar.dateComponents(in: .current, from: String.formatter.date(from: self)!)
        
        let second = (dt.minute! * 60) + dt.second!
        let milissecond = (second * 1000) + (dt.nanosecond! / 1000000)
        
        return milissecond
    }
}
