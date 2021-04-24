#version 420

layout(location = 0) in vec3 inPos;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec3 inNormal;
layout(location = 3) in vec2 inUV;
layout(location = 4) in vec4 inFragPosLightSpace;

in vec4 gl_FragCoord;

struct DirectionalLight
{
	//Light direction (defaults to down, to the left, and a little forward)
	vec4 _lightDirection;

	//Generic Light controls
	vec4 _lightCol;

	//Ambience controls
	vec4 _ambientCol;
	float _ambientPow;
	
	//Power controls
	float _lightAmbientPow;
	float _lightSpecularPow;
	
	float _shadowBias;
};

layout (std140, binding = 0) uniform u_Lights
{
	DirectionalLight sun;
};


uniform sampler2D s_Diffuse;
uniform sampler2D s_Diffuse2;
uniform sampler2D s_Specular;

uniform float u_TextureMix;
uniform vec3  u_CamPos;

layout (binding = 29) uniform sampler2D s_DepthBuffer;
uniform float u_waterTransparency;

uniform float u_windowWidth;
uniform float u_windowHeight;


uniform float u_shoreCutoff;
uniform float u_midCutoff;

uniform vec4 u_deepColor;
uniform vec4 u_midColor;
uniform vec4 u_shoreColor;


out vec4 frag_color;

float linearize_depth(float d,float zNear,float zFar)
{
	float z_n = 2.0*d-1.0;
	return 2.0*zNear * zFar / (zFar+zNear-z_n*(zFar - zNear));
}


// https://learnopengl.com/Advanced-Lighting/Advanced-Lighting
void main() {
	vec2 scrennUV = vec2(gl_FragCoord.x/u_windowWidth,gl_FragCoord.y/u_windowHeight);
	float expectedDepth = linearize_depth(texture(s_DepthBuffer,scrennUV).x,0.01,1000.0);

	float actualDepth = linearize_depth(gl_FragCoord.z,0.01,1000.0);
	float depthDiff = expectedDepth - actualDepth;

	float deep = 0.0;
	float mid = 0.0;
	float shore = 0.0;


	shore = max(0,depthDiff-(u_midCutoff+u_shoreCutoff))/(depthDiff-(u_midCutoff+u_shoreCutoff));
	mid = max(0,depthDiff-u_shoreCutoff)/(depthDiff-u_shoreCutoff);
	deep = 0.0;


	// Diffuse
	vec3 N = normalize(inNormal);
	vec3 lightDir = normalize(-sun._lightDirection.xyz);
	float dif = max(dot(N, lightDir), 0.0);
	vec3 diffuse = dif * sun._lightCol.xyz;// add diffuse intensity

	// Specular
	vec3 viewDir  = normalize(u_CamPos - inPos);
	vec3 h        = normalize(lightDir + viewDir);

	// Get the specular power from the specular map
	float texSpec = texture(s_Specular, inUV).x;
	float spec = pow(max(dot(N, h), 0.0), 4.0); // Shininess coefficient (can be a uniform)
	vec3 specular = sun._lightSpecularPow * texSpec * spec * sun._lightCol.xyz; // Can also use a specular color

	// Get the albedo from the diffuse / albedo map
	vec4 textureColor1 = texture(s_Diffuse, inUV);
	vec4 textureColor2 = texture(s_Diffuse2, inUV);
	vec4 textureColor = mix(textureColor1, textureColor2, u_TextureMix);


	vec3 result = (
		(sun._ambientPow * sun._ambientCol.xyz) + // global ambient light

		(diffuse + specular) // light factors from our single light
		) * inColor * mix(textureColor,u_shoreColor,shore).rgb
		*(shore
		+(u_midColor.rgb*mid)
		+(u_deepColor.rgb*deep)); // Object color
	frag_color = vec4(depthDiff,depthDiff,depthDiff, u_waterTransparency);
	//frag_color = vec4(result, u_waterTransparency);

}