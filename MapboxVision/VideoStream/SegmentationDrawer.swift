//
//  SegmentationDrawer.swift
//  cv-assist-ios
//
//  Created by Maksim on 5/16/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import VisionCore

final class SegmentationDrawer: NSObject, MTKViewDelegate {
    
    private let device: MTLDevice
    
    private var source: MTLTexture?
    private var mask: MTLTexture?
    
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLComputePipelineState
    
    init?(device: MTLDevice) {
        self.device = device
        
        guard
            let commandQueue = device.makeCommandQueue(),
            let library = try? device.makeDefaultLibrary(bundle: Bundle(for: SegmentationDrawer.self)),
            let function = library.makeFunction(name: "blend"),
            let pipelineState = try? device.makeComputePipelineState(function: function)
        else {
            assertionFailure("SegmentationDrawer: Can't work properly with MTLDevice")
            return nil
        }
        
        self.commandQueue = commandQueue
        self.pipelineState = pipelineState
    }
    
    func set(_ segMask: SegmentationMask) {
        source = segMask.sourceImage.getTexture();
        mask = segMask.segmentationMaskImage.getTexture();
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        #if !targetEnvironment(simulator)
        guard
            let drawable = view.currentDrawable,
            let source = source,
            let mask = mask,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeComputeCommandEncoder()
        else { return }
        
        encoder.setTexture(source, index: 0)
        encoder.setTexture(mask, index: 1)
        encoder.setTexture(drawable.texture, index: 2)
        ComputeDispatcher.dispathPipeline(pipelineState, encoder: encoder, texture: drawable.texture)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        #endif
    }
}



