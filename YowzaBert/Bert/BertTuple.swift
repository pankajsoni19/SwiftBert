//
//  BertTuple.swift
//  wafer
//
//  Created by Pankaj Soni on 06/10/16.
//  Copyright © 2016 pankaj soni. All rights reserved.
//

import UIKit

class BertTuple: NSObject, NSCopying {
    
    var array: NSMutableArray!
    
    override init(){
        array = NSMutableArray()
    }
    
    init(array: NSMutableArray) {
       self.array = array
    }
    
    func count() -> Int {
        return array.count
    }
    
    func isKV () -> Bool{
        return (array.count == 2)
    }
    
    func objectAtIndex(index: Int) -> AnyObject {
        return array.objectAtIndex(index)
    }
    
    func addObject(any: AnyObject) {
        array.addObject(any)
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return BertTuple(array: self.array.copyWithZone(zone) as! NSMutableArray)
    }
    
    override var description: String{
        return "BertTuple (\(array!))"
    }
}


