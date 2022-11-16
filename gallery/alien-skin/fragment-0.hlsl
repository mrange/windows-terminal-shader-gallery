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

// License CC0: Alien skin
//  More playing around with warped FBMs
//  https://iquilezles.org/articles/warp
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

float hash(in vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

float onoise(vec2 x) {
  x *= 0.5;
  float a = sin(x.x);
  float b = sin(x.y);
  const float f = 0.9;
  float c = mix(a, b, 0.5+0.5*sin(TAU*tanh_approx(a*b+a+b)));
  return c;
}

#define QUINTIC
float vnoise(vec2 x) {
  vec2 i = floor(x);
  vec2 w = fract(x);

#if defined(QUINTIC)
  // quintic interpolation
  vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);
#else
  // cubic interpolation
  vec2 u = w*w*(3.0-2.0*w);
#endif

  float a = hash(i+vec2(0.0,0.0));
  float b = hash(i+vec2(1.0,0.0));
  float c = hash(i+vec2(0.0,1.0));
  float d = hash(i+vec2(1.0,1.0));

  float k0 =   a;
  float k1 =   b - a;
  float k2 =   c - a;
  float k3 =   d - c + a - b;

  float aa = mix(a, b, u.x);
  float bb = mix(c, d, u.x);
  float cc = mix(aa, bb, u.y);

  return k0 + k1*u.x + k2*u.y + k3*u.x*u.y;
}

float fbm(vec2 p, int mx) {
  vec2 op = p;
  const float aa = 0.45;
  const vec2 oo = -vec2(1.23, 1.5);
  const mat2 rr = 2.03*ROT(1.2);

  float h = 0.0;
  float d = 0.0;
  float a = 1.0;

  for (int i = 0; i < mx; ++i) {
    h += a*onoise(p);
    d += (a);
    a *= aa;
    p += oo;
    p = mul(rr, p);
  }

  return mix((h/d), -0.5*(h/d), pow(vnoise(0.9*op), 0.25));
}

float warp(vec2 p, inout mat2 rot0, inout mat2 rot1) {
  const int mx1 = 8;
  const int mx2 = 3;
  const int mx3 = 3;
  vec2 v = vec2(fbm(p, mx1), fbm(p+0.7*vec2(1.0, 1.0), mx1));

  v = mul(rot0, v);

  vec2 vv = vec2(fbm(p + 3.7*v, mx2), fbm(p + -2.7*v.yx+0.7*vec2(1.0, 1.0), mx2));

  vv = mul(rot1, vv);

  return fbm(p + 1.4*vv, mx3);
}

float height(vec2 p, vec2 off, inout mat2 rot0, inout mat2 rot1) {
  p += off;
  p *= 2.0;
  p += 13.0;
  float h = warp(p, rot0, rot1);
  float rs = 3.0;
  return 0.4*tanh(rs*h)/rs;
}

vec3 normal(vec2 p, vec2 off, inout mat2 rot0, inout mat2 rot1) {
  // As suggested by IQ, thanks!
  vec2 eps = -vec2(2.0/RESOLUTION.y, 0.0);

  vec3 n;

  n.x = height(p + eps.xy, off, rot0, rot1) - height(p - eps.xy, off, rot0, rot1);
  n.y = 2.0*eps.x;
  n.z = height(p + eps.yx, off, rot0, rot1) - height(p - eps.yx, off, rot0, rot1);


  return normalize(n);
}

vec3 postProcess(vec3 col, vec2 q)  {
  col=pow(clamp(col,0.0,1.0),unit3*(0.75));
  col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
  col=mix(col, unit3*(dot(col, unit3*(0.33))), -0.4);  // satuation
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
  return col;
}

vec3 effect(vec2 p, vec2 q) {
  float a   = 0.005*TIME;
  vec2 off  = 5.0*vec2(cos(a), sin(sqrt(0.5)*a));
  mat2 rot0 = ROT(1.0+TIME*0.1);
  mat2 rot1 = ROT(-1.0+TIME*0.2315);

  const vec3 lp1 = vec3(0.8, -0.75, 0.8);
  const vec3 lp2 = vec3(-0., -1.5, -1.0);

  float h = height(p, off, rot0, rot1);
  vec3 pp = vec3(p.x, h, p.y);
  vec3 ld1 = normalize(lp1 - pp);
  vec3 ld2 = normalize(lp2 - pp);

  vec3 n = normal(p, off, rot0, rot1);
  float diff1 = max(dot(ld1, n), 0.0);
  float diff2 = max(dot(ld2, n), 0.0);

  const vec3 baseCol1 = vec3(0.6, 0.8, 1.0);
  const vec3 baseCol2 = (vec3(1.0, 0.6, .75))*0.75;

  vec3 col = unit3*(0.0);
  col += baseCol1*pow(diff1, 16.0);
  col += 0.1*baseCol1*pow(diff1, 4.0);
  col += 0.15*baseCol2*pow(diff2,8.0);
  col += 0.015*baseCol2*pow(diff2, 2.0);

  col = mix(0.05*baseCol1, col, 1.0 - (1.0 - 0.5*diff1)*exp(- 2.0*smoothstep(-.1, 0.05, (h))));

  col = postProcess(col, q);

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

  vec3 col = effect(p, q);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}



