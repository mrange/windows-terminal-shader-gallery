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

#define TIME        (0.5*Time)
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

// Solme AVIX
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

static const mat2 rot45 = ROT(radians(45.0));
static const vec3 dim = vec3(0.675, -0.025, 0.012);

vec2 off(float n) {
//  return vec2(-(1.5-n)*dim.x-dim.y, 0.0);
  return 0.5*sin(vec2(1.0, sqrt(0.5))*(TIME-1.25*n));
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pabs(float a, float k) {
  return -pmin(a, -a, k);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float segmentx(vec2 p, float off) {
  p.x -= off;
  float d0 = length(p);
  float d1 = abs(p.y);
  return p.x > 0.0 ? d0 : d1;
}

vec2 dBox(vec2 p) {
  p = mul(rot45, p);
  const float roff = 0.065;
  float d = box(p, (0.25-roff));
  float dd = d-0.18;
  d -= 0.0275+roff;
  d = abs(d);
  d -= dim.z;
  return vec2(d, dd);
}

vec2 dA(vec2 p) {
  p -= off(0.0);
  vec2 p0 = p;
  vec2 d0 = dBox(p0);
  vec2 p1 = p;
  const mat2 rot1 = ROT(radians(-62.0));
  p1.x = pabs(p1.x, dim.z*1.5);
  p1.x -= 0.095;
  p1.y += 0.075;
  p1 = mul(rot1, p1);
  float d1 = segmentx(p1, 0.03)-dim.z;
  vec2 p2 = p;
  p2.y -= -0.03;
  p2.x = abs(p2.x);
  float d2 = segmentx(p2, 0.07)-dim.z;
  float d = d0.x;
  d = min(d, d1);
  d = min(d, d2);
  return vec2(d, d0.y);
}

vec2 dV(vec2 p) {
  p -= off(1.0);
  vec2 p0 = p;
  vec2 d0 = dBox(p0);
  vec2 p1 = p;
  const mat2 rot1 = ROT(radians(62.0));
  p1.x = pabs(p1.x, dim.z*1.5);
  p1.x -= 0.095;
  p1.y -= 0.075;
  p1 = mul(rot1, p1);
  float d1 = segmentx(p1, 0.03)-dim.z;
  float d = d0.x;
  d = min(d, d1);
  return vec2(d, d0.y);
}

vec2 dI(vec2 p) {
  p -= off(2.0);
  vec2 p0 = p;
  vec2 d0 = dBox(p0);
  vec2 p1 = p;
  p1.y = abs(p1.y);
  p1 = p1.yx;
  float d1 = segmentx(p1, 0.10)-dim.z;
  float d = d0.x;
  d = min(d, d1);
  return vec2(d, d0.y);
}

vec2 dX(vec2 p) {
  p -= off(3.0);
  vec2 p0 = p;
  vec2 d0 = dBox(p0);
  vec2 p1 = p;
  p1 = abs(p1);
  p1 = mul(rot45, p1);
  float d1 = segmentx(p1, 0.145)-dim.z;
  float d = d0.x;
  d = min(d, d1);
  return vec2(d, d0.y);
}

vec3 effect(vec2 p) {
  float aa = 4.0/RESOLUTION.y;

  vec2 ddA = dA(p);
  vec2 ddV = dV(p);
  vec2 ddI = dI(p);
  vec2 ddX = dX(p);

  float d = ddX.x;
  d = pmax(d, -ddI.y, dim.z);
  d = min(d, ddI.x);
  d = pmax(d, -ddV.y, dim.z);
  d = min(d, ddV.x);
  d = pmax(d, -ddA.y, dim.z);
  d = min(d, ddA.x);

  vec3 col = (0.0);
  col = mix(col, (1.0), smoothstep(0.0, -aa, d));
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

  vec3 col = effect(p);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}