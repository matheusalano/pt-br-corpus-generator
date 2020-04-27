//
//  main.swift
//  Pt-Br Corpus Generator
//
//  Created by Matheus Alano on 05/07/19.
//  Copyright © 2019 Matheus Alano. All rights reserved.
//

import Foundation

print("Options:\n1 - Friends\n2 - Cornell\n")
print("Enter the option: ")
var option = readLine()
while option != "1" && option != "2" {
    print("Enter the option: ")
    option = readLine()
}

if option == "1" {
    let friends = Friends()
    friends.start()
} else if option == "2" {
    let cornell = Cornell()
    cornell.start()
}
