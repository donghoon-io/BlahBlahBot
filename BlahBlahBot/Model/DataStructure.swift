//
//  DataStructure.swift
//  BlahBlahBot
//
//  Created by Donghoon Shin on 2020/12/18.
//

import Foundation

var experimentID: String {
    get {
        return UserDefaults.standard.string(forKey: "experimentID") ?? ""
    } set {
        UserDefaults.standard.set(newValue, forKey: "experimentID")
        UserDefaults.standard.synchronize()
    }
}
