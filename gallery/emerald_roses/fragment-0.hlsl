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

// License CC0: Metallic Voronot Roses
//  If you got a decent height function, apply FBM and see if it makes it more interesting
//  Based upon: https://www.shadertoy.com/view/4tXGW4

#define VIGINETTE

#define PI          3.141592654
#define PI_2        (0.5*3.141592654)
#define TAU         (2.0*PI)
#define DOT2(x)     dot(x, x)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/index.htm
vec3 postProcess(vec3 col, vec2 q) {
  col = clamp(col, 0.0, 1.0);
  col = sqrt(col);
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, unit3*(dot(col, unit3*(0.33))), -0.4);
#if defined(VIGINETTE)
  col *= smoothstep(1.8, 0.5, length((-1.0+2.0*q)));
#endif
  return col;
}

// License: MIT, author: Pascal Gilcher, found: https://www.shadertoy.com/view/flSXRV
float atan_approx(float y, float x) {
  float cosatan2 = x / (abs(x) + abs(y));
  float t = PI_2 - cosatan2 * PI_2;
  return y < 0.0 ? -t : t;
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pabs(float a, float k) {
  return -pmin(a, -a, k);
}

// License: Unknown, author: Unknown, found: don't remember
vec2 hash(vec2 p) {
  p += 0.5;
  p = vec2(dot (p, vec2 (127.1, 311.7)), dot (p, vec2 (269.5, 183.3)));
  return -1. + 2.*fract (sin (p)*43758.5453123);
}

float height_(vec2 p, float tm) {
  p *= 0.125*1.5;
  vec2 n = floor(p + 0.5);
  vec2 r = hash(n);
  p = fract(p+0.5)-0.5;
  float d = length(p);
  float c = 1E6;
  float x = pow(d, 0.1);
  float y = atan_approx(p.x, p.y) / TAU;

  for (float i = 0.; i < 3.; ++i) {
    float ltm = tm+10.0*(r.x+r.y);
    float v = length(fract(vec2(x - ltm*i*.005123, fract(y + i*.125)*.5)*20.)*2.-1.);
    c = pmin(c, v, 0.125);
  }

  return -0.125*pabs(1.0-tanh_approx(5.5*d-80.*c*c*d*d*(.55-d))-0.25*d, 0.25);
}


float height(vec2 p) {
  const float aa = -0.35;
  const mat2  pp = 0.9*(1.0/aa)*ROT(1.0);

  float tm = TIME*0.00075;
  p += 50.0*vec2(cos(tm), sin(tm));
  float h = 0.0;
  float a = 1.0;
  float d = 0.0;
  for (int i = 0; i < 6; ++i) {
    h += a*height_(p, 0.125*TIME+10.0*sqrt(float(i)));
    h = pmin(h, -h, 0.025);
    d += a;
    a *= aa;
    p = mul(pp, p);
  }
  return (h/d);
}

vec3 normal(vec2 p) {
  vec2 v;
  vec2 w;
  vec2 e = vec2(4.0/RESOLUTION.y, 0);

  vec3 n;
  n.x = height(p + e.xy) - height(p - e.xy);
  n.y = 2.0*e.x;
  n.z = height(p + e.yx) - height(p - e.yx);

  return normalize(n);
}

vec3 effect(vec2 p, vec2 q) {
  const float s   = 1.0;
  const vec3 lp1  = vec3(1.0, 1.25, 1.0)*vec3(s, 1.0, s);
  const vec3 lp2  = vec3(-1.0, 1.25, 1.0)*vec3(s, 1.0, s);
  const vec3 ro   = vec3(0.0, -10.0, 0.0);

  const vec3 lcol1= vec3(1.5, 1.5, 2.0).xzy;
  const vec3 lcol2= vec3(2.0, 1.5, 0.75).zyx;

  float h = height(p);
  vec3  n = normal(p);

  vec3 pp = vec3(p.x, 0.0, p.y);

  vec3 po = vec3(p.x, h, p.y);
  vec3 rd = normalize(ro - po);

  vec3 ld1 = normalize(lp1 - po);
  vec3 ld2 = normalize(lp2 - po);

  float diff1 = max(dot(n, ld1), 0.0);
  float diff2 = max(dot(n, ld2), 0.0);

  vec3  rn    = n;
  vec3  ref   = reflect(rd, rn);
  float ref1  = max(dot(ref, ld1), 0.0);
  float ref2  = max(dot(ref, ld2), 0.0);

  vec3 lpow1 = 0.15*lcol1/DOT2(ld1);
  vec3 lpow2 = 0.5*lcol2/DOT2(ld2);
  vec3 dm = unit3*tanh_approx(-h*10.0+0.125);
  vec3 col = unit3*(0.0);
  col += dm*diff1*diff1*lpow1;
  col += dm*diff2*diff2*lpow2;
  vec3 rm = unit3*mix(0.25, 1.0, tanh_approx(-h*1000.0));
  col += rm*pow(ref1, 10.0)*lcol1;
  col += rm*pow(ref2, 10.0)*lcol2;

  col *= 0.33;

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

//  float ff = smoothstep(2.0, 0.5, length(pp));
#if defined(VIGINETTE)
  float ff = smoothstep(2.0, 0.5, length(pp));
  col = mix(col, 0.0*unit3, sh.w*ff);
  col = mix(col, fg.xyz, fg.w*ff);
#else
  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);
#endif

  return vec4(col, 1.0);
}



