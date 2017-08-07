//
//  DistributionHeader.swift
//  wafer
//
//  Created by Pankaj Soni on 06/10/16.
//  Copyright © 2016 pankaj soni. All rights reserved.
//

import UIKit

public class DistributionHeader {
    
    var MAGIC                       :UInt8      = 131
    var NIL_EXT                     :UInt8      = 106
    
    var SMALL_INTEGER_EXT_MIN_VAL   :Int        = 0
    var SMALL_INTEGER_EXT_MAX_VAL   :Int        = 255
    
    var INTEGER_EXT_MIN_VAL         :Int        = Int(Int32.min)
    var INTEGER_EXT_MAX_VAL         :Int        = Int(Int32.max)
    
    var SMALL_INTEGER_EXT           :UInt8      = 97                      //DND: byte
    var INTEGER_EXT                 :UInt8      = 98
    
    var FLOAT_LENGTH                :Int32       = 31
    
    var FLOAT_EXT                   :UInt8      = 99
    var NEW_FLOAT_EXT               :UInt8      = 70
    
    var SMALL_BIG_EXT               :UInt8      = 110
    var LARGE_BIG_EXT               :UInt8      = 111
    
    var ATOM_EXT                    :UInt8      = 100                     //DND: max len: 255
    var SMALL_ATOM_EXT              :UInt8      = 115
    
    var STRING_EXT_MAX_VAL          :Int        = 65535
    
    var STRING_EXT                  :UInt8      = 107                    //DND: max size: 65535
    var LIST_EXT                    :UInt8      = 108
    
    var BINARY_EXT                  :UInt8      = 109
    
    var SMALL_TUPLE_EXT             :UInt8      = 104
    var LARGE_TUPLE_EXT             :UInt8      = 105
    
    var MAP_EXT                     :UInt8      = 116
}
