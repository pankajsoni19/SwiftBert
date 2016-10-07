//
//  BertDecoder.swift
//  wafer
//
//  Created by Pankaj Soni on 06/10/16.
//  Copyright © 2016 pankaj soni. All rights reserved.
//

import UIKit

class BertDecoder: Bert {
    
    private var decodeAtomAsString      = false
    private var decodePropListsAsMap    = false
    private var decodeMapKeysAsString   = false

    private var keys: NSMutableArray!
    private var ptr: UnsafePointer<UInt8>!
    private var position: Int = 0;
    
    func withDecodeAtomAsString(decodeAtomAsString : Bool) -> BertDecoder {
        self.decodeAtomAsString = decodeAtomAsString
        return self
    }
    
    func withDecodePropListsAsMap(decodePropListsAsMap : Bool)-> BertDecoder {
        self.decodePropListsAsMap = decodePropListsAsMap
        return self
    }
    
    func withDecodeMapKeysAsString(decodeMapKeysAsString : Bool) -> BertDecoder {
        self.decodeMapKeysAsString = decodeMapKeysAsString
        return self
    }
    
    func withDecodeBinaryAsStringForKey(key: NSObject) -> BertDecoder {
        if (keys == nil){
            keys = NSMutableArray()
        }
        keys.addObject(key)
        return self
    }
    
    func shouldDecodeBinaryAsStringForKey(key: NSObject) -> Bool {
        if (keys == nil) {
            return false
        }
        return (keys.indexOfObject(key) != NSNotFound)
    }
    
