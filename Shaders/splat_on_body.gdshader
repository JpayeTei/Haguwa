shader_type spatial;

// This is the coordinate of the poop hit. 
// We will pass this from GDScript.
uniform vec3 hit_position = vec3(0.0, 0.0, 0.0);

// How big the splat is
uniform float splat_radius : hint_range(0.0, 2.0) = 0.3;

// The color of the poop (brown)
uniform vec4 splat_color : source_color = vec4(0.3, 0.2, 0.1, 1.0);

// This stores the position of the current pixel we are drawing
varying vec3 local_vertex_position;

void vertex() {
    // Save the exact position of the model's vertices
    local_vertex_position = VERTEX;
}

void fragment() {
    // Calculate the distance between this pixel and the hit point
    float dist = distance(local_vertex_position, hit_position);
    
    // Create a smooth circle mask (1.0 inside the splat, 0.0 outside)
    // smoothstep makes the edges of the splat soft, not a hard pixelated circle
    float splat_mask = 1.0 - smoothstep(splat_radius * 0.5, splat_radius, dist);
    
    // Mix the original texture color with the poop color based on the mask
    ALBEDO = mix(ALBEDO, splat_color.rgb, splat_mask);
    
    // Optional: Make the splat look wet/gross by lowering roughness
    ROUGHNESS = mix(ROUGHNESS, 0.1, splat_mask);
}