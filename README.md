# SyncAsync
### A Swift library to convert between synchronous and asynchronous functions

##Disclaimer
This may or may not be the right library for what you want to accomplish. **Most likely it's not**, because asynchronous methods are usually meant to be asynchronous because they may take a long time or need the ability to be canceled. Have a look at the discussion [here](https://twitter.com/Kametrixom/status/636214808438829057) about making asynchronous functions synchronous, it's generally a *very* bad idea.

This is **not** the right library if:
- 🚫 You're on your main thread in your new app and you don't want to wait for this async network requst to finish
- 🚫 Your user should be able to cancel a task running in the background, whops you made it synchronous
- 🚫 You looove completion handlers, you want to do everything asynchronous. Adding 2+2? handler! Averaging the array? handler!
- 🚫 You picked up an API that has tons of **asynchronous function** and you want all of them synchronously because you think it's easier. Don't do this, they are meant to be like this

This might be the right library if:
- You only want to try something out in a **Playground** but the function you need is asynchronous and you don't want your prints getting all messed up
- You (or somebody else) wrote a **synchronous function** that takes a **hella long time** to execute, you'd love to have a completion handler

I recommend not using this library in a serious project, as most likely there's something wrong if you need to convert sync/async functions. Also async -> sync is generally not as bad of a pattern than sync -> async. Use this library as a convenience for something quick, **don't abuse it** to unify synchronous/asynchronous tasks, they are not the same.

##Usage

There are only two (heavily overloaded) functions in this library:
- `toSync` which takes an asynchronous function and returns the synchronous equivalent
- `toAsync` which does the opposite: Takes a synchronous function and returns the asynchronous equivalent

These work for different amounts of inputs and outputs, throwing and non-throwing, generic and non-generic errors, with or without a dedicated error handler.

A much more detailed tutorial including throwing functions, error handlers and more is in the Playground

###toSync

We have got ourselves an asynchronous function

```swift
func doItLater(n: Int, completionHandler: String -> Void) {
  dispatch_async(dispatch_queue_create("", DISPATCH_QUEUE_SERIAL)) {
    let string = "\n".join(Repeat(count: n, repeatedValue: "JUST DO IT!"))
    completionHandler(string)
  }
}
```

but we don't want to procrastinate, so we make it synchronous

```swift
let doItNow = toSync(doItLater)   // type signature: Int -> String
```

and call it

```swift
doItNow(100)    // "JUST DO IT!\nJUST DO IT!\nJUST DO IT!..."
```

###toAsync

Suppose we have a synchronous function

```swift
func multiply(a: Int, b: Int) -> Int {
  return a * b
}
```

We can convert it to an asynchronous one like this

```swift
let asyncMultiply = toAsync(multiply)   // type signature: (Int, Int, completionHandler: Int -> ()) -> ()
```

and call it

```swift
asyncAdd(6, 9) {
  print($0)
}
```

Which will obviously print "42" when done, using our provided completion handler

##How to use it in your project

All you need to do to be able to use this is:
- Download the Playground for a full tutorial (or you can download the important stuff only [here](https://github.com/Kametrixom/SyncAsync/blob/master/SyncAsync.playground/Sources/SyncAsync.swift))
- Copy the SyncAsync.swift into your project

##Notes

I hope this small library helps you, it was really fun to write it anyways. The source file was partly generated automatically, errors are unlikely, also due to the very strict function signatures, however if you happen to find one, please let me know (@Kametrixom on Twitter, Reddit, StackOverflow, Github, ...) and I'll see what I can do. Suggestions and critique are very welcome as well. If you don't like that the functions are so minimized, I'm sorry, but otherwise it would get very big. Also sorry for any typos, english isn't my native language. If you're able to use my library for anything useful, I wouldn't mind a mention on Twitter ;)

Inspiration came from StackOverflow where people often want to make asynchronous tasks synchronous (usually that's a bad thing). They get replies such as "These functions are asynchronous for a reason, don't fight it", etc. but sometimes it's actually pretty useful to have them synchronous, as I mentioned in the beginning.

Recently I've been getting into Haskell, where higher-order functions are the norm, which made me write this library in this higher-order function style (I like it :D).
