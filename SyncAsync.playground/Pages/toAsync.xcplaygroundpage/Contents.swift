//: [Previous](@previous)
import XCPlayground
//: The `toAsync` function is the reverse of the `toSync` function. It takes a synchronous function and returns its asynchronous variant
//: Let's create a synchronous function
func add(a: Int, b: Int) -> Int {
	return a + b
}
//: To make it asynchronous, just call `toAsync` on it. The resulting function takes the arguments of the synchronous function plus a completion handler
toAsync(add)(1, 2) { result in
	print("Added: \(result)")
}

waitABit() // Waits a bit so that the outputs don't get messed up (because it's asynchronous), see Utils.swift
//: Like the `toSync` function, the `toAsync` function is overloaded for it to be able to take up to four inputs and an unlimited amount of outputs. To demonstrate this, we'll create a few synchronous functions

// Our own error type
enum Error: ErrorType {
	case LessThanZero
	case DivisionByZero
}

func sayHi(to: String, isBuddy: Bool) -> (speech: String, friendly: Bool) {
	switch (to, isBuddy) {
	case ("Bob", _): return ("...", false)
	case (_, true): return ("Hey man", true)
	case (let s, _): return ("Hello, \(s)", true)
	}
}

func product(from: Int, through: Int, steps: Int) -> Int {
	return from.stride(through: through, by: steps).reduce(1, combine: *)
}

func factorial(n: Int) throws -> Int {
	guard n >= 0 else { throw Error.LessThanZero }
	return n < 2 ? 1 : try factorial(n - 1) * n
}

func divide12345By(val: Double) throws -> (Double, Double, Double, Double, Double) {
	guard val != 0 else { throw Error.DivisionByZero }
	return (1 / val, 2 / val, 3 / val, 4 / val, 5 / val)
}
//: Simply call `toAsync` to convert these to asynchronoous functions
let asyncHi = toAsync(sayHi)
let asyncProd = toAsync(product)
let asyncFactorial = toAsync(factorial)
let asyncDivision = toAsync(divide12345By)
//: As you can see from the types, throwing functions automatically get converted to functions that take a completion handler, executed when succeeded, and an error handler, executed when an error occured. As with `toSync`, parameter names cannot be preserved.
asyncHi("Paul", true) { debugPrint($0) }
waitABit()

asyncProd(4, 10, 2) { debugPrint($0) }
waitABit()

asyncFactorial(-3, completionHandler: { debugPrint($0) }, errorHandler: { debugPrint($0) })
waitABit()

asyncDivision(19, completionHandler: { debugPrint($0) }, errorHandler: { debugPrint($0) })
waitABit()
//: And yes if you really want to, you can chain `toAsync` and `toSync` even though this is utter nonsense

toSync(toAsync(sayHi))("Bob", false)

/*:
I hope this small library helps you, it was really fun to write it anyways. The source file was partly generated automatically, errors are unlikely, also due to the very strict function signatures, however if you happen to find an error, please let me know (@Kametrixom on Twitter, Reddit, StackOverflow, Github, ...) and I'll see what I can do. Suggestions and critique are very welcome as well. If you don't like that the functions are so minimized, I'm sorry, but otherwise it would get very big. Also sorry for any typos, english isn't my native language. If you're able to use my library for anything useful, I wouldn't mind a mention on Twitter ;)

Inspiration came from StackOverflow where people often want to make asynchronous tasks synchronous (usually that's a bad thing). They get replies such as "These functions are asynchronous for a reason, don't fight it", etc. but sometimes it's actually pretty useful to have them synchronous, as I mentioned in the beginning.

Recently I've been getting into Haskell, where higher-order functions are the norm, which made me write this library in this higher-order function style (I like it :D).
*/

