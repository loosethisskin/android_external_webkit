/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "config.h"
#import "LayerTreeHostCA.h"

#import "WebProcess.h"
#import <QuartzCore/CATransaction.h>
#import <WebCore/GraphicsLayer.h>
#import <WebKitSystemInterface.h>

@interface CATransaction (Details)
+ (void)synchronize;
@end

namespace WebKit {

void LayerTreeHostCA::platformInitialize()
{
    mach_port_t serverPort = WebProcess::shared().compositingRenderServerPort();
    m_remoteLayerClient = WKCARemoteLayerClientMakeWithServerPort(serverPort);

    [m_rootLayer->platformLayer() setGeometryFlipped:YES];

    WKCARemoteLayerClientSetLayer(m_remoteLayerClient.get(), m_rootLayer->platformLayer());

    m_layerTreeContext.contextID = WKCARemoteLayerClientGetClientId(m_remoteLayerClient.get());
}

void LayerTreeHostCA::scheduleLayerFlush()
{
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    
    // Make sure we wake up the loop or the observer could be delayed until some other source fires.
    CFRunLoopWakeUp(currentRunLoop);

    if (m_flushPendingLayerChangesRunLoopObserver)
        return;

    // Run before the Core Animation commit observer, which has order 2000000.
    const CFIndex runLoopOrder = 2000000 - 1;
    CFRunLoopObserverContext context = { 0, this, 0, 0, 0 };
    m_flushPendingLayerChangesRunLoopObserver.adoptCF(CFRunLoopObserverCreate(0, kCFRunLoopBeforeWaiting | kCFRunLoopExit, true, runLoopOrder, flushPendingLayerChangesRunLoopObserverCallback, &context));

    CFRunLoopAddObserver(currentRunLoop, m_flushPendingLayerChangesRunLoopObserver.get(), kCFRunLoopCommonModes);
}

void LayerTreeHostCA::platformInvalidate()
{
    if (m_flushPendingLayerChangesRunLoopObserver) {
        CFRunLoopObserverInvalidate(m_flushPendingLayerChangesRunLoopObserver.get());
        m_flushPendingLayerChangesRunLoopObserver = nullptr;
    }

    WKCARemoteLayerClientInvalidate(m_remoteLayerClient.get());
    m_remoteLayerClient = nullptr;
}

void LayerTreeHostCA::platformSizeDidChange()
{
    [CATransaction flush];
    [CATransaction synchronize];
}

void LayerTreeHostCA::platformForceRepaint()
{
    [CATransaction flush];
    [CATransaction synchronize];
}    

void LayerTreeHostCA::flushPendingLayerChangesRunLoopObserverCallback(CFRunLoopObserverRef, CFRunLoopActivity, void* context)
{
    // This gets called outside of the normal event loop so wrap in an autorelease pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    static_cast<LayerTreeHostCA*>(context)->performScheduledLayerFlush();
    [pool drain];
}

void LayerTreeHostCA::platformDidPerformScheduledLayerFlush()
{
    // We successfully flushed the pending layer changes, remove the run loop observer.
    ASSERT(m_flushPendingLayerChangesRunLoopObserver);
    CFRunLoopObserverInvalidate(m_flushPendingLayerChangesRunLoopObserver.get());
    m_flushPendingLayerChangesRunLoopObserver = 0;
}

} // namespace WebKit
