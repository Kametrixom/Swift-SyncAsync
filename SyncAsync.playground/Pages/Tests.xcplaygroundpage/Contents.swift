import Foundation
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely()

// This test set isn't complete in that it doesn't test every function, however most functions in SyncAsync.swift were generated automatically, a typo isn't likely

enum E : ErrorType {
	case E
	init() { self = E }
}

func sn11(a: Int) -> Int { return a }
func sn21(a: Int, b: Int) -> Int { return a + b }
func sn12(a: Int) -> (Int, Int) { return (a, a + 1) }
func sn22(a: Int, b: Int) -> (Int, Int) { return (a + b, a - b) }

func st11(a: Int) throws -> Int { guard a > 0 else { throw E() }; return a }
func st21(a: Int, b: Int) throws -> Int { guard a > 0 && b > 0 else { throw E() }; return a + b }
func st12(a: Int) throws -> (Int, Int) { guard a > 0 else { throw E() }; return (a, a + 1) }
func st22(a: Int, b: Int) throws -> (Int, Int) { guard a > 0 && b > 0 else { throw E() }; return (a + b, a - b) }

toAsync(sn11)(1) { print("sn11: \($0)") }
toAsync(sn21)(1, 1) { print("sn21: \($0)") }
toAsync(sn12)(1) { a, b in print("sn12: \(a, b)") }
toAsync(sn22)(1, 1) { print("sn22: \($0)") }

toAsync(st11)(1, completionHandler: { print("st11: \($0)") }, errorHandler: { print("st11 error: \($0)") })
toAsync(st11)(0, completionHandler: { print("st11: \($0)") }, errorHandler: { print("st11 error: \($0)") })
toAsync(st21)(1, 1, completionHandler: { print("st21: \($0)") }, errorHandler: { print("st21 error: \($0)") })
toAsync(st21)(1, 0, completionHandler: { print("st21: \($0)") }, errorHandler: { print("st21 error: \($0)") })
toAsync(st12)(1, completionHandler: { a, b in print("st12: \(a, b)") }, errorHandler: { print("st12 error: \($0)") })
toAsync(st12)(0, completionHandler: { print("st12: \($0)") }, errorHandler: { print("st12 error: \($0)") })
toAsync(st22)(1, 1, completionHandler: { print("st22: \($0)") }, errorHandler: { print("st22 error: \($0)") })
toAsync(st22)(0, 1, completionHandler: { print("st22: \($0)") }, errorHandler: { print("st22 error: \($0)") })


NSThread.sleepForTimeInterval(1)
print("")

struct S<I, O> {
	let i: I, c: I -> O, h: O -> ()
	func exec() { h(c(i)) }
}

func ann11(a: Int, h: Int -> ()) { h(a) }
func ann21(a: Int, b: Int, h: Int -> ()) { h(a + b) }
func ann12(a: Int, h: (Int, Int) -> ()) { h(a, a + 1) }
func ann22(a: Int, b: Int, h: (Int, Int) -> ()) { h(a + b, a - b) }

func asn11(a: Int, h: Int -> ()) -> S<Int, Int> { return S(i: a, c: {$0}, h: h) }
func asn21(a: Int, b: Int, h: Int -> ()) -> S<(Int, Int), Int> { return S(i: (a, b), c: {$0.0 + $0.1}, h: h) }
func asn12(a: Int, h: (Int, Int) -> ()) -> S<Int, (Int, Int)> { return S(i: a, c: {($0, $0 + 1)}, h: h) }
func asn22(a: Int, b: Int, h: (Int, Int) -> ()) -> S<(Int, Int), (Int, Int)> { return S(i: (a, b), c: {($0.0 + $0.1, $0.0 - $0.1)}, h: h) }



print("ann11 \(toSync(ann11)(1))")
print("ann21 \(toSync(ann21)(1, 1))")
print("ann12 \(toSync(ann12)(1))")
print("ann22 \(toSync(ann22)(1, 1))")

print("asn11 \(toSync(asn11) { $0.exec() }(1))")
print("asn21 \(toSync(asn21) { $0.exec() }(1, 1))")
print("asn12 \(toSync(asn12) { $0.exec() }(1))")
print("asn22 \(toSync(asn22) { $0.exec() }(1, 1))")


func ant11(a: Int, h: (Int?, ErrorType?) -> ()) { a > 0 ? h(a, nil) : h(nil, E()) }
func ant21(a: Int, b: Int, h: (Int?, ErrorType?) -> ()) { a > 0 && b > 0 ? h(a + b, nil) : h(nil, E()) }
func ant12(a: Int, h: (Int?, Int?, ErrorType?) -> ()) { a > 0 ? h(a, a + 1, nil) : h(nil, nil, E()) }
func ant22(a: Int, b: Int, h: (Int?, Int?, ErrorType?) -> ()) { a > 0 && b > 0 ? h(a + b, a - b, nil) : h(nil, nil, E()) }

do { try print("ant11: \(toSync(ant11)(1))") } catch { print(error) }
do { try print("ant21: \(toSync(ant21)(1, 1))") } catch { print(error) }
do { try print("ant12: \(toSync(ant12)(1))") } catch { print(error) }
do { try print("ant22: \(toSync(ant22)(1, 1))") } catch { print(error) }
do { try print("ant11: \(toSync(ant11)(0))") } catch { print("ant11 error: \(error)") }
do { try print("ant21: \(toSync(ant21)(0, 1))") } catch { print("ant21 error: \(error)") }
do { try print("ant12: \(toSync(ant12)(0))") } catch { print("ant12 error: \(error)") }
do { try print("ant22: \(toSync(ant22)(1, 0))") } catch { print("ant22 error: \(error)") }







