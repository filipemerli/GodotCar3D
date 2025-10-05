shader_type spatial;

// Gradient colors - set these in the inspector
uniform vec4 color_low : source_color = vec4(0.0, 0.3, 0.0, 1.0);  // Dark green
uniform vec4 color_mid : source_color = vec4(0.0, 0.75, 0.05, 1.0);  // Green
uniform vec4 color_high : source_color = vec4(0.4, 0.28, 0.1, 1.0); // Brown

// Height thresholds
uniform float height_min : hint_range(-100.0, 0.0) = -10.0;
uniform float height_mid : hint_range(-100.0, 100.0) = 0.0;
uniform float height_max : hint_range(0.0, 100.0) = 20.0;

varying float vertex_height;

void vertex() {
    // Store the local Y position in world space
    vertex_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
    vec3 final_color;
    
    if (vertex_height < height_mid) {
        // Below zero: interpolate between dark green and green
        float t = clamp((vertex_height - height_min) / (height_mid - height_min), 0.0, 1.0);
        final_color = mix(color_low.rgb, color_mid.rgb, t);
    } else {
        // Above zero: interpolate between green and brown
        float t = clamp((vertex_height - height_mid) / (height_max - height_mid), 0.0, 1.0);
        final_color = mix(color_mid.rgb, color_high.rgb, t);
    }
    
    ALBEDO = final_color;
}