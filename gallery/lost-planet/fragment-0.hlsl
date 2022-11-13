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


#define sat(a) clamp(a, 0., 1.)
float2x2 r2d(float a) { float c = cos(a), s = sin(a); return float2x2(c, -s, s, c); }

float2 _min(float2 a, float2 b)
{
    if(a.x < b.x)
        return a;
    return b;
}

float2 map(float3 p)
{
    p.xy = mul(r2d(.25), p.xy);
    //p.xz = mul(r2d(.25), p.xy);

    p -= float3(1.,1.2,0.);
    float2 acc = float2(10000.,-1.);
    float shape = length(p)-1.;
    shape = max(shape, -(length(p.xy)-.5));
    shape = max(shape, -(length(p)-.8));
    float mat = 0.0;
    if (length(p) > .9)
    {
        mat = 1.;
        float th = 0.04;
        if (abs(length(p.xz)-.2)-th < 0.)
            mat = 3.;
        if (abs(length(p.yz)-.2)-th < 0.)
            mat = 3.;
    }
       
    if (length(p.xy) < .51)
        mat = 2.;

        
    acc = _min(acc, float2(shape, mat));
    
    float antena = max(max(length(p.xz)-.015, p.y+.5), -p.y-2.);
    antena = min(antena, length(p-float3(0.,-2.,0.))-.1);
    acc = _min(acc, float2(antena, 0.));
    return acc;
}

float grass(float2 uv)
{
    uv.x+= sin(uv.y*20.+Time)*.02;
    float h= lerp(.01,.02, sat(sin(uv.x)*.5+.5));
    return uv.y-h*asin(sin(uv.x*250.+sin(uv.y*2.)*20.+sat(3.+uv.y*15.)*Time));
}

float3 getCam(float3 rd, float2 uv)
{
    float3 r = normalize(cross(rd, float3(0.,1.,0.)));
    float3 u = normalize(cross(rd, r));
    return normalize(rd+r*uv.x+u*uv.y);
}

float3 getNorm(float3 p, float d)
{
  float2 e = float2(0.01,0.);
  return normalize(float3(d,d,d)-float3(map(p-e.xyy).x,map(p-e.yxy).x,map(p-e.yyx).x));
}
float3 trace(float3 ro, float3 rd, int steps)
{
  float3 p = ro;
  for (int i = 0; i<steps;++i)
  {
    float2 res = map(p);
    if (res.x<0.01)
      return float3(res.x,distance(p,ro),res.y);
    p+= rd*res.x;
  }
  return float3(-1.,-1.,-1.);
}

float3 rdr(float2 uv)
{
    float2 buv = uv;
    float baseT = Time*.2;
    float t = sin(baseT)*.5;
    float3 col = lerp(float3(0.694,0.827,0.824), float3(0.796,0.882,0.871), sat(-uv.y));
    
    float xA = uv.x+t*.125;
    float mountA = uv.y+.1-0.05*sin(xA*5.)+0.01*asin(sin(xA*10.));
    float3 mountACol = lerp(float3(0.627,0.710,0.690)*.8, float3(0.702,0.784,0.765), sat(sin(14.6*length(float2(xA,uv.y)-float2(0.2,1.))*10.)*sin(length(float2(xA,uv.y)-float2(0.,1.))*50.)*1000.));
    col = lerp(col, mountACol, 1.-sat(mountA*40000.));
    float xB = uv.x+t*.25;
    float mountB = uv.y+.1-0.02*sin(xB*10.)+0.01*asin(sin(xB*10.));
    col = lerp(col, float3(0.729,0.553,0.541), 1.-sat(mountB*40000.));
    
    float3 ro = float3(sin(t)*10.,0.,10.*cos(t));
    float3 ta = float3(t*4.,0.,0.);
    float3 rd = normalize(ta-ro);
    
    rd = getCam(rd, buv);
    
    float3 res = trace(ro, rd, 32);
    
    if (res.y > 0.)
    {
        float3 p = ro+rd*res.y;
        float3 n = getNorm(p, res.x);
        float3 ldir = normalize(float3(1.,-1.,1.));
        
        col = n*.5+.5;
        if (res.z == 0.)
            col = float3(.1,.1,.1);
        if (res.z == 1. || res.z == 3.)
            col = lerp(float3(.8,.8,.8), float3(.92,.92,.92), sat(dot(n,ldir)*100.));
        if (res.z == 2.)
            col = float3(.4,.4,.4);
        if (res.z == 3.)
            col *= .75;
    }
    
    
    float xC = uv.x+t*.5;
    float mountC = uv.y+.15-0.02*sin(xC*7.)+0.01*asin(sin(xC*10.));
    col = lerp(col, float3(0.824,0.392,0.388), 1.-sat(mountC*40000.));
    

    float xD = uv.x+t;
    float mountD = uv.y+.17-0.02*sin(-xD*10.+4.)+0.015*asin(sin(xD*7.));
    mountD += .2+grass(uv);
    col = lerp(col, float3(0.776,0.314,0.314), 1.-sat(mountD*40000.));
    float xE = uv.x+t*2.;
    float mountE = uv.y+.3-0.04*sin(-xE*10.+4.)+0.015*asin(sin(xE*7.));
    mountE += .2+grass(uv);
    col = lerp(col, float3(0.541,0.173,0.173), 1.-sat(mountE*40000.));
    uv.y -= .2;
    float xCloud = uv.x+t*.0125;
    float cloud =  max(uv.y-asin(sin(xCloud*5.))*.02-sin(xCloud*5.-Time*.25)*.03, -(uv.y+.03-.02*(sin(xCloud*5.+Time*.25))));
    
    col = lerp(col, float3(0.776,0.875,0.863), 1.-sat(cloud*40000.));
    
    //col = float3(1.)*sat(*40000.);
//    float t3d = Time*.1;

    
    return col;
}
 
