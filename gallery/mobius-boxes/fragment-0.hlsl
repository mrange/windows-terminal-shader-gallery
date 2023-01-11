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

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// License: Unknown, author: Hexler, found: Kodelife example Grid
float hash(vec2 uv) {
  return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

float dot2(vec2 p) {
  return dot(p, p);
}

vec2 df(vec2 p, float aa, out float h, out float sc) {
  vec2 pp = p;

  float sz = 2.0;

  float r = 0.0;

  for (int i = 0; i < 5; ++i) {
    vec2 nn = mod2(pp, (sz));
    sz /= 3.0;
    float rr = hash(nn+123.4);
    r += rr;
    if (rr < 0.5) break;
  }

  float d0 = box(pp, (1.45*sz-aa))-0.05*sz;
  float d1 = sqrt(sqrt(dot2(pp*pp)));
  h = fract(r);
  sc = sz;
  return vec2(d0, d1);
}

vec2 toSmith(vec2 p)  {
  // z = (p + 1)/(-p + 1)
  // (x,y) = ((1+x)*(1-x)-y*y,2y)/((1-x)*(1-x) + y*y)
  float d = (1.0 - p.x)*(1.0 - p.x) + p.y*p.y;
  float x = (1.0 + p.x)*(1.0 - p.x) - p.y*p.y;
  float y = 2.0*p.y;
  return vec2(x,y)/d;
}

vec2 fromSmith(vec2 p)  {
  // z = (p - 1)/(p + 1)
  // (x,y) = ((x+1)*(x-1)+y*y,2y)/((x+1)*(x+1) + y*y)
  float d = (p.x + 1.0)*(p.x + 1.0) + p.y*p.y;
  float x = (p.x + 1.0)*(p.x - 1.0) + p.y*p.y;
  float y = 2.0*p.y;
  return vec2(x,y)/d;
}

vec2 transform(vec2 p) {
  float tm = 0.25*TIME;
  p *= 2.0;
  const mat2 rot0 = ROT(1.0);
  const mat2 rot1 = ROT(-2.0);
  vec2 off0 = 4.0*cos(vec2(1.0, sqrt(0.5))*0.23*tm);
  vec2 off1 = 3.0*cos(vec2(1.0, sqrt(0.5))*0.13*tm);
  vec2 sp0 = toSmith(p);
  vec2 sp1 = toSmith((p+off0));
  vec2 sp2 = toSmith((p-off1));
  vec2 pp = fromSmith(sp0+sp1-sp2);
  p = pp;
  p += 0.25*tm;

  return p;
}

vec3 effect(vec2 p, vec2 pp) {
  vec2 np = p+1.0/RESOLUTION.y;
  p = transform(p);
  np = transform(np);
  float aa = distance(p, np)*sqrt(2.0);

  float h = 0.0;
  float sc = 0.0;
  vec2 d2 = df(p, aa, h, sc);

  vec3 col = (0.0);

  vec3 rgb = ((2.0/3.0)*(cos(0.33*TAU*h+0.5*vec3(0.0, 1.0, 2.0))+(1.0))-d2.y/(3.0*sc));
  col = mix(col, rgb, smoothstep(aa, -aa, d2.x));

  const vec3 gcol1 = vec3(3.0, 1.75, 1.0);
  col += gcol1*tanh_approx(0.025*aa);

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
