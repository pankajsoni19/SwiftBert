//
//  BertDecoder.swift
//  wafer
//
//  Created by Pankaj Soni on 06/10/16.
//  Copyright © 2017 pankaj soni. All rights reserved.
//

import BigInt
import BigInt.Swift

public class BertDecoder: Bert {
    
    private var decodeAtomAsString      = false
    private var decodePropListsAsMap    = false
    private var decodeMapKeysAsString   = false

    private var keys: NSMutableArray!
    private var ptr: UnsafePointer<UInt8>!
    
    public func withDecodeAtomAsString(decodeAtomAsString : Bool) -> BertDecoder {
        self.decodeAtomAsString = decodeAtomAsString
        return self
    }
    
    public func withDecodePropListsAsMap(decodePropListsAsMap : Bool)-> BertDecoder {
        self.decodePropListsAsMap = decodePropListsAsMap
        return self
    }
    
    public func withDecodeMapKeysAsString(decodeMapKeysAsString : Bool) -> BertDecoder {
        self.decodeMapKeysAsString = decodeMapKeysAsString
        return self
    }
    
    public func withDecodeBinaryAsStringForKey(key: NSObject) -> BertDecoder {
        if (keys == nil){
            keys = NSMutableArray()
        }
        keys.add(key)
        return self
    }
    
    public func shouldDecodeBinaryAsStringForKey(key: NSObject) -> Bool {
        if (keys == nil) {
            return false
        }
        return (keys.index(of: key) != NSNotFound)
    }
    
    public func decodeAny(data: Data) -> Any? {
        if data.count == 0 {
            return nil
        }
                
        data.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
            ptr = u8Ptr
        }
                
        if (ptr.pointee == MAGIC){
            advancePtrBy(n: 1)
            let result = decode()
            ptr = nil
            return result
        }

