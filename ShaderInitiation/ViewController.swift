//
//  ViewController.swift
//  ShaderInitiation
//
//  Created by adrien on 9/17/17.
//  Copyright © 2017 Adrien Coye de Brunelis. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation

struct Platform {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}

class ViewController: GLKViewController {

    //MARK: -
    
    //GL
    var context: EAGLContext?
    var program: ShaderProgram!
    var textureSize: TextureSize = TextureSize(width: 0, height: 0)
    var startTime: TimeInterval = 0.0
    
    // try out "ShaderDemo" (while playing music) within the `shaders/extra` folder
    let shader: Shader = Shader(baseName: "EX_1")
    
    // model
    let filteredData = FilteredData(lowPassFilterRatio: 0.2)
    
    // audio
    var audioEngine: AVAudioEngine!
    var audioNode: AVAudioPlayerNode!
    
    var power: Float = 0.0
    var previousPower: Float = 0.0
    var magnitudes : [Float] = []
    
    
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // gl setup
        setupGLContext()
        loadShader(shader: shader)
        
        ////////////////////////////////////////
        // uncomment for audio playback
//        setupPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateContextSize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateContextSize() {
        textureSize.width = Int(UIScreen.main.bounds.size.width)
        textureSize.height = Int(UIScreen.main.bounds.size.height)
        
        setupBuffers()
        
        program.setUniform(name: "u_rms", value: 0.0)
        program.setUniform(name: "u_vrms", value: GLKVector4(v: (0.0, 0.0, 0.0, 0.0)))
    }
    
    //MARK: Audio
    func setupPlayer() {
        audioEngine = AVAudioEngine()
        audioNode = AVAudioPlayerNode()
        audioEngine.attach(audioNode)
        
        guard let url = Bundle.main.url(forResource: "bensound-epic", withExtension: "mp3") else { return }  // checkout "bensound-dubstep" also

        guard let audioFile = try? AVAudioFile(forReading: url) else { return }
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
        try? audioFile.read(into: buffer)
        audioEngine.connect(audioNode, to: audioEngine.mainMixerNode, format: buffer.format)
        audioNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        
        let size: UInt32 = 1024
        audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: size, format: audioEngine.mainMixerNode.outputFormat(forBus: 0)) { (buffer, time) in
            buffer.frameLength = size
            
            if buffer.format.channelCount > 0 {
                if let _ = buffer.floatChannelData?[0] {
                    self.previousPower = self.power
                    
                    let fft = FFT.perform(buffer: buffer)
                    self.magnitudes = fft.magnitudes
                    self.power = fft.power
                }
            }
        }
        
        try? audioEngine.start()
        audioNode.play()
    }

    //MARK: GLES
    func setupGLContext() {
        context = EAGLContext.init(api: .openGLES2)
        
        let glkView: GLKView = self.view as! GLKView
        glkView.context = context!
        
        // fix performance for the iOS simulator, rendering at 1/4 resolution
        if Platform.isSimulator {
//            glkView.contentScaleFactor = 0.25
        }
        
        preferredFramesPerSecond = 60
    }
    
    func loadShader(shader: Shader) {
        startTime = Date.timeIntervalSinceReferenceDate
        
        EAGLContext.setCurrent(context!)
        program = ShaderProgram()
        if !program.load(shader: shader) {
            print("Error loading the shader")
        } else {
            print("Success loading the shader")
        }
        
        NoiseTexture.create(size: 256, slot: GLenum(GL_TEXTURE1))
    }
    
    func setupBuffers() {
        var positionVBO: GLuint = 0
        var texcoordVBO: GLuint = 0
        var indexVBO: GLuint = 0
        let square = SquareObject(size: textureSize)
        
        glGenBuffers(1, &indexVBO);
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexVBO);
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), 6 * MemoryLayout<GLint>.size, UnsafeRawPointer(square.index), GLenum(GL_STATIC_DRAW));
        
        glGenBuffers(1, &positionVBO);
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), positionVBO);
        glBufferData(GLenum(GL_ARRAY_BUFFER), 8 * MemoryLayout<GLfloat>.size, UnsafeRawPointer(square.vertex), GLenum(GL_STATIC_DRAW));
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue));
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(2 * MemoryLayout<GLfloat>.size), nil);
        
        glGenBuffers(1, &texcoordVBO);
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), texcoordVBO);
        glBufferData(GLenum(GL_ARRAY_BUFFER), 8 * MemoryLayout<GLfloat>.size, UnsafeRawPointer(square.coord), GLenum(GL_DYNAMIC_DRAW));
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue));
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(2 * MemoryLayout<GLfloat>.size), nil);
    }
    
    func update() {
        let time = GLfloat(Date.timeIntervalSinceReferenceDate - startTime)
        
        // overflow time counter in ms
        let overflowCounter = Int32(time*1000.0)
        
        // OGL-ES 2 highp float int range is 16-bit (minimum)
        // masking source to 16bit to avoid aliasing, will overflow nicely.
        let highpMask: Int32 = 0x0000ffff
        
        let maskedCounter = overflowCounter & highpMask
        let overflowTime = GLfloat(maskedCounter)/1000.0
        
        // timer and resolution
        program.setUniform(name: "u_time", value: overflowTime)
        program.setUniform(name: "u_resolution", value: GLKVector2(v: (1.0, 1.0)))
        
        // beat detect
        let diff = abs(self.power - self.previousPower);
        
        let clampedBeat = min(max(diff/10000.0, 0.0), 1.0)
        program.setUniform(name: "u_beat", value: clampedBeat)
        
        if diff > 10000 {
            //            print("beat")
        }
        
        guard self.magnitudes.count > 0 else { return }
        
        let a = self.magnitudes.map { $0/4096 } // adjusting scale
        filteredData.batchUpdate(input: a)
        
        program.setUniform(name: "u_rms", value: filteredData.lastRMS())
        program.setUniform(name: "u_vrms", value: filteredData.historyVectorSmooth)
        TextureLoader.load(data: filteredData.data,
                           slot: GLenum(GL_TEXTURE0))
        
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        if textureSize.height != 0 {
            DispatchQueue.main.async {
                self.update()
            }
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
            glDrawElements(GLenum(GL_TRIANGLE_STRIP), 12, GLenum(GL_UNSIGNED_SHORT), nil)
        }
    }

}

