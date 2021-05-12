//
//  BertAtom.swift
//
//  Created by Pankaj Soni on 06/10/16.
//  Copyright © 2017-2021 pankaj soni. All rights reserved.
//

public class BertAtom {
    
    private let ATOM_EXT_MAX_LEN : Int = 255
    private var atom : String? = nil
    
    required public init(atom: String) {
        if atom.isEmpty {
            print("ERROR: Atom can't be empty")
        }
        else if atom.count > ATOM_EXT_MAX_LEN {
            print("ERROR: Atom max length can be only \(ATOM_EXT_MAX_LEN)")
        }
        else {
            self.atom = atom
        }
    }
    
    public func stringVal() -> String {
        if let atom = atom, !atom.isEmpty{
            return atom
        }
        
        return ""
    }
    
    public var description: String {
        let atom = stringVal()
        return "BertAtom (\(atom))"
    }
}