        return nil
    }
    
    private func decode() -> Any? {
        let type: UInt8 = ptr[0];
        advancePtrBy(n: 1)
        
        switch type {
        case NIL_EXT:
            return [Any]()
        case SMALL_INTEGER_EXT:
            return decodeByte()
        case INTEGER_EXT:
            return decodeInteger()
        case NEW_FLOAT_EXT:
            return decodeDouble()
        case SMALL_BIG_EXT:
            return decodeLongOrBigInteger(tag: SMALL_BIG_EXT)
        case LARGE_BIG_EXT:
            return decodeLongOrBigInteger(tag: LARGE_BIG_EXT)
        case ATOM_EXT:
            return decodeAtom(tag: ATOM_EXT)
        case SMALL_ATOM_EXT:
            return decodeAtom(tag: SMALL_ATOM_EXT)
        case STRING_EXT:
            return decodeString()
        case BINARY_EXT:
            return decodeBinary()
        case LIST_EXT:
            return decodeArray()
        case SMALL_TUPLE_EXT:
            return decodeTuple(tag: SMALL_TUPLE_EXT)
        case LARGE_TUPLE_EXT:
            return decodeTuple(tag: LARGE_TUPLE_EXT)
        case MAP_EXT:
            return decodeMap()
        default:
            print("ERROR: Un decodable data received \(type)")
            return nil
        }
    }
    
    private func decodeByte() -> NSNumber {
        let num = NSNumber(value: ptr[0])
        advancePtrBy(n: MemoryLayout<UInt8>.size)
        return num
    }
    
    private func decodeShort() -> NSNumber {
        
        let result = ptr.withMemoryRebound(to: Int16.self, capacity: 1) { ptr -> NSNumber in
            let i = Int16(bigEndian: ptr.pointee)
            return NSNumber(value: i)
        }
        
        advancePtrBy(n: MemoryLayout<Int16>.size)
        
        return result
    }
    
    private func decodeInteger() -> NSNumber {
        
        let result = ptr.withMemoryRebound(to: Int32.self, capacity: 1) { ptr -> NSNumber in
            let i = Int32(bigEndian: ptr.pointee)
            return NSNumber(value: i)
        }
        
        advancePtrBy(n: MemoryLayout<Int32>.size)
        
        return result
    }
    
    private func decodeDouble() -> Double {
        let array = Array(UnsafeBufferPointer(start: ptr, count: MemoryLayout<Double>.size).reversed())
        advancePtrBy(n: MemoryLayout<Double>.size)
        return array.withUnsafeBufferPointer { (ptr) -> Double! in
            let baseAddr = ptr.baseAddress!
            return baseAddr.withMemoryRebound(to: Double.self, capacity: 1, { (ptr) -> Double in
                return ptr.pointee
            })
        }
    }

    
    private func decodeLongOrBigInteger(tag: UInt8) -> Any? {
        var byteCount: NSNumber!
        
        switch tag {
        case SMALL_BIG_EXT:
            byteCount = decodeByte()
        case LARGE_BIG_EXT:
            byteCount = decodeInteger()
        default:
            return nil
        }
        
        let sign = decodeByte() == 1 ? BigInt.Sign.minus : BigInt.Sign.plus
        
        let array = Array(UnsafeBufferPointer<UInt8>(start: ptr, count: byteCount.intValue).reversed())
        let bytes = Data(bytes: UnsafeRawPointer(array), count: byteCount.intValue)
        advancePtrBy(n: byteCount.intValue)
        let bigInt = BigInt(sign: sign, magnitude: BigUInt(bytes))
        return NSNumber(value: (bigInt.description as NSString).longLongValue)
    }
    
    private func decodeAtom(tag: UInt8) -> Any? {
        var byteCount: NSNumber!
        
        switch tag {
        case ATOM_EXT:
            byteCount = decodeShort()
        case SMALL_ATOM_EXT:
            byteCount = decodeByte()
        default:
            return nil
        }
        
        var atom: String?
        
        if byteCount.intValue > 0 {
            atom = decodeString(byteCount: byteCount)
        }
        
        if (atom == nil || atom!.isEmpty) {
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
            return BertAtom(atom: atom!)
        }
    }
    
    private func decodeString() -> String? {
        let byteCount: NSNumber = decodeShort()
        return decodeString(byteCount: byteCount)
    }
    
    private func decodeBinary() -> Data {
        let byteCount = decodeInteger()
        return decodeData(byteCount: byteCount)
    }
    
    private func decodeArray() -> Any {
        let numElements = decodeInteger().intValue
        
        var canDecodeAsMap: Bool = decodePropListsAsMap
        
        let array: AnyObject = NSMutableArray()
        
        for _ in 0..<numElements {
            let decoded = decode()
            canDecodeAsMap =
                canDecodeAsMap &&
                (decoded is BertTuple) &&
                (decoded as! BertTuple).isKV()
            array.add(decoded as AnyObject)
        }
        
        if decodeByte().uint8Value != NIL_EXT {
            let _ = ptr.predecessor()
        }
        
        if (canDecodeAsMap){
            let dict = NSMutableDictionary()
            
            for tuple in array as! [BertTuple] {
                dict.setObject(tuple.object(at: 1), forKey: tuple.object(at: 0) as! NSCopying)
            }
        
            return dict
        }
        
        return array
    }
    
    private func decodeTuple(tag: UInt8) -> Any? {
        var elements: NSNumber
        
        switch tag {
        case SMALL_TUPLE_EXT:
            elements = decodeByte()
        case LARGE_TUPLE_EXT:
            elements = decodeInteger()
        default:
            return nil
        }
        
        let tuple = BertTuple()
        
        for _ in stride(from: 0, to: elements.intValue, by: 1) {
            tuple.add(decode() as AnyObject)
        }

        return tuple
    }
    
    private func decodeMap() -> Dictionary<NSObject, Any> {
        let numElements = decodeInteger().intValue
        
        var dict = Dictionary<NSObject, Any>()
        
        for _ in stride(from: 0, to: numElements, by: 1) {
            let key = decodeMapKey()
            let value = decodeMapValue(key: key)
            
            guard let dictKey = key as? NSObject else { continue }
            
            if let val = value {
                dict[dictKey] = val
            } else if let val = value as? String{
                dict[dictKey] = val
            } else if let val = value as? Array<AnyObject>{
                dict[dictKey] = val
            } else {
                print("ERROR: unparsed value = \(String(describing: value)) for key = \(String(describing: key))")
            }
        }
    
        return dict
    }
    
    private func decodeMapKey() -> Any? {
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
        
        if key is Data {
            return String(data: key as! Data, encoding: String.Encoding.utf8)
        }
        
        return String(describing: key)
    }
    
    private func decodeMapValue(key: Any?) -> Any? {
        if (key == nil) {
            return nil
        }
        
        let value = decode()
        
        if shouldDecodeBinaryAsStringForKey(key: key as! NSObject) {
            switch value {
            case nil: return nil
            case let array as Array<Data>:
                return array.map { String(data: $0 as Data, encoding: String.Encoding.utf8)!}
            case let value as Data:
                return String(data: value, encoding: String.Encoding.utf8)
            default:
                break
            }
        }
        
        return value
    }
    
    private func decodeString(byteCount: NSNumber) -> String? {
        let data: Data = decodeData(byteCount: byteCount)
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    private func decodeData(byteCount: NSNumber) -> Data {
        let data = Data(bytes: ptr, count: byteCount.intValue)
        advancePtrBy(n: byteCount.intValue)
        return data
    }
    
    private func advancePtrBy(n: Int){
        ptr = ptr.advanced(by: n)
    }
}
