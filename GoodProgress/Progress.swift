//
//  Progress.swift
//  GoodProgress
//
//  Created by Thomas Visser on 19/01/15.
//  Copyright (c) 2015 Thomas Visser. All rights reserved.
//

import Foundation

typealias KVOContext = UnsafeMutablePointer<UInt8>

public class Progress : NSObject {
    let fractionCompletedKVOContext = KVOContext()
    
    private let progress: NSProgress
    public typealias ProgressCallback = (Double) -> ()
    
    private var progressCallbacks = [ProgressCallback]()
    
    private var cancellationReported = false
    private var pausingReported = false
    
    private let callbackSemaphore = dispatch_semaphore_create(1)
    
    public init(progress: NSProgress) {
        self.progress = progress
        super.init()
        
        // hook to NSProgress
        self.progress.addObserver(self, forKeyPath: "fractionCompleted", options: nil, context: self.fractionCompletedKVOContext)
    }
    
    deinit {
        self.progress.removeObserver(self, forKeyPath: "fractionCompleted")
    }
    
    public convenience init(totalUnitCount: Int64) {
        self.init(progress: NSProgress(totalUnitCount: totalUnitCount))
    }
    
    public convenience init(parent: NSProgress, userInfo: [NSObject:AnyObject]?) {
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
    
    func reportProgress() {
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
    public var totalUnitCount: Int64 {
        get {
            return self.progress.totalUnitCount
        }
    }
    
    public var completedUnitCount: Int64 {
        get {
            return self.progress.completedUnitCount
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
    
    public var cancellable: Bool {
        get {
            return self.progress.cancellable
        }
    }
    
    public var cancelled: Bool {
        get {
            return self.cancelled
        }
    }
    
    public func cancel() {
        assert(self.fractionCompleted < 1.0)
        self.progress.cancel()
    }
    
    public var pausable: Bool {
        get {
            return self.progress.pausable
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
    
    

}

public class MutableProgress : Progress {
    
    public typealias CancellationCallback = () -> ()
    public typealias PausingCallback = () -> ()
    
    private var cancellationCallbacks = [CancellationCallback]()
    private var pausingCallbacks = [PausingCallback]()
    
    public override init(progress: NSProgress) {
        super.init(progress: progress)
        
        self.progress.cancellationHandler = { [weak self] in
            self?.reportCancellation()
            return
        }
    }
    
    public func captureProgress(pendingUnitCount: Int64, fn: () -> ()) {
        self.becomeCurrentWithPendingUnitCount(pendingUnitCount)
        fn()
        self.resignCurrent()
    }
    
    public func onCancel(fn: CancellationCallback) -> Self {
        dispatch_semaphore_wait(self.callbackSemaphore, DISPATCH_TIME_FOREVER)
        if self.cancellationReported {
            if self.cancelled {
                fn()
            }
        } else {
            self.cancellationCallbacks.append {
                let keepAliveSelf = self
                fn()
            }
        }
        dispatch_semaphore_signal(self.callbackSemaphore)
        return self
    }
    
    public func onPause(fn: PausingCallback) -> Self {
        dispatch_semaphore_wait(self.callbackSemaphore, DISPATCH_TIME_FOREVER)
        if self.pausingReported {
            if self.paused {
                fn()
            }
        } else {
            self.pausingCallbacks.append {
                let keepAliveSelf = self
                fn()
            }
        }
        dispatch_semaphore_signal(self.callbackSemaphore)
        return self
    }
    
    func reportCancellation() {
        dispatch_semaphore_wait(self.callbackSemaphore, DISPATCH_TIME_FOREVER)
        assert(self.cancelled)
        
        for cancellationCallback in self.cancellationCallbacks {
            cancellationCallback()
        }
        
        self.cancellationCallbacks.removeAll()
        self.cancellationReported = true
        dispatch_semaphore_signal(self.callbackSemaphore)
    }
    
    func reportPausing() {
        dispatch_semaphore_wait(self.callbackSemaphore, DISPATCH_TIME_FOREVER)
        assert(self.paused)
        
        for pausingCallback in self.pausingCallbacks {
            pausingCallback()
        }
        
        self.pausingCallbacks.removeAll()
        self.pausingReported = true
        dispatch_semaphore_signal(self.callbackSemaphore)
    }
}

// NSProgress proxy
extension MutableProgress {
    public override var completedUnitCount: Int64 {
        get {
            return self.progress.completedUnitCount
        }
        set(newUnitCount) {
            self.progress.completedUnitCount = newUnitCount
        }
    }
    
    public override var totalUnitCount: Int64 {
        get {
            return super.totalUnitCount
        }
        set(newTotal) {
            self.progress.totalUnitCount = newTotal
        }
    }
    
    public func becomeCurrentWithPendingUnitCount(pendingUnitCount: Int64) {
        self.progress.becomeCurrentWithPendingUnitCount(pendingUnitCount)
    }
    
    public func resignCurrent() {
        self.progress.resignCurrent()
    }
    
    public override var cancellable: Bool {
        get {
            return self.progress.cancellable
        }
        set(newCancellable) {
            self.progress.cancellable = cancellable
        }
    }
    
    public override var pausable: Bool {
        get {
            return self.progress.pausable
        }
        set(newPausable) {
            self.progress.pausable = newPausable
        }
    }
    
    public func setUserInfoObject(object: AnyObject?, forKey key: String) {
        self.progress.setUserInfoObject(object, forKey: key)
    }
}


public func progress(fn: MutableProgress -> ()) -> Progress {
    return progress(100, fn)
}

public func progress(totalUnitCount: Int64, fn: MutableProgress -> ()) -> Progress {
    let progress = MutableProgress(totalUnitCount: totalUnitCount)
    fn(progress)
    return Progress(progress: progress.progress)
}

public func progress<T>(totalUnitCount: Int64, fn: MutableProgress -> (T)) -> (Progress, T) {
    let progress = MutableProgress(totalUnitCount: totalUnitCount)
    let res = fn(progress)
    return (Progress(progress: progress.progress), res)
}
