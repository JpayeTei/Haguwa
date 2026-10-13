shader_type spatial;

void vertex() {
	//vec3 uv = UV - 0.5;
//	float d = length(uv);
	float r = 0.5;
	float c = 0.0;
	COLOR = vec4(c, c, c, 2);
	
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
