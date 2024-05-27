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

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
static const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

static const float
    outer = .0125*0.5
  , inner = .0125*0.5
  , full  = inner+outer
  , pi    = acos(-1.)
  , tau   = 2.*pi
  ;

static const vec3
    lightCol0 = HSV2RGB(vec3(0.58, 0.8, 2.))
  , lightCol1 = HSV2RGB(vec3(0.68, 0.5, 2.))
  , sunCol    = HSV2RGB(vec3(0.08, 0.8, 5E-2))
  , lightPos0 = vec3(1.1, 1.-0.5, 1.25)
  , lightPos1 = vec3(-1.5, 0, 1.25)
  ;
// License: Unknown, author: Matt Taylor (https://github.com/64), found: https://64.github.io/tonemapping/
vec3 aces_approx(vec3 v) {
  v = max(v, 0.0);
  v *= 0.6;
  float a = 2.51;
  float b = 0.03;
  float c = 2.43;
  float d = 0.59;
  float e = 0.14;
  return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0, 1.0);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// IQ's polynomial min
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

// IQ's box
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// IQ's segment
float parabola(vec2 pos, float k) {
  pos.x = abs(pos.x);
  float ik = 1.0/k;
  float p = ik*(pos.y - 0.5*ik)/3.0;
  float q = 0.25*ik*ik*pos.x;
  float h = q*q - p*p*p;
  float r = sqrt(abs(h));
  float x = (h>0.0) ?
        pow(q+r,1.0/3.0) - pow(abs(q-r),1.0/3.0)*sign(r-q) :
        2.0*cos(atan2(r,q)/3.0)*sqrt(p);
  return length(pos-vec2(x,k*x*x)) * sign(pos.x-x);
}

float atari(vec2 p) {
  p.x = abs(p.x);
  float db = box(p, vec2(0.36, 0.32));

  float dp0 = -parabola(p-vec2(0.4, -0.235), 4.0);
  float dy0 = p.x-0.115;
  float d0 = mix(dp0, dy0, smoothstep(-0.25, 0.125, p.y)); // Very hacky

  float dp1 = -parabola(p-vec2(0.4, -0.32), 3.0);
  float dy1 = p.x-0.07;
  float d1 = mix(dp1, dy1, smoothstep(-0.39, 0.085, p.y)); // Very hacky

  float d2 = p.x-0.035;
  static const float sm = 0.025;
  float d = 1E6;
  d = min(d, max(d0, -d1));;
  d = pmin(d, d2, sm);
  d = pmax(d, db, sm);

  return d;
}

float df(vec2 p) {
  static const float z = 2.;
  return atari(p/z)*z;
}

float hf(vec2 p) {
  float d0 = df(p);
  float x = clamp(full+(d0-outer), 0., full);
  float h = sqrt((full*full-x*x))/full;

  return -0.5*full*h;
}

vec3 nf(vec2 p) {
  vec2 e = vec2(sqrt(8.)/RESOLUTION.y, 0);

  vec3 n;
  n.x = hf(p + e.xy) - hf(p - e.xy);
  n.y = hf(p + e.yx) - hf(p - e.yx);
  n.z = 2.0*e.x;

  return normalize(n);
}

float mountain(float p) {
  p*= 5.;
  p += -1.+TIME*5E-3;
  float h = 0.;
  float a = 1.;
  for (int i = 0; i < 3; ++i) {
    h += a*sin(p);
    a *= .5;
    p = 1.99*p+1.;
  }

  return 0.05*h+0.05;
}

vec3 layer0(vec3 col, vec2 p, float aa, float tm) {
  vec3
      ro    = vec3(0,0,tm)
    , rd    = normalize(vec3(p,2))
    , ard   = abs(rd)
    , srd   = sign(rd)
    ;

  for (float i = 1.; i < 10.; ++i) {
    float tw = -(ro.x-6.*sqrt(i))/ard.x;

    vec3 wp = ro+rd*tw;

    vec2
        wp2 = (ro+rd*tw).yz*2E-2
      , wn2 = round(wp2)
      , wc2 = wp2 - wn2
      ;

    if (hash(wn2+i+.5*srd.x) < .5)
      wc2 = vec2(wc2.y, -wc2.x);

    float
        fo  = smoothstep(-sqrt(.5), 1., sin(.1*wp.z+tm+i+srd.x))
      , wd  = abs(min(length(wc2+.5)-.5, length(wc2-.5)-.5))-25E-3
      ;


    col +=
       (1.+sin(vec3(-4,3,1)/2.+5E-2*tw+tm))
      *exp(-3E-3*tw*tw)
      *fo
      *25E-4/max(abs(wd), 3E-3*fo);
  }


  return col;
}

vec3 layer1(vec3 col, vec2 p, float aa) {
  float d = df(p);
  vec3  n = nf(p);

  vec3 lcol = (0.);
  vec3 p3 = vec3(p, 0.);

  vec3 ro = vec3(0.,0.,10.);
  vec3 rd = normalize(p3-ro);
  vec3 r = reflect(rd, n);
  vec3 ld0 = normalize(lightPos0-p3);
  vec3 ld1 = normalize(lightPos1-p3);

  float spe0 = pow(max(dot(r, ld0), 0.0), 70.);
  float spe1 = pow(max(dot(r, ld1), 0.0), 40.);

  float m = mountain(p.x);
  float cy = p.y+m;
  vec2 sp = p-vec2(0.0,0.5);
  vec3 topCol = hsv2rgb(vec3(0.58+cy*0.15, 0.95, 1.));
  topCol *= smoothstep(0.7, 0.25, cy);
  topCol += sunCol/max(dot(sp, sp), 1E-2);
  vec3 botCol = hsv2rgb(vec3(0.98-cy*0.2, 0.85, 1.));
  botCol *= tanh(-10.*min(0., cy+0.01)+0.05);

  lcol = mix(topCol, botCol, smoothstep(aa, -aa, cy));

  lcol *= 0.67+0.33*sin(p.y*RESOLUTION.y*tau/8.);
  lcol *= 2.;
  lcol += spe0*lightCol0;
  lcol += spe1*lightCol1;
  lcol -= 0.0125*length(p);

  col *= 1.-0.9*exp(-10.*max(d+0.0125*sqrt(2.), 0.));
  col = mix(col, lcol, smoothstep(aa, -aa, d-outer));
  col = mix(col, (0.), smoothstep(aa, -aa, abs(d-outer)-2E-3));

  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  float
      aa = sqrt(2.)/RESOLUTION.y
    ;

  vec3
      col = (0.)
    ;

  col = layer0(col, p, aa, 0.5*TIME);
  col = layer1(col, p, aa);

  col *= smoothstep(sqrt(2.), sqrt(.5), length(pp));
  col = sqrt(aces_approx((col)));
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
