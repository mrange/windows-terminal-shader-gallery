// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================
// Code base stolen here 
// https://github.com/Hammster/windows-terminal-shaders

// Data provided by Windows Terminal
Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings {
	float  Time;
	float  Scale;
	float2 Resolution;
	float4 Background;
};


float permute(float x)
{
	x *= (34 * x + 1);
	return 289 * frac(x * 1 / 289.0f);
}

float rand(inout float state)
{
	state = permute(state);
	return frac(state / 41.0f);
}

float hash(float2 p)  // replace this by something better
{
    p  = 50.0*frac( p*0.3183099 + float2(0.71,0.113));
    return -1.0+2.0*frac( p.x*p.y*(p.x+p.y) );
}

float _noise( float2 p )
{
    float2 i = floor( p );
    float2 f = frac( p );
	
	float2 u = f*f*(3.0-2.0*f);

    return lerp( lerp( hash( i + float2(0.0,0.0) ), 
                     hash( i + float2(1.0,0.0) ), u.x),
                lerp( hash( i + float2(0.0,1.0) ), 
                     hash( i + float2(1.0,1.0) ), u.x), u.y);
}
#define sat(a) clamp(a, 0., 1.)
float4 mainImage(float2 tex) : TARGET
{
	float2 xy = tex.xy;
	
	float4 color = shaderTexture.Sample(samplerState, xy);


	float stp = 0.0001;
	tex = floor(((xy*Resolution.xy)/Resolution.xx)/stp)*stp;
	float3 m = float3(tex*.1, 0) + 1.;
	float state = permute(permute(m.x) + m.y) + m.z;
	
	float p = 0.95 * rand(state) + 0.025;
	float q = p - 0.5;
	float r2 = q * q;
	
	float noise = _noise(tex*500.0);// q * (a2 + (a1 * r2 + a0) / (r2 * r2 + b1 * r2 + b0));
	
	float3 back = lerp(float3(0.,0.,0.), 0.8*float3(88, 31, 173)/255., sat(xy.y));
	back += pow(clamp(noise, 0.0,1.0), 15.1)*1.0*float3(1.0,1.0,1.0);
	
	color.rgb = lerp(color.rgb, back, 1.0-sat(length(color.rgb))); 
	
	

	return color;
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
	return mainImage(tex);
}