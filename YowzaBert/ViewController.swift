//
//  ViewController.swift
//  YowzaBert
//
//  Created by Pankaj Soni on 04/10/16.
//  Copyright © 2016 Pankaj Soni. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let x = BertTuple()
        x.addObject("asd")
        x.addObject("asdasd")
        x.addObject("asdadsads")
        let dict = NSMutableDictionary()
        dict.setObject(x, forKey: "asd")
        
        //x.addObject("asd")
        NSLog("value: \(dict)")
        
        let encoder = BertEncoder()
            .withEncodeStringAsBinary(true)
            .withEncodeMapKeysAsAtom(true)
            //.withEncodeMapAsPropList(true)
        
        let encoded: NSData = encoder.encodeAny(dict)
        NSLog("encoded \(encoded)")
        
        let decoder = BertDecoder().withDecodeAtomAsString(true)
        
        let decoded =
            decoder.decodeAny(encoded)
        
        NSLog("decoded \(decoded)")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

