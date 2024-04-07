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
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

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

  n -= (0.5);
  // Rounding to make hextile 0,0 well behaved
  return round(n*2.0)*0.5;
}

// License: Unknown, author: Matt Taylor (https://github.com/64), found: https://64.github.io/tonemapping/
vec3 aces_approx(vec3 v) {
  v = max(v, 0.0);
  v *= 0.6f;
  float a = 2.51f;
  float b = 0.03f;
  float c = 2.43f;
  float d = 0.59f;
  float e = 0.14f;
  return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0f, 1.0f);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

vec3 palette(float a){
  return (1.+(sin(vec3(0., 1., 2.)+a)));
}

vec3 effect(vec2 p, vec2 pp) {
  float tm = -TIME*0.25;
  const float MaxIter = 22.;
  const float zz= 1.;
  const float b = 0.1;

  vec2 op = p;
  p = p.yx;

  vec2 center = vec2(-0.4, 0.);
  vec2 c = center+p*0.5;
  vec2 z = c;

  vec2 z2;

  float s = 1.;
  float i = 0.;
  for (; i < MaxIter; ++i) {
    z2 = z*z;
    float ss = sqrt(z2.x+z2.y);
    if (ss > 2.) break;
    s *= 2.;
    s *= ss;
    z = vec2(z2.x-z2.y, 2.*z.x*z.y)+c;
  }

  vec2 p2 = z/zz;
  float a = 0.1*tm;
  p2 = mul(p2, ROT(a));
  p2 += sin(vec2(1., sqrt(0.5))*a*b)/b;

  const float gfo = 0.5;
  float fo = (gfo*1E-3)+s*(gfo*3E-3);
  vec2 c2 = p2;
  hextile(c2);

  float gd0 = length(c2)-0.25;
  float gd1 = abs(c2.y);
  const vec2 n2 = mul(ROT(radians(60.)),vec2(0.,1.));
  const vec2 n3 = mul(ROT(radians(-60.)),vec2(0.,1.));
  float gd2 = abs(dot(n2, c2));
  float gd3 = abs(dot(n3, c2));
  gd1 = min(gd1, gd2);
  gd1 = min(gd1, gd3);
  float gd = gd0;
  gd = pmax(gd, -(gd1-0.025), 0.075);
  gd = min(gd, gd1);
  gd = pmin(gd, gd0+0.2, 0.025);
  gd = abs(gd);
  gd -= fo;

  vec3 col = (0.);

  if (i < MaxIter) {
  } else {
    float gf = (gfo*1E-2)/max(gd, fo);
    col += gf*palette(tm+(p2.x-p2.y)+op.x);
  }

  float div = 6.*max(round(RESOLUTION.y/1080.0), 1.);

  col *= sqrt(0.5)*(0.5+0.5*sin(op.y*RESOLUTION.y*TAU/div));
  col = aces_approx(col);
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
