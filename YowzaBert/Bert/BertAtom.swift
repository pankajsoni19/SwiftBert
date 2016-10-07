//
//  BertAtom.swift
//  wafer
//
//  Created by Pankaj Soni on 06/10/16.
//  Copyright © 2016 pankaj soni. All rights reserved.
//

import UIKit

class BertAtom: NSObject, NSCopying {
    
    private let ATOM_EXT_MAX_LEN : Int = 255
    private var atom : String? = nil
    
    required init(atom: String) {
        if(atom.isEmpty == true) {
            print("Atom can't be empty")
        }
        else if atom.characters.count > ATOM_EXT_MAX_LEN {
            print("Atom max length can be only \(ATOM_EXT_MAX_LEN)")
        }
        else {
            self.atom = atom
        }
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return BertAtom(atom: self.atom!)
    }
    
    func stringVal() -> String {
        if(atom?.isEmpty == true) {
            return ""
        }
        return atom!
    }
    
    override var description: String{
        return "BertAtom (\(atom!))"
    }
}
