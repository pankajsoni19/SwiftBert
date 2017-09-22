//
//  Bert.swift
//  wafer
//
//  Created by Pankaj Soni on 06/10/16.
//  Copyright © 2017 pankaj soni. All rights reserved.
//
import Foundation

public class Bert: DistributionHeader {
    
    public override init() { }
    
    func isFraction(num: NSNumber) -> Bool {
        let dValue = num.doubleValue
        if (dValue < 0.0) {
            return (dValue != ceil(dValue));
        } else {
            return (dValue != floor(dValue));
        }
    }
}
