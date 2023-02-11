#define WINDOWS_TERMINAL

Texture2D shaderTexture;
SamplerState samplerState;

// --------------------
#if defined(WINDOWS_TERMINAL)
cbuffer PixelShaderSettings {
  float  Time;
  float  Scale;
  float2 Resolution;
  float4 Background;
};

#define TIME        Time
#define RESOLUTION  Resolution
#else
float time;
float2 resolution;

#define TIME        time
#define RESOLUTION  resolution
#endif
// --------------------

// --------------------
// GLSL => HLSL adapters
#define vec2  float2
#define vec3  float3
#define vec4  float4
#define mat2  float2x2
#define mat3  float3x3
#define fract frac
#define mix   lerp

float mod(float x, float y) {
  return x - y * floor(x/y);
}

vec2 mod(vec2 x, vec2 y) {
  return x - y * floor(x/y);
}

static const vec2 unit2 = vec2(1.0, 1.0);
static const vec3 unit3 = vec3(1.0, 1.0, 1.0);
static const vec4 unit4 = vec4(1.0, 1.0, 1.0, 1.0);

// --------------------

#define PI          3.141592654
#define TAU         (2.0*PI)

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float hexagon(vec2 p, float r) {
  const vec3 k = 0.5*vec3(-sqrt(3.0), 1.0, sqrt(4.0/3.0));
  p = abs(p);
  p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
  p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
  return length(p)*sign(p.y);
}

static const float igamma = 2.0;
static const vec3 bgcol0 = pow(vec3(164.0, 124.0, 222.0)/255.0, unit3*(igamma));
static const vec3 bgcol1 = pow(vec3(037.0, 000.0, 104.0)/255.0, unit3*(igamma));
static const vec3 bgcol2 = pow(vec3(055.0, 000.0, 147.0)/255.0, unit3*(igamma));
static const vec3 white  = unit3*(1.0);

vec4 csharp(vec2 p, float aa, out float d) {

  vec2 pp = p;
  pp.y = abs(pp.y);

  float l = length(p);
  float hd  = hexagon(p.yx, 0.4)-0.1;
  float fsd = dot(normalize(vec2(-1.0, sqrt(3.0))), p);
  float rsd = dot(normalize(vec2(-1.0, -sqrt(3.0))), p);
  float cd  = abs(l-0.25)-0.08;
  float sd  = max(fsd, rsd);
  float bd  = abs(l-0.25)-0.03;
  bd        = abs(bd) - 0.0125;
  float dd  = dot(normalize(vec2(-1.0, 2.9)), pp);
  bd        = max(bd, dd);
  float ld  = dot(normalize(vec2(-1.0, 7.0)), pp);
  ld        = abs(ld) - 0.0125;
  bd        = min(bd, ld);
  float od  = abs(l-0.25)-0.0666;
  bd        = max(bd, od);

  vec3 bgcol = mix(bgcol0, bgcol1, smoothstep(aa, -aa, fsd));

  vec3 col = (0.0);
  float t = smoothstep(aa, -aa, hd);

  col = bgcol;
  col = mix(col, white  , smoothstep(aa, -aa, cd));
  col = mix(col, bgcol2 , smoothstep(aa, -aa, sd));
  col = mix(col, white  , smoothstep(aa, -aa, bd));
  d = hd;

  return vec4(col, t);
}

vec3 effect(vec2 p, vec2 pp) {
  const float off = 0.95;
  const float freq = TAU*1.5;
  const float aam = freq*cos(off);

  float d;
  float aa = 2.0/RESOLUTION.y;
  vec4 cc = csharp(p, aa, d);

  vec3 col  = 0.1*sqrt(bgcol2);
  col += bgcol2*exp(-20.0*d*d);
  col += bgcol0*smoothstep(-aa*aam+off, aa*aam+off, sin(freq*(1.0*d)+TAU*TIME/20.0))/(1.0+4.0*dot(p, p));
  col = mix(col, cc.xyz, cc.w);
  col = mix(col, white  , smoothstep(aa, -aa, abs(d+0.02)-0.0125));
  col *= smoothstep(1.25, 0.0, length(pp));
  col = sqrt(col);
  return col;

}

//
// PS_OUTPUT ps_main(in PS_INPUT In)
#if defined(WINDOWS_TERMINAL)
float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
#else
float4 ps_main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
#endif
{
  vec2 q = tex;
  vec2 p = -1.0 + 2.0*q;
  vec2 pp = p;
#if defined(WINDOWS_TERMINAL)
  p.y = -p.y;
#endif
  float r = RESOLUTION.x/RESOLUTION.y;
  p.x *= r;

  vec3 col = effect(p, pp);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
