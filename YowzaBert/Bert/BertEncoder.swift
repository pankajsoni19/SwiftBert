//
//  BertEncoder.swift
//  wafer
//
//  Created by Pankaj Soni on 06/10/16.
//  Copyright © 2016 pankaj soni. All rights reserved.
//

import UIKit

class BertEncoder: Bert {
    
    private var data: NSMutableData!
    
    private var encodeStringAsBinary    = false
    private var encodeMapKeysAsAtom     = false
    private var encodeMapKeysAsString   = false
    private var encodeMapAsPropList     = false
    private var encodeKVTupleAsMap      = false
    
    func withEncodeStringAsBinary(encodeStringAsBinary : Bool) -> BertEncoder {
        self.encodeStringAsBinary = encodeStringAsBinary
        return self
    }
    
    func withEncodeMapAsPropList(encodeMapAsPropList  : Bool) -> BertEncoder {
        self.encodeMapAsPropList = encodeMapAsPropList
        return self
    }
    
    func withEncodeMapKeysAsAtom(encodeMapKeysAsAtom: Bool) ->BertEncoder {
        self.encodeMapKeysAsAtom = encodeMapKeysAsAtom
        return self
    }
    
    func withEncodeMapKeysAsString(encodeMapKeysAsString : Bool) -> BertEncoder {
        self.encodeMapKeysAsString = encodeMapKeysAsString
        return self
    }
    
    func withEncodeKVTupleAsMap(encodeKVTupleAsMap: Bool) -> BertEncoder {
        self.encodeKVTupleAsMap = encodeKVTupleAsMap
        return self
    }
    
    func encodeAny(any: Any!) -> NSData{
        data = NSMutableData()
        data.append(&MAGIC, length: 1)
        encode(any: any)
        
        // create array of appropriate length:
        var array = [UInt8](repeating: 0, count: data.length)
        
        // copy bytes into array
        data.getBytes(&array, length:data.length)
        
//        for x in 0...array.count-1 {
//            print(array[x])
//        }
        return data;
    }
    
    private func encode(any: Any!){
        switch any {
        case nil:
            encodeNull();
        case let num as NSNumber:
            if isFraction(num: num) {
                encodeDouble(someDouble: num.doubleValue)
            } else {
                encodeInteger(someInt: Int(num.int64Value))
            }
        case let someInt as Int:
            encodeInteger(someInt: someInt)
        case let someLong as Int64:
            encodeBigInteger(bigInt: BigInt(someLong))
        case let someFloat as Float:
            let someDouble = Double(someFloat)
            encodeDouble(someDouble: someDouble)
        case let someDouble as Double:
            encodeDouble(someDouble: someDouble)
        case let bigInt as BigInt:
            encodeBigInteger(bigInt: bigInt)
        case let bool as Bool:
            if (bool){
                encodeAtom(atom: "true")
            } else{
                encodeAtom(atom: "false")
            }
        case let atom as BertAtom:
            encodeAtom(atom: atom.stringVal())
        case let string as String:
            encodeString(string: string)
        case let binary as NSData:
            encodeBinary(binary: binary)
        case let tuple as BertTuple:
            encodeTuple(tuple: tuple)
        case let array as Array<AnyObject>:
            let elems = array.map {$0 as Any}
            encodeArray(array: elems)
        case let dict as NSDictionary:
            encodeDict(dict: dict)
        default:
            print("Un encodable data received \(any)")
        }
    }
    
    private func encodeNull(){
        data.append(&NIL_EXT, length: 1)
    }
    
    private func encodeByte(someByte: Int) {
        data.append(&SMALL_INTEGER_EXT, length: 1)
        putUnsignedByte(someByte: someByte);
    }
    
    private func encodeInteger(someInt: Int){
        if (SMALL_INTEGER_EXT_MIN_VAL <= someInt && someInt <= SMALL_INTEGER_EXT_MAX_VAL) {
            encodeByte(someByte: someInt)
        } else if (INTEGER_EXT_MIN_VAL <= someInt && someInt <= INTEGER_EXT_MAX_VAL) {
            data.append(&INTEGER_EXT, length: 1)
            var value: Int32 = Int32(someInt).bigEndian;
            data.append(&value, length: MemoryLayout<Int32>.size);
        } else {
            encodeBigInteger(bigInt: BigInt(someInt))
        }
    }
    
    private func encodeDouble(someDouble: Double){
        var array = toByteArray(value: someDouble)
        data.append(&NEW_FLOAT_EXT, length: 1)
        data.append(&array, length: MemoryLayout<Double>.size)
    }
    