float4 mainImage(float2 tex) : TARGET
{
	float2 ouv = tex.xy*float2(1.,-1.)-float2(0.5,-0.5);
	float2 uv = (tex.xy*float2(1.,-1.)-float2(0.5,-0.5))/(Resolution.xx/Resolution.xy);
	float2 xy = tex.xy;
	
	float4 blurTextColor = float4(0.0,0.0,0.0,0.0);
    //float2 uv = (fragCoord-.5*iResolution.xy)/iResolution.xx;

	float stp = .005;
    
    uv = floor(uv/stp)*stp;
    float3 col = rdr(uv);
	float stpb = 1.0/4.;
	float acc = 0.0f;
	float4 textColor =	shaderTexture.Sample(samplerState, xy);
				float diffTest = distance(col, textColor);
				// TODO clean this mess (too lazy now)
				/*
    for (float x = -1.; x < 1.; x += stpb)
	{
		for (float y = -1.; y < 1.; y += stpb)
		{
			float coef = 1.-saturate(length(float2(x, y)));

			blurTextColor += shaderTexture.Sample(samplerState, 0.*-0.004*float2(1.,1.)+xy+float2(x, y)*0.01)*coef;
			acc += coef;
		}

	}*/
	blurTextColor = blurTextColor/acc;

	float coefVisi =1.;// pow(1.-saturate(diffTest), 3.);
	//col = lerp(col, float3(0.,0.,0.), saturate(blurTextColor.w*coefVisi));
	//col = lerp(col, float3(0.,0.,0.), 0.3);
	float angle = 3.14159265;
	float c = cos(angle);
	float s = sin(angle);
	float originalA = textColor.w;
	float4x4 hueRotation =	
					float4x4( 	 0.299,  0.587,  0.114, 0.0,
					    	 0.299,  0.587,  0.114, 0.0,
					    	 0.299,  0.587,  0.114, 0.0,
					   		 0.000,  0.000,  0.000, 1.0) +
		
					float4x4(	 0.701, -0.587, -0.114, 0.0,
							-0.299,  0.413, -0.114, 0.0,
							-0.300, -0.588,  0.886, 0.0,
						 	 0.000,  0.000,  0.000, 0.0) * c +
		
					float4x4(	 0.168,  0.330, -0.497, 0.0,
							-0.328,  0.035,  0.292, 0.0,
							 1.250, -1.050, -0.203, 0.0,
							 0.000,  0.000,  0.000, 0.0) * s;
	col = lerp(col, float3(1.,1.,1.), (1.-saturate(ouv.y+.5))*0.5);
	//textColor.xyz = mul(hueRotation, 1.-textColor.xyz);
		textColor.w = originalA;
	//col = lerp(col, textColor, pow(textColor.w,3.));
	col = lerp(col, (col)*textColor.xyz*saturate(1.-length(textColor.xyz)+.8), pow(textColor.w,2.));
	if (length(col) < 0.3)
		col += textColor.xyz;
    float4 colorret = float4(col,1.0);
	
	return colorret;
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
	return mainImage(tex);
}