//
//  File.swift
//  UberClone
//
//  Created by Treinamento on 10/14/19.
//  Copyright © 2019 JCAS. All rights reserved.
//

import Foundation

class teste {
    var a: Int?
    
    init(a: Int) {
        let aA = a
        print(aA)
    }
}

class aplicacao {
    let b: teste? = teste(a: 10)
}
