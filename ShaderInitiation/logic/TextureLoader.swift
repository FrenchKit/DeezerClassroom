//
//  TextureLoader.swift
//  Knitstagram
//
//  Created by Arthur Guibert on 09/01/2017.
//  Copyright © 2017 Arthur Guibert. All rights reserved.
//

import GLKit

final class TextureLoader {
    
    class func load(name: String, slot: GLenum) {
        glActiveTexture(slot)
        if let path = Bundle.main.path(forResource: name, ofType: "png") {
            if let extra = try? GLKTextureLoader.texture(withContentsOfFile: path, options: nil) {
                glBindTexture(extra.target, extra.name);
                glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_REPEAT));
                glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_REPEAT));
            }
        }
    }
    
    class func load(data: [Float], slot: GLenum) {
        TextureLoader.load(data: data, width: Int(data.count), height: 1, slot: slot)
    }
    
    class func load(data: [Float], width: Int, height: Int, slot: GLenum) {
        var texture: GLuint = 0
        var raw: [GLubyte] = []
        
        for i in 0..<data.count {
            let value = GLubyte( max(min(data[i] * 255.0, Float(UInt8.max)), Float(UInt8.min)) )
            raw.append(value) // R
            raw.append(value) // G
            raw.append(value) // B
            raw.append(value) // A
        }
        
        glActiveTexture(slot)
        
        glGenTextures(1, &texture)
        glBindTexture(GLenum(GL_TEXTURE_2D), texture);
        
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT);
        
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), raw);
        
    }
}
