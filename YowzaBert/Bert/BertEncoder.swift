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
        data.appendBytes(&MAGIC, length: 1)
        encode(any)
        
        // create array of appropriate length:
        var array = [UInt8](count: data.length, repeatedValue: 0)
        
        // copy bytes into array
        data.getBytes(&array, length:data.length)
        
        for x in 0...array.count-1 {
            print(array[x])
        }
        return data;
    }
    
    private func encode(any: Any!){
        switch any {
        case nil:
            encodeNull();
        case let num as NSNumber:
            if isFraction(num) {
                encodeDouble(num.doubleValue)
            } else {
                encodeInteger(Int(num.longLongValue))
            }
        case let someInt as Int:
            encodeInteger(someInt)
        case let someLong as Int64:
            encodeBigInteger(BigInt(someLong))
        case let someFloat as Float:
            let someDouble = Double(someFloat)
            encodeDouble(someDouble)
        case let someDouble as Double:
            encodeDouble(someDouble)
        case let bigInt as BigInt:
            encodeBigInteger(bigInt)
        case let bool as Bool:
            if (bool){
                encodeAtom("true")
            } else{
                encodeAtom("false")
            }
        case let atom as BertAtom:
            encodeAtom(atom.stringVal())
        case let string as String:
            encodeString(string)
        case let binary as NSData:
            encodeBinary(binary)
        case let tuple as BertTuple:
            encodeTuple(tuple)
        case let array as NSArray:
            encodeArray(array.flatMap({$0}))
        case let array as Array<Any>:
            encodeArray(array)
        case let dict as NSDictionary:
            encodeDict(dict)
        default:
            print("Un encodable data received \(any)")
        }
    }
    
    private func encodeNull(){
        data.appendBytes(&NIL_EXT, length: 1)
    }
    
    private func encodeByte(someByte: Int) {
        data.appendBytes(&SMALL_INTEGER_EXT, length: 1)
        putUnsignedByte(someByte);
    }
    
    private func encodeInteger(someInt: Int){
        if (SMALL_INTEGER_EXT_MIN_VAL <= someInt && someInt <= SMALL_INTEGER_EXT_MAX_VAL) {
            encodeByte(someInt)
        } else if (INTEGER_EXT_MIN_VAL <= someInt && someInt <= INTEGER_EXT_MAX_VAL) {
            data.appendBytes(&INTEGER_EXT, length: 1)
            var value: Int32 = Int32(someInt).bigEndian;
            data.appendBytes(&value, length: sizeof(Int32));
        } else {
            encodeBigInteger(BigInt(someInt))
        }
    }
    
    private func encodeDouble(someDouble: Double){
        var array = toByteArray(someDouble)
        data.appendBytes(&NEW_FLOAT_EXT, length: 1)
        data.appendBytes(&array, length: sizeof(Double))
    }
    
    private func encodeBigInteger(bigInt: BigInt){
        
        let bytes: NSData = bigInt.abs.serialize()
        let count = bytes.length
        
        if (count <= SMALL_INTEGER_EXT_MAX_VAL){
            data.appendBytes(&SMALL_BIG_EXT, length: 1)
            putUnsignedByte(count);
        } else {
            data.appendBytes(&LARGE_BIG_EXT, length: 1)
            putUnsignedInt(count);
        }
        
        var sign: UInt8 = bigInt.negative ? 1 : 0
        
        data.appendBytes(&sign, length: 1)
        data.appendData(bytes)
    }
    
    private func encodeAtom(atom: String) {
        let count = atom.characters.count;
        
        if (count <= SMALL_INTEGER_EXT_MAX_VAL){
            data.appendBytes(&SMALL_ATOM_EXT, length: 1)
            putUnsignedByte(count)
        } else{
            data.appendBytes(&ATOM_EXT, length: 1)
            putUnsignedShort(count);
        }
        
        data.appendData(atom.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    private func encodeString(string: String){
        if (encodeStringAsBinary){
            encodeBinary(string.dataUsingEncoding(NSUTF8StringEncoding)!);
            return;
        }
        
        let count = string.characters.count;
        
        if (count <= STRING_EXT_MAX_VAL){
            data.appendBytes(&STRING_EXT, length: 1)
            putUnsignedShort(count);
            data.appendData(string.dataUsingEncoding(NSUTF8StringEncoding)!)
        } else {
            encodeArray(Array(arrayLiteral: string.characters))
        }
    }
    
    private func encodeBinary(binary: NSData) {
        data.appendBytes(&BINARY_EXT, length: 1)
        putUnsignedInt(binary.length);
        data.appendData(binary)
    }
    
    private func encodeTuple(tuple: BertTuple) {
        if tuple.isKV() {
            let dict = NSMutableDictionary()
            dict.setObject(tuple.objectAtIndex(0), forKey: tuple.objectAtIndex(1) as! NSCopying)
            encode(dict)
            return
        }
        
        let count = tuple.count()
        
        if (count <= SMALL_INTEGER_EXT_MAX_VAL){
            data.appendBytes(&SMALL_TUPLE_EXT, length: 1)
            putUnsignedByte(count);
        } else{
            data.appendBytes(&LARGE_TUPLE_EXT, length: 1)
            putUnsignedInt(count);
        }
        
        for o : Any in tuple.array {
            encode(o)
        }
    }
    
    private func encodeArray(array: Array<Any>){
        data.appendBytes(&LIST_EXT, length: 1)
        
        putUnsignedInt(array.count);
        
        for o: Any in array {
            encode(o)
        }
        
        encodeNull();
    }
    
    private func encodeDict(dict: NSDictionary){
        if (encodeMapAsPropList){
            data.appendBytes(&LIST_EXT, length: 1)
        } else{
            data.appendBytes(&MAP_EXT, length: 1)
        }
        
        putUnsignedInt(dict.count);
        
        NSLog("count of elements \(dict.count)")
        
        for (key, value) in dict {
            if (encodeMapAsPropList){
                data.appendBytes(&SMALL_TUPLE_EXT, length: 1)
                putUnsignedByte(2);
            }
            
            if (encodeMapKeysAsAtom) {
                encodeAtom(String(key));
            } else if (encodeMapKeysAsString) {
                encodeString(String(key));
            } else {
                encode(key);
            }
            
            encode(value);
        }
        
        if (encodeMapAsPropList){
            encodeNull();
        }
    }
    
    private func putUnsignedByte(someByte: Int) {
        var byte: UInt8 = UInt8(someByte);
        data.appendBytes(&byte, length: 1)
    }
    
    private func putUnsignedShort(someShort: Int) {
        var short: UInt16 = UInt16(someShort).bigEndian
        data.appendBytes(&short, length: sizeof(UInt16))
    }
    
    private func putUnsignedInt(someInt: Int) {
        var int: UInt32 = UInt32(someInt).bigEndian
        data.appendBytes(&int, length: sizeof(UInt32))
    }
    
    func toByteArray<T>(value: T) -> [UInt8] {
        var v: T = value
        return withUnsafePointer(&v) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)).reverse())
        }
    }
}


