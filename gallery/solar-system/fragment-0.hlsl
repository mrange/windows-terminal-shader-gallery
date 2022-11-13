// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

// Data provided by Windows Terminal
Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings {
	float  Time;
	float  Scale;
	float2 Resolution;
	float4 Background;
};

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



#define PI 3.141592653

float2x2 r2d(float a) { float c= cos(-a), s = sin(-a); return float2x2(c,-s,s,c);}

float _cir(float2 uv, float r)
{
    return length(uv)-r;
}

float _sqr(float2 p, float2 s)
{
    float2 l = abs(p)-s;
    return max(l.x, l.y);
}
float _star(float2 p, float2 s)
{
    p = mul(p,r2d(PI/4.));
    float a = _sqr(p, s);
    float b = _sqr(p, s.yx);
    return min(a, b);
}
float _stars(float2 uv)
{
    float2 ouv = uv;
    float th = 0.002;
    float2 rep = float2(0.1,0.1);

    float2 idx = floor((uv+rep*.5)/rep);
    
    uv = fmod(uv+rep*.5, rep)-rep*.5;
    uv += sin(length(idx)*10.)*rep*.25;
    float sz = saturate(sin(idx.x*5.+idx.y+Time+length(ouv)*10.))*saturate(length(ouv*2.)-.5);
    return _star(uv, float2(20.*th, th)*.5*sz);
}

float3 rdr(float2 uv, float2 texUv)
{
    float3 col = float3(0.173,0.145,0.129)*(1.-saturate(length(uv)-.5));
    float3 rgb = float3(1.000,0.000,0.349);
    
    float th = 0.002;
    float shp = 400.;
    
    float sun = _cir(uv, .1);
    float innerSun = max(sun, (sin((uv.x+uv.y)*200.+Time*10.)+.7)*5.);
    sun = abs(sun)-th;
    innerSun = min(sun, innerSun);
    col = lerp(col, rgb, 1.-saturate(innerSun*shp));
    
    float ta=Time*.5;
    float2 pa = uv-float2(sin(ta), cos(ta))*.5;
    float pla = _cir(pa, .04);
    pla = abs(pla)-th;
    pla = min(pla, _sqr(mul(pa,r2d(-PI/4.)), float2(.08, th)));
    col = lerp(col, rgb, 1.-saturate(pla*shp));
    
    float tb = Time;
    float2 pb = uv-float2(sin(tb), cos(tb))*.2;
    float plb = _cir(pb, .02);
    col = lerp(col, rgb, 1.-saturate(plb*shp));
    
    float tc = Time*.7;
    float2 pc = uv-float2(sin(tc), cos(tc))*.3;
    float plc = _cir(pc, .05);
    col = lerp(col, rgb,  1.-saturate(plc*shp));
    
    float stars = _stars(uv+float2(1.,1.));
    col = lerp(col, rgb, 1.-saturate(stars*shp));
    
    col += .5*saturate(float3(1.000,0.000,0.298)*1.)*(1.-saturate(length(uv)));
    
    col *= .7*lerp(float3(1.000,0.000,0.298), float3(0.,0.,0.), saturate(length(uv)));

    col = lerp(col, col.zyx, saturate(length(uv)));
    uv = mul(uv, r2d(Time*.1));
    uv += (sin(length(uv)*2.)*.5+.5)*.15;
    
	/*col += saturate(length(uv))*saturate(length(uv))*
    lerp(float3(1.000,0.122,0.427), float3(1.000,0.710,0.078), saturate(length(uv)));
	*/
	float4 color = shaderTexture.Sample(samplerState, texUv);
	col = lerp(col, col, saturate(length(uv)));
	float3 txtCol = float3(1.000,0.000,0.349);//lerp(float3(255, 223, 120)/255., float3(255, 120, 185)/255., saturate(sin(Time+10.*length(uv))));
	col = lerp(col*.75, saturate(color.rgb*txtCol), saturate(color.a));
    return col;
}

float4 mainImage(float2 tex) : TARGET
{
    //Time = Time*.5;//+texture(iChannel0, fragCoord/8.).x*iTimeDelta;
    float2 uv = (tex.xy*float2(1.,-1.)-float2(0.5,-0.5))/(Resolution.xx/Resolution.xy);
    uv *= 2.+sin(Time*.5);
    float3 col  = rdr(uv, tex).zxy;
    for (int i = 0; i < 16; ++i)
    {
        float f = (float(i)/16.)*.5;
        float coef = 1.-saturate(float(i)/16.);
        col += rdr(uv*(1.-f*.1), tex)*coef*.3;
    }
    col = pow(col, float3(1.,1.,1.));
    return float4(col,1.0);
}
float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
	return mainImage(tex);
}