# Resources

Open `ShaderInitiation.xcodeproj`

You want to edit `EX_<n>.fsh` in the `Shaders` folder.

Change the shader used by the app in `ViewController.swift`


### EX_1 hello world

A pixel's color is expressed as a vector  `vec4(r, g ,b ,a);`

The pixel color should be assigned to `gl_FragColor`

Now fill the screen with blue color


### EX_2 draw a rectangle at the center of the screen (0.0, 0.0)

Using the utility function `is_coordinates_within_rectangle`, draw a white rectangle.

You can use `DZR_RECTANGLE` as input parameter to get the correct size.


### EX_3 Translate the rectangle

Translate the origin of the Cartesian coordinate system.

We want to draw the logo from the bottom right of it.

To achieve this we need to translate our coordinate system to the correct position.

More on this here https://thebookofshaders.com/08/


### EX_4 Draw a column using a for loop

Draw 3 vertical rectangles using `is_coordinates_within_rectangle()` multiple times.

Translate the origin of the Cartesian coordinate system between each loop.

Increment `coordinates.y` by `DZR_RECTANGLE.y + DZR_RECTANGLE_MARGIN`.


### EX_5 Add colors to the logo

Using the `color_for_index_path` helper function, draw the Deezer logo with colors.


### EX_6 Animation !

Using the helper function `num_of_rectangles_for_column_animated` animate the logo.

Uncomment `setupPlayer()` in `ViewController.swift` for audio


For smooth animations on the simulator, you might want to use a lower resolution.

Uncomment `glkView.contentScaleFactor = 0.25` in `ViewController.swift` to do so.


### Bonus steps

Using HSV color space and `u_time` uniform, change the logo's colors over time.

Code use example provided in `ShaderDemo.vsh`

```
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
```

