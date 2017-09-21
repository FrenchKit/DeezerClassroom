// GLSL Shader.
//
//  Created by Adrien Coye de Brunélis on 30/01/17.

#ifdef GL_ES
precision highp float;
#endif

#define PI 3.14159265359
#define PI_2 6.28318530718

uniform vec2            u_resolution;
varying mediump vec2    v_tex_coord;

uniform float           u_time;
uniform vec4            u_vrms;

// colors
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 shiftColor(vec3 rgbColor, float shift) {
    vec3 hsvColor = rgb2hsv(rgbColor);
    hsvColor.x = shift;
    return hsv2rgb(hsvColor);
}

// math
mat2 rotate2d(in float angle){
    return mat2(cos(angle),-sin(angle),
                sin(angle),cos(angle));
}

// shapes
float rect(in vec2 st, in vec2 size, in float smoothness){
    size = 0.25-size*0.25;
    vec2 uv = smoothstep(size, size+smoothness,st*(1.0-st));
    return uv.x*uv.y;
}

void main() {
    
    float rms_x = u_vrms.x;
    float rms_y = u_vrms.y;
    float rms_z = u_vrms.z;
    float rms_w = u_vrms.w;
    
    float pow_value = 2.0;
    float rms_pow_x = clamp(pow(rms_x, pow_value), 0., 1.);
    float rms_pow_y = clamp(pow(rms_y, pow_value), 0., 1.);
    float rms_pow_z = clamp(pow(rms_z, pow_value), 0., 1.);
    float rms_pow_w = clamp(pow(rms_w, pow_value), 0., 1.);
    
    float rms_e = clamp(exp(rms_x)-1., 0., 1.);
    
    // tinker with effects
    vec4 blurLevel = vec4(0.001, 0.002, 0.0035, 0.005);
    
    float time = u_time;
    float timeScale = 8.;
    float frameTime = .016*124.;
    vec4 timeSin = vec4(sin(time/timeScale),
                        sin((time-frameTime)/timeScale),
                        sin((time-frameTime*2.)/timeScale),
                        sin((time-frameTime*3.)/timeScale));
    
    vec2 st = v_tex_coord.yx / u_resolution.xy;
    st.x += sin(time) / 4.0;
    st.y += sin(time/2.0) / 4.0;
    
    vec3 baseColor_x = vec3(1.0,0.5,1.0);
    vec3 baseColor_y = vec3(1.0,0.4,1.0);
    vec3 baseColor_z = vec3(1.0,0.3,1.0);
    vec3 baseColor_w = vec3(1.0,0.2,1.0);
    
    vec3 color_front =      shiftColor(baseColor_x, rms_x);
    vec3 color_mid =        shiftColor(baseColor_y, rms_y);
    vec3 color_back =       shiftColor(baseColor_z, rms_z);
    vec3 color_back_back =  shiftColor(baseColor_w, rms_w);
    
    vec3 influencing_color_A =  vec3(0.132,0.281,0.425);
    vec3 influencing_color_B =  vec3(0.340,0.078,0.075);
    
    vec3 color = vec3(0.);
    
    // Background Gradient
    color = mix(shiftColor(influencing_color_A, timeSin.x),
                shiftColor(influencing_color_B, timeSin.w),
                sin(5.0*st.x/PI));
    
    // Background rectangles
    {
        vec2 size_back = vec2(0.05,0.7);
        vec2 h_offset_back = vec2(0.3, 0.);
        vec2 v_offset_back = h_offset_back.yx;
        
        // rotate
        vec2 bg_st = st;
        bg_st -= vec2(0.5);
        bg_st = rotate2d(rms_w*PI_2) * bg_st;
        bg_st += vec2(0.5);
        
        color = mix(color,
                    color_back_back,
                    rect(bg_st+h_offset_back,size_back, blurLevel.w));
        color = mix(color,
                    color_back_back,
                    rect(bg_st+v_offset_back,size_back.yx, blurLevel.w));
        
        color = mix(color,
                    color_back_back,
                    rect(bg_st-h_offset_back,size_back, blurLevel.w));
        color = mix(color,
                    color_back_back,
                    rect(bg_st-v_offset_back,size_back.yx, blurLevel.w));
    }
    
    {
        vec2 size_back = vec2(0.04,0.8);
        vec2 h_offset_back = vec2(0.3, 0.);
        vec2 v_offset_back = h_offset_back.yx;
        
        // rotate
        vec2 bg_st = st;
        bg_st -= vec2(0.5);
        bg_st = rotate2d(rms_z*PI_2) * bg_st;
        bg_st += vec2(0.5);
        
        color = mix(color,
                    color_back,
                    rect(bg_st+h_offset_back,size_back, blurLevel.z));
        color = mix(color,
                    color_back,
                    rect(bg_st+v_offset_back,size_back.yx, blurLevel.z));
        
        color = mix(color,
                    color_back,
                    rect(bg_st-h_offset_back,size_back, blurLevel.z));
        color = mix(color,
                    color_back,
                    rect(bg_st-v_offset_back,size_back.yx, blurLevel.z));
    }
    
    // Middleground rectangle
    {
        vec2 size_mid = vec2(0.03,0.9);
        vec2 h_offset_mid = vec2(0.3, 0.0);
        vec2 v_offset_mid = h_offset_mid.yx;
        
        // rotate
        vec2 m_st = st;
        m_st -= vec2(0.5);
        m_st = rotate2d(rms_y*PI_2) * m_st;
        m_st += vec2(0.5);
        
        color = mix(color,
                    color_mid,
                    rect(m_st+h_offset_mid,size_mid, blurLevel.y));
        color = mix(color,
                    color_mid,
                    rect(m_st+v_offset_mid,size_mid.yx, blurLevel.y));
        
        color = mix(color,
                    color_mid,
                    rect(m_st-h_offset_mid,size_mid, blurLevel.y));
        color = mix(color,
                    color_mid,
                    rect(m_st-v_offset_mid,size_mid.yx, blurLevel.y));
    }
    
    // Foreground rectangle
    {
        vec2 size_front = vec2(0.02,1.0);
        vec2 h_offset_front = vec2(0.3,0.0);
        vec2 v_offset_front = h_offset_front.yx;
        
        // rotate
        vec2 fg_st = st;
        fg_st -= vec2(0.5);
        fg_st = rotate2d(rms_x*PI_2) * fg_st;
        fg_st += vec2(0.5);
        
        color = mix(color,
                    color_front,
                    rect(fg_st+h_offset_front,size_front, blurLevel.x));
        color = mix(color,
                    color_front,
                    rect(fg_st+v_offset_front,size_front.yx, blurLevel.x));
        
        color = mix(color,
                    color_front,
                    rect(fg_st-h_offset_front,size_front, blurLevel.x));
        color = mix(color,
                    color_front,
                    rect(fg_st-v_offset_front,size_front.yx, blurLevel.x));
    }
    
    gl_FragColor = vec4(color,1.0);
}