    func decodeBinaryToString(data: NSData) -> String! {
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
    
    func decodeAny(data: NSData) -> Any! {
        if data.length == 0 {
            return nil
        }
        
        ptr = UnsafePointer<UInt8>(data.bytes);
        position = 0
        
        if (ptr.memory == MAGIC){
            advancePtrBy(1)
            return decode()
        }

        return nil
    }
    
    private func decode() -> Any! {
        let type: UInt8 = ptr[0];
        advancePtrBy(1)
        
        switch type {
        case NIL_EXT:
            return nil
        case SMALL_INTEGER_EXT:
            return decodeByte()
        case INTEGER_EXT:
            return decodeInteger()
        case NEW_FLOAT_EXT:
            return decodeDouble()
        case SMALL_BIG_EXT:
            return decodeLongOrBigInteger(SMALL_BIG_EXT)
        case LARGE_BIG_EXT:
            return decodeLongOrBigInteger(LARGE_BIG_EXT)
        case ATOM_EXT:
            return decodeAtom(ATOM_EXT)
        case SMALL_ATOM_EXT:
            return decodeAtom(SMALL_ATOM_EXT)
        case STRING_EXT:
            return decodeString();
        case BINARY_EXT:
            return decodeBinary();
        case LIST_EXT:
            return decodeArray();
        case SMALL_TUPLE_EXT:
            return decodeTuple(SMALL_TUPLE_EXT);
        case LARGE_TUPLE_EXT:
            return decodeTuple(LARGE_TUPLE_EXT);
        case MAP_EXT:
            return decodeMap();
        default:
            print("Un decodable data received \(type)")
            return nil
        }
    }
    
    private func decodeByte() -> NSNumber! {
        let num = NSNumber(unsignedChar: ptr[0])
        advancePtrBy(sizeof(UInt8))
        return num
    }
    
    private func decodeShort() -> NSNumber! {
        let i = Int16(bigEndian: UnsafePointer<Int16>(ptr).memory)
        advancePtrBy(sizeof(Int16))
        return NSNumber(short: i)
    }
    
    private func decodeInteger() -> NSNumber! {
        let i = Int32(bigEndian: UnsafePointer<Int32>(ptr).memory)
        advancePtrBy(sizeof(Int32))
        return NSNumber(int: i)
    }
    
    func decodeDouble() -> Any! {
        let array = Array(UnsafeBufferPointer(start: ptr, count: sizeof(Double)).reverse())
        advancePtrBy(sizeof(Double))
        return fromByteArray(array, Double.self)
    }
    
    func decodeLongOrBigInteger(tag: UInt8) -> Any! {
        var byteCount: NSNumber!
        
        switch tag {
        case SMALL_BIG_EXT:
            byteCount = decodeByte()
        case LARGE_BIG_EXT:
            byteCount = decodeInteger()
        default:
            return nil
        }
        
        let isNegative: Bool = decodeByte() == 1
        var array = Array(UnsafeBufferPointer<UInt8>(start: ptr, count: byteCount.integerValue).reverse())
        let bytes = NSData(bytes: &array, length: byteCount.integerValue)
        advancePtrBy(byteCount.integerValue)
        return BigInt(abs: BigUInt(bytes), negative: isNegative)
    }
    
    func decodeAtom(tag: UInt8) -> Any! {
        var byteCount: NSNumber!
        
        switch tag {
        case ATOM_EXT:
            byteCount = decodeShort()
        case SMALL_ATOM_EXT:
            byteCount = decodeByte()
        default:
            return nil
        }
        
        var atom: String!
        
        if byteCount.integerValue > 0 {
            atom = decodeString(byteCount)
        }
        
        if (atom == nil || atom.isEmpty) {
            return nil
        }
        
        if atom == "true" {
            return true
        }
        else if atom == "false" {
            return false
        }
        else if (decodeAtomAsString) {
            return atom
        }
        else {
            return BertAtom(atom: atom)
        }
    }
    
    private func decodeString() -> String! {
        let byteCount = decodeShort()
        return decodeString(byteCount)
    }
    
    private func decodeBinary() -> Any! {
        let byteCount = decodeInteger()
        return decodeData(byteCount)
    }
    
    private func decodeArray() -> Any! {
        let numElements = decodeInteger().integerValue
        
        var canDecodeAsMap: Bool = decodePropListsAsMap
        
        let array: AnyObject = NSMutableArray()
        
        for _ in 0.stride(to: numElements, by: 1) {
            let decoded = decode()
            canDecodeAsMap =
                canDecodeAsMap &&
                (decoded is BertTuple) &&
                (decoded as! BertTuple).isKV()
            
            array.addObject(decoded as! AnyObject)
        }
        
        if decodeByte().unsignedCharValue != NIL_EXT {
            ptr.predecessor()
        }
        
        if (canDecodeAsMap){
            let dict = NSMutableDictionary()
            
            for tuple in array as! [BertTuple] {
                dict.setObject(tuple.objectAtIndex(1), forKey: tuple.objectAtIndex(1) as! NSCopying)
            }
        
            return dict
        }
        
        return array
    }
    
    private func decodeTuple(tag: UInt8) -> Any! {
        var numElements: NSNumber!
        
        switch tag {
        case SMALL_TUPLE_EXT:
            numElements = decodeByte()
        case LARGE_TUPLE_EXT:
            numElements = decodeInteger()
        default:
            return nil
        }
        
        let tuple = BertTuple()
        
        for _ in 0.stride(to: numElements.integerValue, by: 1) {
            tuple.addObject(decode() as! AnyObject)
        }

        return tuple
    }
    
    private func decodeMap() -> NSDictionary! {
        let numElements = decodeInteger().integerValue
        
        let dict = NSMutableDictionary()
        
        for _ in 0.stride(to: numElements, by: 1) {
            let key = decodeMapKey()
            let value = decodeMapValue(key)
            
            if (key == nil) {
                continue
            }
            
            dict.setObject(value as! AnyObject, forKey: key as! NSCopying)
        }
    
        return dict
    }
    
    private func decodeMapKey() -> Any! {
        let key = decode()
        
        if !decodeMapKeysAsString {
            return key
        }
        
        if key is String {
            return key
        }
        
        if key is BertAtom {
            return (key as! BertAtom).stringVal
        }
        
        if key is NSData {
            return String(data: key as! NSData, encoding: NSUTF8StringEncoding)
        }
        
        return String(key)
    }
    
    private func decodeMapValue(key: Any!) -> Any! {
        if (key == nil) {
            return nil
        }
        
        let value = decode()
        
        if shouldDecodeBinaryAsStringForKey(key as! NSObject) {
            return String(data: value as! NSData, encoding: NSUTF8StringEncoding)
        }
        
        return value
    }
    
    private func decodeString(byteCount: NSNumber) -> String! {
        let data = decodeData(byteCount)
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
    
    private func decodeData(byteCount: NSNumber) -> NSData! {
        let data = NSData(bytes: ptr, length: byteCount.integerValue)
        advancePtrBy(byteCount.integerValue)
        return data
    }
    
    private func advancePtrBy(n: Int){
        ptr = ptr.advancedBy(n)
        position += n
    }
    
    func fromByteArray<T>(value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBufferPointer {
            return UnsafePointer<T>($0.baseAddress).memory
        }
    }
}
