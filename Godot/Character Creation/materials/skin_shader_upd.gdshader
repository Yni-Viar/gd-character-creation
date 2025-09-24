shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx, sss_mode_skin;

/*

Copyright 2023 Petter Thowsen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

* anything inside MatMADNESS HumanShader block is made by MatMADNESS under MIT License. Full text below.

MIT License
Copyright (c) 2025 MatMADNESS

Permission is hereby granted, free of charge, to use, copy, modify, and
distribute this software as permitted under the MIT License.

This Shader is part of the Human Shaders collection by MatMADNESS
and is built upon https://github.com/RustyRoboticsBV/GodotStandardLightShader
*/


uniform sampler2D body_diffuse : source_color;
uniform sampler2D face_diffuse : source_color;
uniform sampler2D face_map : source_color, hint_default_black;
uniform sampler2D body_age : source_color, hint_default_transparent;
uniform float age_factor = 0.0;
uniform vec4 skin_color : source_color = vec4(1.000000, 1.000000, 1.000000, 1.000000);
uniform sampler2D body_overlay : source_color;
uniform sampler2D face_roughness : source_color;
uniform sampler2D body_bump : hint_normal;

//MatMADNESS Human Shader block
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform bool translucency = false;
uniform float translucency_strength : hint_range(0.0, 2.0, 0.01) = 0.75;
uniform sampler2D texture_translucency : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_translucency_color : source_color, filter_linear, repeat_disable;
varying float sss_tex;
//End block

void fragment() {
	//Body shader part
	vec4 body = texture(body_diffuse, UV);
	vec4 face = texture(face_diffuse, UV2);
	vec4 face_map_tex = texture(face_map, UV);
	vec3 body_basic = mix(vec3(body.xyz), vec3(face.xyz), vec3(face_map_tex.xyz));
	vec4 age_tex = texture(body_age, UV);
	vec3 age_setter = body_basic * vec3(age_tex.xyz);
	vec3 body_with_age = mix(body_basic, age_setter, age_factor);
	vec3 skinned_body = body_with_age * vec3(skin_color.xyz);
	//Face roughness
	vec4 face_rough = texture(face_roughness, UV2);
	//MatMADNESS Human Shader block
	sss_tex = texture(texture_translucency, UV).b;
	//End block
	//output
	ALBEDO = skinned_body * texture(body_overlay, UV).xyz;
	ROUGHNESS = mix(vec3(0.5), vec3(face_rough.xyz), vec3(face_map_tex.xyz)).x;
	NORMAL_MAP = texture(body_bump, vec2(UV * 10.0)).xyz;
}
//MatMADNESS Human Shader block
void light()
{
	// Calculate some vectors.
	vec3 lightColor = LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
	//normal_depth = 1.;
	if (translucency){
		float translucency_dot = dot(VIEW,-(LIGHT + NORMAL * .4));
		vec2 t_col_coord = vec2(sss_tex * translucency_dot * translucency_strength, 0.0);
		vec3 t_color = texture(texture_translucency_color, t_col_coord).rgb;
		vec3 translucent = max(translucency_dot * t_color, 0.0) * lightColor;
		//translucency *= max(translucency_strength, 1.);

		DIFFUSE_LIGHT += translucent;
	}
}

//End block