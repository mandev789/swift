// RUN: %target-run-simple-swift | FileCheck %s

import Foundation

class Canary: NSObject {
  deinit {
    println("died")
  }
}

var CanaryAssocObjectHandle: UInt8 = 0
// Attach an associated object with a loud deinit so we can see that the
// object died.
func hangCanary(o: AnyObject) {
  objc_setAssociatedObject(o, &CanaryAssocObjectHandle, Canary(),
                     objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
}

// CHECK-LABEL: NSData:
println("NSData:")
autoreleasepool {
  var bytes: UnsafeMutablePointer<UInt8>
  do {
    let data = NSData(bytes: [2, 3, 5, 7] as [UInt8], length: 4)
    hangCanary(data)
    bytes = data.bytes.asPointerTo(UInt8.self).asMutablePointer
  } while false // CHECK-NOT: died
  println(bytes[0]) // CHECK:      2
  println(bytes[1]) // CHECK-NEXT: 3
  println(bytes[2]) // CHECK-NEXT: 5
  println(bytes[3]) // CHECK-NEXT: 7
} // CHECK-NEXT: died

// CHECK-LABEL: AnyObject:
println("AnyObject:")
autoreleasepool {
  var bytes: UnsafeMutablePointer<UInt8>
  do {
    let data = NSData(bytes: [11, 13, 17, 19] as [UInt8], length: 4)
    hangCanary(data)
    let dataAsAny: AnyObject = data
    bytes = dataAsAny.bytes!.asPointerTo(UInt8.self).asMutablePointer
  } while false // CHECK-NOT: died
  println(bytes[0]) // CHECK:      11
  println(bytes[1]) // CHECK-NEXT: 13
  println(bytes[2]) // CHECK-NEXT: 17
  println(bytes[3]) // CHECK-NEXT: 19
} // CHECK-NEXT: died
