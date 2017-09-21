
#ifdef GL_ES
precision highp float;
#endif

// object size
#define DZR_RECTANGLE           vec2(0.171, 0.0428)
#define DZR_RECTANGLE_MARGIN    0.0214

// dzr colors
#define DZR_RGB_VEC3(r, g, b) vec3(r/255.0, g/255.0, b/255.0)

#define DZR_RED_COLOR       DZR_RGB_VEC3(255.0,     0.0,    0.0)
#define DZR_YELLOW_COLOR    DZR_RGB_VEC3(255.0,     237.0,  0.0)
#define DZR_PURPLE_COLOR    DZR_RGB_VEC3(255.0,     0.0,    146.0)
#define DZR_GREEN_COLOR     DZR_RGB_VEC3(190.0,     214.0,  47.0)
#define DZR_BLUE_COLOR      DZR_RGB_VEC3(0.0,       199.0,  242.0)

#define DZR_RED_PASTEL_COLOR       DZR_RGB_VEC3(255.0,     170.0,    170.0)
#define DZR_PURPLE_PASTEL_COLOR    DZR_RGB_VEC3(255.0,     194.0,    229.0)
#define DZR_GREEN_PASTEL_COLOR     DZR_RGB_VEC3(221.0,     232.0,    155.0)
#define DZR_BLUE_PASTEL_COLOR      DZR_RGB_VEC3(193.0,     241.0,    252.0)

// uniforms
uniform vec2            u_resolution;
uniform sampler2D       u_texture;
varying mediump vec2    v_tex_coord;

uniform float           u_time;
uniform float           u_beat;
uniform vec4            u_vrms;

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

// number of items in a vertical stack
int num_of_rectangles_for_column (int section) {
    
    // no switch in GLSL _yet_  :/
    int offset = 0;
    if (section == 0) {
        offset = 2;
    } else if (section == 2) {
        offset = 4;
    } else if (section == 3) {
        offset = 2;
    } else if (section == 4) {
        offset = 5;
    }
    
    return 3 + offset;
}

// get a color for a rectangle
vec3 color_for_index_path(int column, int row) {
    
    vec3 color = vec3(1.0);
    if (column == 0) {
        if (row > 2) {
            color = DZR_RED_PASTEL_COLOR;
        } else {
            color = DZR_RED_COLOR;
        }
    } else if (column == 1) {
        color = DZR_YELLOW_COLOR;
    } else if (column == 2) {
        if (row > 2) {
            color = DZR_PURPLE_PASTEL_COLOR;
        } else {
            color = DZR_PURPLE_COLOR;
        }
    } else if (column == 3) {
        if (row > 2) {
            color = DZR_GREEN_PASTEL_COLOR;
        } else {
            color = DZR_GREEN_COLOR;
        }
    } else if (column == 4) {
        if (row > 2) {
            color = DZR_BLUE_PASTEL_COLOR;
        } else {
            color = DZR_BLUE_COLOR;
        }
    }
    
    return color;
}

int num_of_rectangles_for_column_animated (int section) {
    
    // apply pow funct to add some "oomph" to the effect
    float pow_value = 2.0;
    vec4 rms_pow = clamp(pow(u_vrms*vec4(10), vec4(pow_value)), 0.0, 1.0);
    
    int offset = 1;
    if (section == 0) {
        // use beat detection for this line
        offset = int(rms_pow.w * 5.0);
    } else if (section == 1) {
        offset = int(rms_pow.w * 3.0);
    } else if (section == 2) {
        offset = int(rms_pow.z * 7.0);
    } else if (section == 3) {
        offset = int(rms_pow.y * 5.0);
    } else if (section == 4) {
        offset = int(rms_pow.x * 7.0);
    }
    
    return offset;
}

void main() {
    // get back the coordinates in (0. <-> 1.) space
    // (0.0, 0.0) is in the center of the screen
    vec2 coordinates = v_tex_coord.yx / u_resolution.xy;
    
    // translate origin of system to the mid left corner
    coordinates.y -= 0.5;
    coordinates.x -= 0.387;
    
    vec2 coordinates_logo_origin = coordinates;
    
    vec4 black_color = vec4(0.0);
    vec4 color = black_color;
    
    // iterate columns
    for (int column_idx = 0; column_idx<5; column_idx ++) {
        
        // iterate vertical stack items
        int stack_size = num_of_rectangles_for_column_animated(column_idx);
        for (int row_idx=0; row_idx<stack_size; row_idx++) {
            
            float is_inside_rectangle = is_coordinates_within_rectangle(coordinates, DZR_RECTANGLE);
            
            vec3 color_at_index = color_for_index_path(column_idx, row_idx);
            
            color_at_index = color_at_index * vec3(is_inside_rectangle); // logical and
            color += vec4(color_at_index, 1.0);
            
            coordinates.y += DZR_RECTANGLE.y + DZR_RECTANGLE_MARGIN;
        }
        
        coordinates.y = coordinates_logo_origin.y;
        coordinates.x += DZR_RECTANGLE.x + DZR_RECTANGLE_MARGIN;
    }
    
    gl_FragColor = color;
}
