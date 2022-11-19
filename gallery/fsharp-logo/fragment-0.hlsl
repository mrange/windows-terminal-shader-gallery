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
// CC0: F# Windows Terminal Shader
//  A shader background for Windows Terminal featuring the F# logo

#define PI          3.141592654
#define TAU         (2.0*PI)

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
static const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

vec2 pmin(vec2 a, vec2 b, float k) {
  vec2 h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

vec2 pabs(vec2 a, float k) {
  return -pmin(-a, a, k);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float hexagon(vec2 p, float r) {
//  const vec3 k = vec3(-0.866025404,0.5,0.577350269);
  const vec3 k = 0.5*vec3(-sqrt(3.0),1.0,sqrt(4.0/3.0));
  p = abs(p);
  p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
  p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
  return length(p)*sign(p.y);
}

// License: Unknown, author: Martijn Steinrucken, found: https://www.youtube.com/watch?v=VmrIDyYiJBA
vec2 hextile(inout vec2 p) {
  // See Art of Code: Hexagonal Tiling Explained!
  // https://www.youtube.com/watch?v=VmrIDyYiJBA
  const vec2 sz       = vec2(1.0, sqrt(3.0));
  const vec2 hsz      = 0.5*sz;

  vec2 p1 = mod(p, sz)-hsz;
  vec2 p2 = mod(p - hsz, sz)-hsz;
  vec2 p3 = dot(p1, p1) < dot(p2, p2) ? p1 : p2;
  vec2 n = ((p3 - p + hsz)/sz);
  p = p3;

  n -= unit2*(0.5);
  // Rounding to make hextile 0,0 well behaved
  return round(n*2.0)*0.5;
}

vec2 dfsharp(vec2 p) {
  vec2 p0 = p;
  vec2 p1 = p;
  vec2 p3 = p;
  const float sm = 0.03;
  p0 = pabs(p0, sm);
  const vec2 n = normalize(unit2);
  float d0 = abs(dot(n, p0)-0.38)-0.12;
  float d1 = abs(p1.x)-0.025;
  float d2 = dot(n, p0)-0.19;
  float d3 = -p3.x-0.025;
  d2 = pmax(d2, -d3, sm);
  float d = d0;

  d = pmax(d, -d1, sm);
  d = min(d,  d2);
  return vec2(d, p.x > 0.0 ? 1.0 : 0.0);
}

float cellf(vec2 p, vec2 n) {
  const float lw = 0.01;
  return -hexagon(p.yx, 0.5-lw);
}

vec2 df(vec2 p, out vec2 hn0, out vec2 hn1) {
  const float sz = 0.25;
  p /= sz;
  vec2 hp0 = p;
  vec2 hp1 = p+vec2(1.0, sqrt(1.0/3.0));

  hn0 = hextile(hp0);
  hn1 = hextile(hp1);

  float d0 = cellf(hp0, hn0);
  float d1 = cellf(hp1, hn1);
  float d2 = length(hp0);

  float d = d0;
  d = min(d0, d1);

  return vec2(d, d2)*sz;
}

vec3 effect(vec2 p, vec2 pp) {
  const float pa = 20.0;
  const float pf = 0.0025;
  const float hoff = 0.0;
  const vec3 fcol0 = HSV2RGB(vec3(hoff+0.62, 0.95, 1.0));
  const vec3 fcol1 = HSV2RGB(vec3(hoff+0.62, 0.75, 1.0));
  const vec3 bcol0 = HSV2RGB(vec3(hoff+0.63, 0.85, 0.5));

  float aa = 2.0/RESOLUTION.y;
  vec2 hn0;
  vec2 hn1;
  vec2 df2 = dfsharp(p);
  vec2 dfs2 = dfsharp(p-vec2(0.01, -0.01));
  vec2 pb = p + pa*sin(TIME*pf*vec2(1.0, sqrt(0.5)));
  vec2 d2 = df(pb, hn0, hn1);

  vec3 col = unit3*(0.0);

  float h0 = hash(hn1);
  float l = mix(0.25, 0.75, h0);

  if (hn0.x <= hn1.x+0.5) {
    l *= 0.5;
  }

  if (hn0.y <= hn1.y) {
    l *= 0.75;
  }

  col += l*bcol0;

  col = mix(col, unit3*(0.), smoothstep(aa, -aa, d2.x));
  col *= mix(0.75, 1.0, smoothstep(0.01, 0.2, d2.y));
  col = mix(col, col*0.2, smoothstep(aa, -aa, 0.125*dfs2.x));
  col = mix(col, smoothstep(-1.5, 0.5, p.y)*mix(fcol0, fcol1, df2.y > 0.0 ? 1.0 : 0.0), smoothstep(aa, -aa, df2.x));
  col *= 1.25*smoothstep(1.5, 0.25, length(pp));
//  col *= 1.25*mix(unit3*(0.5), unit3,smoothstep(-0.9, 0.9, sin(0.25*TAU*p.y/aa+TAU*vec3(0.0, 1., 2.0)/3.0)));
  col = clamp(col, 0.0, 1.0);
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
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect(p, pp);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}



