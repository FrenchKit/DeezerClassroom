//
//  NoiseTexture.swift
//  Knitstagram
//
//  Created by Arthur Guibert on 15/03/17.
//  Copyright © 2017 Knitstagram SA. All rights reserved.
//

import GLKit

final class NoiseTexture {
    class func create(size: Int, slot: GLenum) {
        var noise = vFloat()
        
        for _ in 0..<size*size {
            noise.append((Float)(arc4random() & 255) / 255.0);
        }
        
        TextureLoader.load(data: noise, width: size, height: size, slot: slot)
    }
}
