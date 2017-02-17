/*:
### Disclaimer
This may or may not be the right library for what you want to accomplish

This is **not** the right library if:
- 🚫 You're on your main thread in your new app and you don't want to wait for this async network requst to finish
- 🚫 Your user should be able to cancel a task running in the background, whops you made it synchronous
- 🚫 You looove completion handlers, you want to do everything asynchronous. Adding 2+2? handler! Averaging the array? handler!

This is the right library if:
- You picked up an API that has tons of **asynchronous function**, but because you're doing everything in a **background queue** anyways, it would be a pain to set up all the completion handlers
- You only want to try something out in a **Playground** but the function you need is asynchronous and you don't want your prints getting all messed up
- You (or somebody else) wrote a **synchronous function** that takes a **hella long time** to execute, you'd love to have a completion handler

 ----

## From an Asynchronous Function to a Synchronous One

Later in this playground I will ofter refer to input and output of a function where
- input: All the parameters of a function (without completion/error handler on asynchronous functions)
- output: The return type of a synchronous function or the parameters of the completion handler of an asynchronous function

Here we have an asynchronous function (the `async` is just a small utility to make asynchronous calling easier, see Utils.swift. We could also just ommit `async` for demonstration purposes but let's have it there anyways).
*/
func doubleLater(n: Int, whenDone: Int -> Void) {
	async { whenDone(n * 2) }
}
//: With the global function `toSync` you can convert it to the synchronous equivalent easily. `toSync` is a higher-order function: It takes a function as a parameter and returns another function (closures can be used too, as they are pretty much the same as functions)
let doubleNow = toSync(doubleLater)
doubleNow(10)
//: You can also use it like this
toSync(doubleLater)(5)
/*:
`toSync` is very heavily overloaded, so that it works with different amounts of inputs and outputs, throwing and non-throwing functions, generic and non-generic error types, with or without a dedicated error handler

`toSync` can be used with the following amount of input/outputs:

 - Non-error: 0 to 4 inputs, any number of outputs
 - Dedicated error handler: 0 to 4 inputs, any number of outputs
 - Optional error in completion handler: 0 to 4 inputs, 0 to 4 outputs

To demonstrate this, let's create a few different asynchronous functions
*/
// Our own error type
enum Error : ErrorType {
	case CannotDivideOddByTwo
	case FutureReference
}

func avg(vals: [Double], scale: Double, completion: (Double?, String?) -> Void) {
	async {
		guard vals.count != 0 else { completion(nil, nil); return }
		let result = vals.reduce(0, combine: +) / Double(vals.count) * scale
		completion(result, "The average scaled by \(scale) is \(result)")
	}
}

func sayItLots(string: String, times: Int, space: Bool, completion: (String, String, String, String) -> Void) {
	async {
		let result = Repeat(count: times, repeatedValue: string).joinWithSeparator(space ? " " : "")
		completion(result, result, result, result)
	}
}

import Foundation
func iLikeThrowing(completionHandler: ErrorType? -> Void) {
	async {
		completionHandler(NSError(domain: "MyOne", code: 42, userInfo: nil))
	}
}

func half(n: Int, completionHandler: (Int?, Error?) -> Void) {
	async {
		if n % 2 == 0 { completionHandler(n / 2, nil) }
		else { completionHandler(nil, Error.CannotDivideOddByTwo) }
	}
}

func howMuchShouldIEat(hungry: Bool, hasFood: Bool, numberOfHoursWithoutEating: Int, whenDoneDeciding: Double -> Void, onError: Error -> Void) {
	async {
		guard numberOfHoursWithoutEating >= 0 else { onError(Error.FutureReference); return }
		let amount = hasFood ? pow(hungry ? 2.0 : 1.5, Double(numberOfHoursWithoutEating)) : 0.0
		whenDoneDeciding(amount)
	}
}
//: Now let's convert these to synchronous variants
let syncAvg = toSync(avg)
let syncSayLots = toSync(sayItLots)
let syncThrowing = toSync(iLikeThrowing)
let syncHalf = toSync(half)
let amountToEat = toSync(howMuchShouldIEat)
/*:
As you can see from the types of the converted functions, asynchronous functions that take a completion handler with an optional error as the last argument become throwing functions automatically, as do functions with both a completion and an error handler. This works for both generic errors (like our own ErrorType "Error") and non-generic errors (any ErrorType). The new function intentionally does not automatically unwrap your functions optionals, as they might not not always contain a value. The converted function just throws an error when the error in the completion handler isn't nil.

We can call these synchronous variants just like usual functions. Named parameters are not available as that would exceed the languages abilities.
*/
syncAvg([1, 2, 5, 8], 2)
syncSayLots("Hey you!", 3, true)

do {
	try syncThrowing()
	try syncHalf(4)
	try amountToEat(true, true, 127)
} catch {
	error
}
//: There are also functions that don't automatically start when you call them, but instead need some action for them to activate. A good example of this is the `dataTaskWithURL:` function of `NSURLSession` which returns an NSURLSessionDataTask that has to be started using its `resume` method. If you don't call `resume` on the result, nothing would happen until you do.
//:
//: The `toSync` has an optional closure as its last parameter. This closure takes the value returned from the asynchronous function for you to do something with it. With this in mind you can create a synchronous network task.
let request = toSync(NSURLSession.sharedSession().dataTaskWithURL) { $0.resume() }

//: This newly created `getData` function is now usable as is. If you modify the url to something non-existant an error will be thrown synchronously and you don't have to worry about providing a callback.

do {
	let (data, response) = try request(NSURL(string: "https://www.google.com/")!)
	print(response)
} catch {
	print(error)
}

//: Let's try to create our own function that doesn't immediately start. For this we'll be using the `RemoteControl` struct (it really should be a class I'm pretty sure, but it doesn't matter here)

struct RemoteControl {
	let string : String
	let callback: () -> Void
	
	func printNow() {
		print(string)
		callback()
	}
}

func printByRemote(string: String, didPrint: () -> Void) -> RemoteControl {
	return RemoteControl(string: string, callback: didPrint)
}

//: And convert it to it's synchronous variant

let printInstantly = toSync(printByRemote) { $0.printNow() }

printInstantly("Hi John")

//: If we wouldn't call `printNow()` within the closure, the method would never return!

//: [Next](@next)
