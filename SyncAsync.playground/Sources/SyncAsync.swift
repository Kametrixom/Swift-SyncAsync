import Foundation

// MARK: Utils -

private struct Group {
	let group = dispatch_group_create()
	func enter() { dispatch_group_enter(group) }
	func leave() { dispatch_group_leave(group) }
	func wait() { dispatch_group_wait(group, DISPATCH_TIME_FOREVER) }
}

private func createConcurrent() -> dispatch_queue_t {
	return dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
}

private func async(queue: dispatch_queue_t, closure: () -> Void) {
	dispatch_async(queue, closure)
}

// MARK: - toAsync -

// MARK: No Error

public func toAsync<O>(f: () -> O) -> (completionHandler: O -> ()) -> () {
	let queue = createConcurrent()	// Needs to be concurrent because the method can be called multiple times
	return { ch in async(queue) { ch(f()) } }
}
public func toAsync<I0, O>(f: (I0) -> O) -> (I0, completionHandler: O -> ()) -> () {
	let queue = createConcurrent()
	return { i0, ch in async(queue) { ch(f(i0)) } }
}
public func toAsync<I0, I1, O>(f: (I0, I1) -> O) -> (I0, I1, completionHandler: O -> ()) -> () {
	let queue = createConcurrent()
	return { i0, i1, ch in async(queue) { ch(f(i0, i1)) } }
}
public func toAsync<I0, I1, I2, O>(f: (I0, I1, I2) -> O) -> (I0, I1, I2, completionHandler: O -> ()) -> () {
	let queue = createConcurrent()
	return { i0, i1, i2, ch in async(queue) { ch(f(i0, i1, i2)) } }
}
public func toAsync<I0, I1, I2, I3, O>(f: (I0, I1, I2, I3) -> O) -> (I0, I1, I2, I3, completionHandler: O -> ()) -> () {
	let queue = createConcurrent()
	return { i0, i1, i2, i3, ch in async(queue) { ch(f(i0, i1, i2, i3)) } }
}

// MARK: - Error

public func toAsync<O>(f: () throws -> O) -> (completionHandler: O -> (), errorHandler: ErrorType -> ()) -> () {
	let queue = createConcurrent()
	return { ch, eh in async(queue) { do { try ch(f()) } catch { eh(error) } } }
}
public func toAsync<I0, O>(f: (I0) throws -> O) -> (I0, completionHandler: O -> (), errorHandler: ErrorType -> ()) -> () {
	let queue = createConcurrent()
	return { i0, ch, eh in async(queue) { do { try ch(f(i0)) } catch { eh(error) } } }
}
public func toAsync<I0, I1, O>(f: (I0, I1) throws -> O) -> (I0, I1, completionHandler: O -> (), errorHandler: ErrorType -> ()) -> () {
	let queue = createConcurrent()
	return { i0, i1, ch, eh in async(queue) { do { try ch(f(i0, i1)) } catch { eh(error) } } }
}
public func toAsync<I0, I1, I2, O>(f: (I0, I1, I2) throws -> O) -> (I0, I1, I2, completionHandler: O -> (), errorHandler: ErrorType -> ()) -> () {
	let queue = createConcurrent()
	return { i0, i1, i2, ch, eh in async(queue) { do { try ch(f(i0, i1, i2)) } catch { eh(error) } } }
}
public func toAsync<I0, I1, I2, I3, O>(f: (I0, I1, I2, I3) throws -> O) -> (I0, I1, I2, I3, completionHandler: O -> (), errorHandler: ErrorType -> ()) -> () {
	let queue = createConcurrent()
	return { i0, i1, i2, i3, ch, eh in async(queue) { do { try ch(f(i0, i1, i2, i3)) } catch { eh(error) } } }
}

// MARK: - toSync -

// MARK: No Error

public func toSync<I, O, R>(f: (I, completionHandler: O -> ()) -> R, start: R -> () = { _ in }) -> I -> O {
	return { input in
		let group = Group()
		var output: O!
		
		group.enter()
		start(f(input) {
			output = $0
			group.leave()
		})
		
		group.wait()
		return output
	}
}

