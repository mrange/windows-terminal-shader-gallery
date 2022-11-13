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

#define sat(a) clamp(a, 0., 1.)
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

float _nimal(float2 uv)
{

    uv.x+=sin(uv.y*25.+Time*2.)*0.01*sat(uv.y*5.);
    float2 tuv = mul((uv-float2(0.11+0.01*sin(uv.y*30.-Time*4.),-.05)), r2d(PI/4.));

    tuv.x = abs(tuv.x);
    tuv = (tuv-float2(-.07,0.));
    float tail = _cir(tuv, .1);
    uv -= float2(0.05,-.03);
    float body = 10.;
    
    float anhears = 0.1;
    float2 offhears = float2(0.01,0.);
    body = min(body, _sqr(mul((uv+offhears),r2d(anhears)), float2(.025,.07)));
    body = min(body, _sqr(mul((uv-offhears),r2d(-anhears)), float2(.025,.07)));
    body = max(body, -_sqr(mul((uv-float2(0.,.08)),r2d(PI/4.)), float2(.03, .03)));
    uv.x = abs(uv.x);
    body = min(body, _cir(uv*float2(1.,.8)-float2(.02,-0.04),.03));
    body = min(body, _cir(uv*float2(1.,.8)-float2(.048,-0.058),.005));
    body = min(body, tail);
    return body;
}

float _star(float2 p, float2 s)
{
    float a = _sqr(p, s.xy);
    float b = _sqr(p, s.yx);
    return min(a, b);
}

float _stars(float2 uv, float2 szu)
{
    uv = mul(r2d(PI/4.), uv);
	uv += float2(0.5,0.5);
    float2 ouv = uv;
    float th = 0.002;
    float2 rep = float2(0.1,0.1);

    float2 idx = floor((uv+rep*.5)/rep);
    
    uv = fmod(uv+rep*.5, rep)-rep*.5;
    float sz = sat(sin(idx.x*5.+idx.y+Time))*sat(length(ouv*2.)-.5);
    return _star(uv, float2(20.*th, th)*.15*sz*szu);
}

float3 rdr(float2 uv, float2 texUv)
{
    float shp = 400.;
    float3 background = float3(0.431,0.114,0.647)*.2;
    
    background = lerp(background, float3(1.000,0.761,0.239), 1.-sat(_stars(uv, float2(1.,1.0))*shp));
    
    float3 sunCol = float3(1.000,0.761,0.239);
    float3 foregroundBack = float3(0.345,0.125,0.494);
    
    float3 foreground;
    
    float sun = _cir(uv, .02);
    float sstp = 0.05;
    sun = floor(sun/sstp)*sstp;
    foreground = lerp(foregroundBack, sunCol, 1.-sat(sun*4.));
    
    float mount = uv.y-asin(sin(uv.x*25.))*.01+.1;
    foreground = lerp(foreground, foreground*.3, 1.-sat(mount*shp*.5));
    
    float mount2 = uv.y-(sin(uv.x*25.+2.))*.05+.1;
    foreground = lerp(foreground, foreground*.5, 1.-sat(mount2*shp*.1));

    
    float hill = _cir(uv-float2(0.,-.9), .8);
    foreground = lerp(foreground, float3(0.,0.,0.), 1.-sat(hill*shp));

    float nanimal = _nimal(uv);
    foreground = lerp(foreground, float3(0.,0.,0.), 1.-sat(nanimal*shp));
    
    
    float mask = _cir(uv, .25);
    
    float3 col = lerp(background, foreground, 1.-sat(mask*shp));
    col += (1.-sat(length(uv*3.)))*sunCol*.7;
    
    col = lerp(col, float3(1.000,0.761,0.239), sat(length(uv)-.1)*(1.-sat(_stars(uv*.8, float2(5.,5.))*shp*.3))*.7);
	float4 color = shaderTexture.Sample(samplerState, texUv);
	col = lerp(col, col*sunCol, sat(length(uv)));
	float3 txtCol = .5+lerp(float3(255, 223, 120)/255., float3(255, 120, 185)/255., sat(sin(Time+10.*length(uv))));
	col = lerp(col*.5, sat(color.rgb*txtCol), sat(color.a));
    return col;
}

float4 mainImage(float2 tex) : TARGET
{
    float2 uv = (tex.xy*float2(1.,-1.)-float2(0.5,-0.5))/(Resolution.xx/Resolution.xy);

    float3 col = rdr(uv, tex);

    return float4(col,1.0);
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
	return mainImage(tex);
}