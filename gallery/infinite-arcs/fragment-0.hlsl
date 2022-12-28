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

static const float ExpBy = log2(1.25);

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
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

vec2 sca(float a) {
  return vec2(sin(a), cos(a));
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float arc(vec2 p, vec2 sc, float ra, float rb) {
  // sc is the sin/cos of the arc's aperture
  p.x = abs(p.x);
  return ((sc.y*p.x>sc.x*p.y) ? length(p-sc*ra) :
                                abs(length(p)-ra)) - rb;
}

float forward(float n) {
  return exp2(ExpBy*n);
}

float reverse(float n) {
  return log2(n)/ExpBy;
}

vec2 cell(float n) {
  float n2  = forward(n);
  float pn2 = forward(n-1.0);
  float m   = (n2+pn2)*0.5;
  float w   = (n2-pn2)*0.5;
  return vec2(m, w);
}

vec2 df(vec2 p) {
  const float w = 2.0/3.0;

  float tm = 0.5*TIME;
  float m = fract(tm);
  float f = floor(tm);
  float z = forward(m);

  vec2 p0 = p;
  p0 /= z;

  float l0 = length(p0);
  float n0 = ceil(reverse(l0));
  vec2 c0 = cell(n0);

  float h0 = hash(n0-f);
  float h1 = fract(3677.0*h0);
  float h2 = fract(8677.0*h0);
  float sh2 = (h2-0.5)*2.0;

  float a = TAU*h2+sqrt(abs(sh2))*sign(sh2)*TIME*TAU/20.0;
  p0 = mul(p0, ROT(a));
  float d0 = arc(p0, sca(PI/4.0+0.5*PI*h1), c0.x, c0.y*w);
  d0 = abs(d0)-c0.y*0.1;
  d0 *= z;
  return vec2(d0, n0-f);
}

vec3 effect(vec2 p, vec2 pp) {
  float aa = 2.0/RESOLUTION.y;
  float dd = length(p);
  vec2 d2 = df(p);
  float fi = smoothstep(0.25, 0.5, 10.0*dd);
  float h = fract(-0.1*dd+0.75+sin(0.25*d2.y)*0.2);
  vec3 bcol = hsv2rgb(vec3(h, 0.8, fi));

  vec3 col = bcol*smoothstep(aa, -aa, d2.x);
  vec3 gcol = HSV2RGB(vec3(0.55, 0.5, 2.0));
  col += gcol*mix(1.0, 0.0, tanh(10.0*dd));
  col *= smoothstep(1.5, 0.5, length(pp));
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
  float r = RESOLUTION.x/RESOLUTION.y;
  p.x *= r;

  vec3 col = effect(p, pp);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