public func toSync<O, R>(f: (completionHandler: O -> ()) -> R, start: R -> () = { _ in }) -> () -> O {
	return toSync({ f(completionHandler: $1) }, start: start)
}
public func toSync<I0, I1, O, R>(f: (I0, I1, completionHandler: O -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) -> O {
	return toSync({ f($0.0, $0.1, completionHandler: $1) }, start: start)
}
public func toSync<I0, I1, I2, O, R>(f: (I0, I1, I2, completionHandler: O -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) -> O {
	return toSync({ f($0.0, $0.1, $0.2, completionHandler: $1) }, start: start)
}
public func toSync<I0, I1, I2, I3, O, R>(f: (I0, I1, I2, I3, completionHandler: O -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) -> O {
	return toSync({ f($0.0, $0.1, $0.2, $0.3, completionHandler: $1) }, start: start)
}

// MARK: - Error

// MARK: Error Handler

public func toSync<I, O, R>(f: (I, completionHandler: O -> Void, errorHandler: ErrorType -> Void) -> R, start: R -> () = {_ in }) -> I throws -> O {
	return { i0 in
		let group = Group()
		var error: ErrorType?, output: O!
		
		group.enter()
		start(f(i0,
			completionHandler: {
				output = $0
				group.leave() },
			errorHandler: {
				error = $0
				group.leave()
		}))
		group.wait()
		
		if let error = error { throw error }
		return output
	}
}

public func toSync<I, O, R, E: ErrorType>(f: (I, completionHandler: O -> Void, errorHandler: E -> Void) -> R, start: R -> () = {_ in }) -> I throws -> O {
	return { i0 in
		let group = Group()
		var error: E?, output: O!
		
		group.enter()
		start(f(i0,
			completionHandler: {
				output = $0
				group.leave() },
			errorHandler: {
				error = $0
				group.leave()
		}))
		group.wait()
		
		if let error = error { throw error }
		return output
	}
}

public func toSync<O, R>(f: (completionHandler: O -> Void, errorHandler: ErrorType -> Void) -> R, start: R -> () = {_ in }) -> Void throws -> O {
	return toSync({ i, ch, eh in f(completionHandler: ch, errorHandler: eh) }, start: start)
}
public func toSync<O, R, E: ErrorType>(f: (completionHandler: O -> Void, errorHandler: E -> Void) -> R, start: R -> () = {_ in }) -> Void throws -> O {
	return toSync({ i, ch, eh in f(completionHandler: ch, errorHandler: eh) }, start: start)
}
public func toSync<I1, I2, O, R>(f: (I1, I2, completionHandler: O -> Void, errorHandler: ErrorType -> Void) -> R, start: R -> () = {_ in }) -> (I1, I2) throws -> O {
	return toSync({ i, ch, eh in f(i.0, i.1, completionHandler: ch, errorHandler: eh) }, start: start)
}
public func toSync<I1, I2, O, R, E: ErrorType>(f: (I1, I2, completionHandler: O -> Void, errorHandler: E -> Void) -> R, start: R -> () = {_ in }) -> (I1, I2) throws -> O {
	return toSync({ i, ch, eh in f(i.0, i.1, completionHandler: ch, errorHandler: eh) }, start: start)
}
public func toSync<I1, I2, I3, O, R>(f: (I1, I2, I3, completionHandler: O -> Void, errorHandler: ErrorType -> Void) -> R, start: R -> () = {_ in }) -> (I1, I2, I3) throws -> O {
	return toSync({ i, ch, eh in f(i.0, i.1, i.2, completionHandler: ch, errorHandler: eh) }, start: start)
}
public func toSync<I1, I2, I3, O, R, E: ErrorType>(f: (I1, I2, I3, completionHandler: O -> Void, errorHandler: E -> Void) -> R, start: R -> () = {_ in }) -> (I1, I2, I3) throws -> O {
	return toSync({ i, ch, eh in f(i.0, i.1, i.2, completionHandler: ch, errorHandler: eh) }, start: start)
}
public func toSync<I1, I2, I3, I4, O, R>(f: (I1, I2, I3, I4, completionHandler: O -> Void, errorHandler: ErrorType -> Void) -> R, start: R -> () = {_ in }) -> (I1, I2, I3, I4) throws -> O {
	return toSync({ i, ch, eh in f(i.0, i.1, i.2, i.3, completionHandler: ch, errorHandler: eh) }, start: start)
}
public func toSync<I1, I2, I3, I4, O, R, E: ErrorType>(f: (I1, I2, I3, I4, completionHandler: O -> Void, errorHandler: E -> Void) -> R, start: R -> () = {_ in }) -> (I1, I2, I3, I4) throws -> O {
	return toSync({ i, ch, eh in f(i.0, i.1, i.2, i.3, completionHandler: ch, errorHandler: eh) }, start: start)
}

// MARK: No Error Handler

public func toSync<I, O, R>(f: (I, completionHandler: (O, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> I throws -> O {
	return { input in
		let group = Group()
		var error: ErrorType?, output: O!
		
		group.enter()
		start(f(input) {
			(output, error) = ($0, $1)
			group.leave()
			})
		group.wait()
		
		if let error = error { throw error }
		return output
	}
}

public func toSync<I, O, R, E: ErrorType>(f: (I, completionHandler: (O, E?) -> ()) -> R, start: R -> () = { _ in }) -> I throws -> O {
	return { input in
		let group = Group()
		var error: E?, output: O!
		
		group.enter()
		start(f(input) {
			(output, error) = ($0, $1)
			group.leave()
			})
		group.wait()
		
		if let error = error { throw error }
		return output
	}
}

public func toSync<I0, R>(f: (I0, completionHandler: (ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0) throws -> () {
	return toSync({ i, ch in f(i) { ch((), $0) } }, start: start)
}
public func toSync<I0, R, E: ErrorType>(f: (I0, completionHandler: (E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0) throws -> () {
	return toSync({ i, ch in f(i) { ch((), $0) } }, start: start)
}
public func toSync<I0, O0, O1, R>(f: (I0, completionHandler: (O0, O1, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0) throws -> (O0, O1) {
	return toSync({ i, ch in f(i) { ch(($0, $1), $2) } }, start: start)
}
public func toSync<I0, O0, O1, R, E: ErrorType>(f: (I0, completionHandler: (O0, O1, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0) throws -> (O0, O1) {
	return toSync({ i, ch in f(i) { ch(($0, $1), $2) } }, start: start)
}
public func toSync<I0, O0, O1, O2, R>(f: (I0, completionHandler: (O0, O1, O2, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0) throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(i) { ch(($0, $1, $2), $3) } }, start: start)
}
public func toSync<I0, O0, O1, O2, R, E: ErrorType>(f: (I0, completionHandler: (O0, O1, O2, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0) throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(i) { ch(($0, $1, $2), $3) } }, start: start)
}
public func toSync<I0, O0, O1, O2, O3, R>(f: (I0, completionHandler: (O0, O1, O2, O3, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0) throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(i) { ch(($0, $1, $2, $3), $4) } }, start: start)
}
public func toSync<I0, O0, O1, O2, O3, R, E: ErrorType>(f: (I0, completionHandler: (O0, O1, O2, O3, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0) throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(i) { ch(($0, $1, $2, $3), $4) } }, start: start)
}

public func toSync<R>(f: (completionHandler: (ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> () {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<R, E: ErrorType>(f: (completionHandler: (E?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> () {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, R>(f: (I0, I1, completionHandler: (ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> () {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, R, E: ErrorType>(f: (I0, I1, completionHandler: (E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> () {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, R>(f: (I0, I1, I2, completionHandler: (ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> () {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, R, E: ErrorType>(f: (I0, I1, I2, completionHandler: (E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> () {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, R>(f: (I0, I1, I2, I3, completionHandler: (ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> () {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, R, E: ErrorType>(f: (I0, I1, I2, I3, completionHandler: (E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> () {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}

public func toSync<O0, R>(f: (completionHandler: (O0, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> (O0) {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<O0, R, E: ErrorType>(f: (completionHandler: (O0, E?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> (O0) {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, O0, R>(f: (I0, I1, completionHandler: (O0, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> (O0) {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, O0, R, E: ErrorType>(f: (I0, I1, completionHandler: (O0, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> (O0) {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, R>(f: (I0, I1, I2, completionHandler: (O0, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> (O0) {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, R, E: ErrorType>(f: (I0, I1, I2, completionHandler: (O0, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> (O0) {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, R>(f: (I0, I1, I2, I3, completionHandler: (O0, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0) {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, R, E: ErrorType>(f: (I0, I1, I2, I3, completionHandler: (O0, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0) {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}

public func toSync<O0, O1, R>(f: (completionHandler: (O0, O1, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> (O0, O1) {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<O0, O1, R, E: ErrorType>(f: (completionHandler: (O0, O1, E?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> (O0, O1) {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, R>(f: (I0, I1, completionHandler: (O0, O1, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> (O0, O1) {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, R, E: ErrorType>(f: (I0, I1, completionHandler: (O0, O1, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> (O0, O1) {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, R>(f: (I0, I1, I2, completionHandler: (O0, O1, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1) {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, R, E: ErrorType>(f: (I0, I1, I2, completionHandler: (O0, O1, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1) {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, R>(f: (I0, I1, I2, I3, completionHandler: (O0, O1, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1) {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, R, E: ErrorType>(f: (I0, I1, I2, I3, completionHandler: (O0, O1, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1) {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}

public func toSync<O0, O1, O2, R>(f: (completionHandler: (O0, O1, O2, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<O0, O1, O2, R, E: ErrorType>(f: (completionHandler: (O0, O1, O2, E?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, O2, R>(f: (I0, I1, completionHandler: (O0, O1, O2, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, O2, R, E: ErrorType>(f: (I0, I1, completionHandler: (O0, O1, O2, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, O2, R>(f: (I0, I1, I2, completionHandler: (O0, O1, O2, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, O2, R, E: ErrorType>(f: (I0, I1, I2, completionHandler: (O0, O1, O2, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, O2, R>(f: (I0, I1, I2, I3, completionHandler: (O0, O1, O2, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, O2, R, E: ErrorType>(f: (I0, I1, I2, I3, completionHandler: (O0, O1, O2, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1, O2) {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}

public func toSync<O0, O1, O2, O3, R>(f: (completionHandler: (O0, O1, O2, O3, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<O0, O1, O2, O3, R, E: ErrorType>(f: (completionHandler: (O0, O1, O2, O3, E?) -> ()) -> R, start: R -> () = { _ in }) -> () throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, O2, O3, R>(f: (I0, I1, completionHandler: (O0, O1, O2, O3, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, O2, O3, R, E: ErrorType>(f: (I0, I1, completionHandler: (O0, O1, O2, O3, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1) throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(i.0, i.1, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, O2, O3, R>(f: (I0, I1, I2, completionHandler: (O0, O1, O2, O3, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, O2, O3, R, E: ErrorType>(f: (I0, I1, I2, completionHandler: (O0, O1, O2, O3, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(i.0, i.1, i.2, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, O2, O3, R>(f: (I0, I1, I2, I3, completionHandler: (O0, O1, O2, O3, ErrorType?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, O2, O3, R, E: ErrorType>(f: (I0, I1, I2, I3, completionHandler: (O0, O1, O2, O3, E?) -> ()) -> R, start: R -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1, O2, O3) {
	return toSync({ i, ch in f(i.0, i.1, i.2, i.3, completionHandler: ch) }, start: start)
}