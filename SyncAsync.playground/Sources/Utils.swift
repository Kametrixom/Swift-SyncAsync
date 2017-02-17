import Foundation

public func async(closure: () -> ()) {
	dispatch_async(dispatch_queue_create("Async", DISPATCH_QUEUE_SERIAL)) {
		closure()
	}
}

public func waitABit() {
	NSThread.sleepForTimeInterval(0.01)
}

