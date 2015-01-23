//
//  ProgressSource.swift
//  GoodProgress
//
//  Created by Thomas Visser on 21/01/15.
//  Copyright (c) 2015 Thomas Visser. All rights reserved.
//

import Foundation

public class ProgressSource {
    
    public typealias CancellationCallback = () -> ()
    public typealias PausingCallback = () -> ()
    
    private var cancellationCallbacks = [CancellationCallback]()
    private var pausingCallbacks = [PausingCallback]()
    
    public let progress: Progress
    
    private let callbackSemaphore = dispatch_semaphore_create(1)
    private let completionSemaphore = dispatch_semaphore_create(1)
    
    private var cancellationReported = false
    private var pausingReported = false
    
    public init(totalUnitCount: Int64 = 100) {
        self.progress = Progress(totalUnitCount: totalUnitCount)
        
        self.progress.progress.cancellationHandler = { [weak self] in
            self?.reportCancellation()
            return
        }
    }
    
    public var totalUnitCount: Int64 {
        get {
            return self.progress.totalUnitCount
        }
        set(newTotalUnitCount) {
            self.progress.totalUnitCount = newTotalUnitCount
        }
    }
    
    public var completedUnitCount: Int64 {
        get {
            return self.progress.completedUnitCount
        }
    }
    
    public var cancellable: Bool {
        get {
            return self.progress.cancellable
        }
        set(newCancellable) {
            self.progress.cancellable = newCancellable
        }
    }
    
    public var pausable: Bool {
        get {
            return self.progress.pausable
        }
        set(newPausable) {
            self.progress.pausable = newPausable
        }
    }
    
    public func completeUnit() {
        dispatch_semaphore_wait(self.completionSemaphore, DISPATCH_TIME_FOREVER)
        self.progress.completedUnitCount++
        dispatch_semaphore_signal(self.completionSemaphore)
    }
    
    public func captureProgress(pendingUnitCount: Int64, fn: () -> ()) {
        self.progress.becomeCurrentWithPendingUnitCount(pendingUnitCount)
        fn()
        self.progress.resignCurrent()
    }
    
    public func becomeCurrentWithPendingUnitCount(pendingUnitCount: Int64) {
        self.progress.becomeCurrentWithPendingUnitCount(pendingUnitCount)
    }
    
    public func resignCurrent() {
        self.progress.resignCurrent()
    }
    
    public func onCancel(fn: CancellationCallback) -> Self {
        dispatch_semaphore_wait(self.callbackSemaphore, DISPATCH_TIME_FOREVER)
        if self.cancellationReported {
            if self.progress.cancelled {
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
            if self.progress.paused {
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
        assert(self.progress.cancelled)
        
        for cancellationCallback in self.cancellationCallbacks {
            cancellationCallback()
        }
        
        self.cancellationCallbacks.removeAll()
        self.cancellationReported = true
        dispatch_semaphore_signal(self.callbackSemaphore)
    }
    
    func reportPausing() {
        dispatch_semaphore_wait(self.callbackSemaphore, DISPATCH_TIME_FOREVER)
        assert(self.progress.paused)
        
        for pausingCallback in self.pausingCallbacks {
            pausingCallback()
        }
        
        self.pausingCallbacks.removeAll()
        self.pausingReported = true
        dispatch_semaphore_signal(self.callbackSemaphore)
    }
}