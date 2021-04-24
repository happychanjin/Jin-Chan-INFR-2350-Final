#version 420

layout(location = 0) in vec2 inUV;


in vec4 gl_FragCoord;


out vec4 frag_color;

layout (binding = 0) uniform sampler2D s_screenTex;

uniform float u_aperture;
uniform float u_focalLength;
uniform float u_planeInFocus;
uniform float u_zFar = 1000.0;
uniform float u_zNear   = 0.01;

uniform float u_windowWidth;
uniform float u_windowHeight;

layout (binding = 29) uniform sampler2D s_DepthBuffer;

float linearize_depth(float d,float zNear,float zFar)
{
	return -zFar * zNear / (d*(zFar - zNear) - zFar);
}

void main() 
{
	vec4 focusColor = texture(s_screenTex, inUV);

	vec2 scrennUV = vec2(gl_FragCoord.x/u_windowWidth,gl_FragCoord.y/u_windowHeight);
	float expectedDepth = linearize_depth(texture(s_DepthBuffer,inUV).x,u_zNear,u_zFar);
	float actualDepth = linearize_depth(gl_FragCoord.z,u_zNear,u_zFar);
	float depthDiff = abs(expectedDepth - actualDepth);

	float CoC = u_aperture  * (abs(depthDiff - u_focalLength) / depthDiff) * (u_planeInFocus / (u_focalLength - u_planeInFocus));
	float SensorHeight = 0.024;
	float PercentOfSensor =    CoC / SensorHeight;
	float BlurFactor = clamp(PercentOfSensor, 0.0, 1.0);

	  float offset = 1.0 / textureSize(s_screenTex, 0).x;
	float blur = 1.0;
		 vec4 shiftedColor = texture2D( s_screenTex , vec2( inUV.x - 4.0*blur*offset , inUV.y - 4.0*blur*offset )) * 0.0162162162;
         shiftedColor += texture2D( s_screenTex , vec2( inUV.x - 3.0*blur*offset , inUV.y - 3.0*blur*offset )) * 0.0540540541;
         shiftedColor += texture2D( s_screenTex , vec2( inUV.x - 2.0*blur*offset , inUV.y - 2.0*blur*offset )) * 0.1216216216;
         shiftedColor += texture2D( s_screenTex , vec2( inUV.x - 1.0*blur*offset , inUV.y - 1.0*blur*offset )) * 0.1945945946;
         shiftedColor += texture2D( s_screenTex , vec2( inUV.x , inUV.y )) * 0.2270270270;
         shiftedColor += texture2D( s_screenTex , vec2( inUV.x + 1.0*blur*offset , inUV.y + 1.0*blur*offset )) * 0.1945945946;
         shiftedColor += texture2D( s_screenTex , vec2( inUV.x + 2.0*blur*offset , inUV.y + 2.0*blur*offset )) * 0.1216216216;
         shiftedColor += texture2D( s_screenTex , vec2( inUV.x + 3.0*blur*offset , inUV.y + 3.0*blur*offset )) * 0.0540540541;
         shiftedColor += texture2D( s_screenTex , vec2( inUV.x + 4.0*blur*offset , inUV.y + 4.0*blur*offset )) * 0.0162162162;
          vec4 outOfFocusColor  = vec4( shiftedColor.rgb *1.05, 1.0 );
	

   frag_color = mix(focusColor ,outOfFocusColor ,BlurFactor);
}