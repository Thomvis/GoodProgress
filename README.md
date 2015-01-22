# GoodProgress
A delightful progress reporting framework for Swift powered by [NSProgress](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSProgress_Class/Reference/Reference.html).

NSProgress is a relatively new (iOS 7, OS X 10.9), often overlooked but awesome addition to the Cocoa framework. It provides a way to report the progress of long running tasks across threads and to pause or cancel those tasks. GoodProgress is a tiny wrapper around NSProgress that aims to make reporting progress super nice in Swift.

## Current State
GoodProgress is in very early stages of development. It should not be used for purposes other than experimentation, yet.

In the (bright) future, GoodProgress could be integrated with [BrightFutures](https://github.com/Thomvis/BrightFutures).

## Usage
Where NSProgress is just one class, GoodProgress splits its functionality into two classes: `Progress` and `ProgressSource`. `ProgressSource` is used where progress is being _made_, `Progress` is used to observe the progress and to pause or cancel the task. The latter is typically used in or near your view code. For example:

```swift
let progress = progress(self.loader.loadNextItems(5))
progress.onProgress { fraction in
	self.progressView.progress = fraction
}
```

Inside the `loadNextItems`, a `ProgressSource` can be used to report the progress:

```swift
func loadNextItems(numberOfItems: Int) {
	let source = ProgressSource(totalUnitCount: numberOfItems)
	dispatch_aync(queue, {
		for offset in 1...numberOfItems {
			self.loadItem(self.lastLoadedIndex+offset)
			source.completeUnit()
		}
		self.lastLoadedIndex += numberOfItems
	}
}
```

A `ProgressSource` can also combine the progress from multiple `ProgressSources`:

```swift
let source = ProgressSource(totalUnitCount: 100)

source.becomeCurrentWithPendingUnitCount(80)
self.loadImages()
source.resignCurrent()

source.becomeCurrentWithPendingUnitCount(20)
self.loadText()
source.resignCurrent()

source.progress.onProgress { fraction in
	println("progress: \(fraction)") // prints a value from 0.0 to 1.0
}
```

GoodProgress leverages the power of Swift to offer a nicer way to achive the same:

```swift
progress(100) { source in
	source.captureProgress(80) {
		self.loadImages()
	}

	source.captureProgress(20) {
		self.loadText()
	}
}.onProgress { fraction in
	println("progress: \(fraction)") // prints a value from 0.0 to 1.0
}
```

This example is functionally equivalent to the previous example, but much nicer to write and read.

## Contact
I am looking forward to your feedback. I am very much still learning Swift. We all are. Let me know how I could improve GoodProgress by creating an issue, a pull request or by reaching out on twitter. I'm [@thomvis88](https://twitter.com/thomvis88).

## License
GoodProgress is available under the MIT license. See the LICENSE file for more info.