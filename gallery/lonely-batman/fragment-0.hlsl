// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// SPDX-FileCopyrightText: © 2022 Sébastien Maire
// SPDX-FileCopyrightText: © 2022 Stanislas Daniel Claude Dolcini

Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings {
    float  Time;
    float  Scale;
    float2 Resolution;
    float4 Background;
};

#define sat(a) clamp(a, 0., 1.)
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
    float timeOffset = 0.0075*sin(uv.y*30.-Time* 0.5);
    uv.x+=sin(uv.y*25.+Time*2.)*0.01*sat(uv.y*5.);
    float2 tuv = mul((uv-float2(0.14+timeOffset,-.015)), r2d(3.3*PI));
    tuv.x = abs(tuv.x);
    tuv = (tuv-float2(-.07,0.));
    float2 tuv2 = -mul((uv+float2(0.04+timeOffset,0.015)), r2d(1.7*PI));
    tuv2.x = abs(tuv2.x);
    tuv2 = (tuv2-float2(-.07,0.));


    uv -= float2(0.05,-.04);
    float body = 10.;
    float anhears = 0.1;
    float2 offhears = float2(0.01,0.);
    body = min(body, _sqr(mul((uv+offhears),r2d(anhears)), float2(.025,.07)));
    body = min(body, _sqr(mul((uv-offhears),r2d(-anhears)), float2(.025,.07)));
    body = max(body, -_sqr(mul((uv-float2(0.,.08)),r2d(PI/4.)), float2(.03, .03)));
    uv.x = abs(uv.x);
    float tail = _cir(tuv, .11);
    body = min(body, tail);
    float tail2 = _cir(tuv2, .11);
    body = min(body, tail2);


    float carveCircle = _cir(uv - float2(0.17,0.01), 0.065);
    body = max(body, -carveCircle);
    carveCircle = _cir(uv - float2(0.09,-0.07), 0.066 );
    body = max(body, -carveCircle);

    return body;
}

float _eyes(float2 uv)
{
    uv.x+=sin(uv.y*25.+Time*2.)*0.01*sat(uv.y*5.);
    uv -= float2(0.05,-.012);
    float body = 1.;
    float square_width = 0.014;
    float square_height = 0.007;
    body = min(body, _sqr(mul((uv-float2(0.0, 0.01)),r2d(0)), float2(square_width, square_height)));
    body = max(body, -_sqr(mul((uv-float2(0.0, 0.02)),r2d(0)), float2(square_width * 6.0,  0.019 )));
    body = max(body, -_sqr(mul((uv-float2(0.0, 0.02)),r2d(PI)), float2(square_width * 0.9,  0.018 * 2)));
    float square_width_01 = 0.045;
    body = max(body, -_sqr(mul((uv-float2(0.0, 0.05)),r2d(PI/4.)), float2(square_width_01, square_width_01)));

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

    float3 sunCol = float3(0.239,0.761,1.000);
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

    float eyes = _eyes(uv);
    float3 eyecolor = float3( 0., 0.6, 0.);
    foreground = lerp(foreground, eyecolor * 1.2, 0.35 -clamp( sat(eyes * shp * 0.15), 0.0, 0.35));
    foreground = lerp(foreground, eyecolor, 1.0 - max(sat(eyes * shp * 0.6), 0.6));
    foreground = lerp(foreground, eyecolor, 1.0 - max(sat(eyes * shp * 0.6), 0.6));
    foreground = lerp(foreground, eyecolor, 1.0 - max(sat(eyes * shp * 0.6), 0.6));

    float mask = _cir(uv, .25);

    float3 col = lerp(background, foreground, 1.-sat(mask*shp));
    col += (1.-sat(length(uv*3.)))*sunCol*.7;

    col = lerp(col, sunCol , sat(length(uv)-.1)*(1.-sat(_stars(uv*.8, float2(5.,5.))*shp*.3))*.7);
    float4 color = shaderTexture.Sample(samplerState, texUv);
    col = lerp(col, col*sunCol, sat(length(uv)));
    col = lerp(col*.75, sat(color.rgb), sat(color.a));
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
