// The MIT License (MIT)
//
// Copyright (c) 2015 Thomas Visser
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public func progress(@autoclosure fn: () -> ()) -> Progress {
    return progress(100, fn)
}

public func progress(totalUnitCount: Int64, @autoclosure fn: () -> ()) -> Progress {
    return progress { source in
        source.becomeCurrentWithPendingUnitCount(source.totalUnitCount)
        fn()
        source.resignCurrent()
    }
}

public func progress(@noescape fn: ProgressSource -> ()) -> Progress {
    return progress(100, fn)
}

public func progress(totalUnitCount: Int64, @noescape fn: ProgressSource -> ()) -> Progress {
    let source = ProgressSource(totalUnitCount: totalUnitCount)
    fn(source)
    return source.progress
}

public func progress<T>(totalUnitCount: Int64, @noescape fn: ProgressSource -> (T)) -> (Progress, T) {
    let source = ProgressSource(totalUnitCount: totalUnitCount)
    let res = fn(source)
    return (source.progress, res)
}

typealias KVOContext = UnsafeMutablePointer<UInt8>

public class Progress : NSObject {
    let fractionCompletedKVOContext = KVOContext()
    
    internal let progress: NSProgress

    public typealias ProgressCallback = (Double) -> ()
    
    private var progressCallbacks = [ProgressCallback]()
    
    private let callbackSemaphore = dispatch_semaphore_create(1)
    
    public init(progress: NSProgress) {
        assert(progress.goodProgressObject == nil)
        self.progress = progress
        
        super.init()
        
        self.progress.goodProgressObject = self
        
        // hook to NSProgress
        self.progress.addObserver(self, forKeyPath: "fractionCompleted", options: nil, context: self.fractionCompletedKVOContext)
    }
    
    deinit {
        self.progress.removeObserver(self, forKeyPath: "fractionCompleted")
    }
    
    public convenience init(totalUnitCount: Int64) {
        self.init(progress: NSProgress(totalUnitCount: totalUnitCount))
    }
    
    internal convenience init(parent: NSProgress, userInfo: [NSObject:AnyObject]?) {
        self.init(progress: NSProgress(parent: parent, userInfo: userInfo))
    }
    
    override public func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == self.fractionCompletedKVOContext {
            self.reportProgress()
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    public func onProgress(fn: ProgressCallback) -> Self {
        dispatch_semaphore_wait(self.callbackSemaphore, DISPATCH_TIME_FOREVER)
        if self.fractionCompleted < 1.0 {
            self.progressCallbacks.append { fraction in
                let keepAliveSelf = self
                fn(fraction)
            }
        }
        dispatch_semaphore_signal(self.callbackSemaphore)
        return self
    }
    
    internal func reportProgress() {
        dispatch_semaphore_wait(self.callbackSemaphore, DISPATCH_TIME_FOREVER)
        for progressCallback in self.progressCallbacks {
            progressCallback(self.fractionCompleted)
        }
        
        if self.fractionCompleted == 1.0 {
            progressCallbacks.removeAll()
        }
        dispatch_semaphore_signal(self.callbackSemaphore)
    }
    
}

// NSProgress proxy
extension Progress {
    public internal(set) var totalUnitCount: Int64 {
        get {
            return self.progress.totalUnitCount
        }
        set(newTotal) {
            self.progress.totalUnitCount = newTotal
        }
    }
    
    public internal(set) var completedUnitCount: Int64 {
        get {
            return self.progress.completedUnitCount
        }
        set(newUnitCount) {
            self.progress.completedUnitCount = newUnitCount
        }
    }
    
    public var fractionCompleted: Double {
        get {
            return self.progress.fractionCompleted
        }
    }
    
    public var localizedDescription: String {
        get {
            return self.progress.localizedDescription
        }
        set(newDescription) {
            self.progress.localizedDescription = newDescription
        }
    }
    
    public var localizedAdditionalDescription: String {
        get {
            return self.progress.localizedAdditionalDescription
        }
        set(newDescription) {
            self.progress.localizedAdditionalDescription = newDescription
        }
    }
    
    public internal(set) var cancellable: Bool {
        get {
            return self.progress.cancellable
        }
        set(newCancellable) {
            self.progress.cancellable = newCancellable
        }
    }
    
    public var cancelled: Bool {
        get {
            return self.progress.cancelled
        }
    }
    
    public func cancel() {
        assert(self.fractionCompleted < 1.0)
        self.progress.cancel()
    }
    
    public internal(set) var pausable: Bool {
        get {
            return self.progress.pausable
        }
        set(newPausable) {
            self.progress.pausable = newPausable
        }
    }
    
    public var paused: Bool {
        get {
            return self.progress.paused
        }
    }
    
    public func pause() {
        assert(self.fractionCompleted < 1.0)
        self.progress.pause()
    }
    
    public var indeterminate: Bool {
        get {
            return self.progress.indeterminate
        }
    }
    
    public var kind: String? {
        get {
            return self.progress.kind
        }
    }
    
    internal func becomeCurrentWithPendingUnitCount(pendingUnitCount: Int64) {
        self.progress.becomeCurrentWithPendingUnitCount(pendingUnitCount)
    }
    
    internal func resignCurrent() {
        self.progress.resignCurrent()
    }
    
    public class func currentProgress() -> Progress? {
        return NSProgress.currentProgress()?.goodProgressObject
    }
    
    public func setUserInfoObject(object: AnyObject?, forKey key: String) {
        self.progress.setUserInfoObject(object, forKey: key)
    }

}

private let GoodProgressObjectKey = UnsafePointer<Void>()

extension NSProgress {
    
    internal var goodProgressObject: Progress? {
        get {
            return objc_getAssociatedObject(self, GoodProgressObjectKey) as? Progress
        }
        set(newObject) {
            objc_setAssociatedObject(self, GoodProgressObjectKey, newObject, UInt(OBJC_ASSOCIATION_ASSIGN))
        }
    }
    
}