    private func encodeBigInteger(bigInt: BigInt){
        
        let bytes: NSData = bigInt.abs.serialize() as NSData
        let count = bytes.length
        
        if (count <= SMALL_INTEGER_EXT_MAX_VAL){
            data.append(&SMALL_BIG_EXT, length: 1)
            putUnsignedByte(someByte: count);
        } else {
            data.append(&LARGE_BIG_EXT, length: 1)
            putUnsignedInt(someInt: count);
        }
        
        var sign: UInt8 = bigInt.negative ? 1 : 0
        
        data.append(&sign, length: 1)
        data.append(bytes as Data)
    }
    
    private func encodeAtom(atom: String) {
        let count = atom.characters.count;
        
        if (count <= SMALL_INTEGER_EXT_MAX_VAL){
            data.append(&SMALL_ATOM_EXT, length: 1)
            putUnsignedByte(someByte: count)
        } else{
            data.append(&ATOM_EXT, length: 1)
            putUnsignedShort(someShort: count);
        }
        
        data.append(atom.data(using: String.Encoding.utf8)!)
    }
    
    private func encodeString(string: String){
        if (encodeStringAsBinary){
            encodeBinary(binary: string.data(using: String.Encoding.utf8)! as NSData)
            return;
        }
        
        let count = string.characters.count;
        
        if (count <= STRING_EXT_MAX_VAL){
            data.append(&STRING_EXT, length: 1)
            putUnsignedShort(someShort: count);
            data.append(string.data(using: String.Encoding.utf8)!)
        } else {
            encodeArray(array: Array(arrayLiteral: string.characters))
        }
    }
    
    private func encodeBinary(binary: NSData) {
        data.append(&BINARY_EXT, length: 1)
        putUnsignedInt(someInt: binary.length);
        data.append(binary as Data)
    }
    
    private func encodeTuple(tuple: BertTuple) {
        if tuple.isKV() {
            let dict = NSMutableDictionary()
            dict.setObject(tuple.object(at: 0), forKey: tuple.object(at: 1) as! NSCopying)
            encode(any: dict)
            return
        }
        
        let count = tuple.count
        
        if (count <= SMALL_INTEGER_EXT_MAX_VAL){
            data.append(&SMALL_TUPLE_EXT, length: 1)
            putUnsignedByte(someByte: count);
        } else{
            data.append(&LARGE_TUPLE_EXT, length: 1)
            putUnsignedInt(someInt: count);
        }
        
        for o: Any in tuple {
            encode(any: o)
        }
    }
    
    private func encodeArray(array: Array<Any>){
        data.append(&LIST_EXT, length: 1)
        
        putUnsignedInt(someInt: array.count);
        
        for o: Any in array {
            encode(any: o)
        }
        
        encodeNull();
    }
    
    private func encodeDict(dict: NSDictionary){
        if (encodeMapAsPropList){
            data.append(&LIST_EXT, length: 1)
        } else{
            data.append(&MAP_EXT, length: 1)
        }
        
        putUnsignedInt(someInt: dict.count);
        
        for (key, value) in dict {
            if (encodeMapAsPropList){
                data.append(&SMALL_TUPLE_EXT, length: 1)
                putUnsignedByte(someByte: 2);
            }
            
            if (encodeMapKeysAsAtom) {
                encodeAtom(atom: String(describing: key));
            } else if (encodeMapKeysAsString) {
                encodeString(string: String(describing: key));
            } else {
                encode(any: key);
            }
            
            encode(any: value);
        }
        
        if (encodeMapAsPropList){
            encodeNull();
        }
    }
    
    private func putUnsignedByte(someByte: Int) {
        var byte: UInt8 = UInt8(someByte);
        data.append(&byte, length: 1)
    }
    
    private func putUnsignedShort(someShort: Int) {
        var short: UInt16 = UInt16(someShort).bigEndian
        data.append(&short, length: MemoryLayout<UInt16>.size)
    }
    
    private func putUnsignedInt(someInt: Int) {
        var int: UInt32 = UInt32(someInt).bigEndian
        data.append(&int, length: MemoryLayout<UInt32>.size)
    }
    
    func toByteArray<T>(value: T) -> [UInt8] {
        var v: T = value
        return withUnsafePointer(to: &v) {
            Array(UnsafeBufferPointer(start: UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self), count: MemoryLayout<T>.size).reversed())
        }
    }
}

