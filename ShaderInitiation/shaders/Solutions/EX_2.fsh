
#ifdef GL_ES
precision highp float;
#endif

// object size
#define DZR_RECTANGLE           vec2(0.171, 0.0428)
#define DZR_RECTANGLE_MARGIN    0.0214

// uniforms
uniform vec2            u_resolution;
varying mediump vec2    v_tex_coord;

// test if pixel is within a rectangle
// 0 no 1 yes
// to understand how this works you can have a look here https://thebookofshaders.com/07/
float is_coordinates_within_rectangle(in vec2 coordinates, in vec2 size) {
    size = vec2(0.5) - size*0.5;
    vec2 uv = smoothstep(size,
                         size+vec2(0.001),
                         coordinates);
    uv *= smoothstep(size,
                     size+vec2(0.001),
                     vec2(1.0)-coordinates);
    return uv.x*uv.y;
}

void main() {
    // get back the coordinates in (0. <-> 1.) space
    // (0.0, 0.0) is in the center of the screen
    vec2 coordinates = v_tex_coord.yx / u_resolution.xy;
    
    vec4 black_color = vec4(0.0);
    vec4 color = black_color;
    
    float is_inside_rectangle = is_coordinates_within_rectangle(coordinates, DZR_RECTANGLE);
    
    color += vec4(is_inside_rectangle);
    
    gl_FragColor = color;
}
