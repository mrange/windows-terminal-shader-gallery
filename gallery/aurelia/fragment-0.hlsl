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
#define REV(x)      exp2((x)*zoom)
#define FWD(x)      (log2(x)/zoom)

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const static vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

const static vec3 baseCol00 = HSV2RGB(vec3(341.0/360.0, 0.96, 0.85));
const static vec3 baseCol01 = HSV2RGB(vec3(260.0/360.0, 0.75, 0.36));
const static vec3 baseCol10 = HSV2RGB(vec3(285.0/360.0, 0.68, 0.45));
const static vec3 baseCol11 = HSV2RGB(vec3(268.0/360.0, 0.72, 0.40));
const static vec3 gcol = HSV2RGB(vec3(0.6, 0.95, 0.00025));
const static mat2 arot = ROT(radians(34.0));
const static vec2 soff = mul(arot, vec2(0.01, 0.01));
const static float zoom = log2(1.8);

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  k = max(k, 1E-10);
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan2(p.y, p.x));
}

vec2 toRect(vec2 p) {
  return vec2(p.x*cos(p.y), p.x*sin(p.y));
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

vec4 daurelia(vec2 p, float r) {
  vec2 p0 = p;
  vec2 p1 = p;
  p1.x += -0.033;
  p1.y += -0.004;
  vec2 p2 = p;
  p2.x += 0.48;
  p2.y += -0.06;
  vec2 p3 = p;
  p3.x += -0.495;
  p3.y += -0.06;
  vec2 p4 = p;
  p4.x += 0.39;
  p4.y += -0.86;
  vec2 p5 = p;
  p5.x += 0.78;
  p5.y += 0.4;
  vec2 p6 = p;
  p6.x += 0.035;

  float d0 = box(p0, vec2(1.0, 0.285)-r);
  float d1 = box(p1, vec2(0.225, 1.01)-r);
  float d2 = box(p2, vec2(0.17, 0.63)-r);
  float d3 = box(p3, vec2(0.11, 0.63)-r);
  float d4 = box(p4, vec2(0.06, 0.06)-r);
  float d5 = box(p5, vec2(0.06, 0.07)-r);
  float d6 = box(p6, vec2(0.55, 0.45)-r);

  d0 -= r;
  d1 -= r;

  float d7 = -(d0 - 0.06);

  d1 = pmax(d1, d7, r);

  float d = d2;
  d = min(d, d3);
  d = min(d, d4);
  d = min(d, d5);
  d -= r;
  d = pmax(d, d7,r);
  return vec4(d0, d1, d, d6);
}

float dot2(vec2 p) {
  return dot(p, p);
}

vec3 aurelia(vec3 col, float aa, vec2 p) {

  p = mul(arot, p);
  vec4 ad = daurelia(p, 0.0);
  vec4 sad = daurelia(p+soff, 0.025);
  float m0 = clamp(0.35*dot2(p-vec2(1.0, 0.0)), 0.0, 1.0);
  float m1 = clamp(0.35*dot2(p-vec2(0.0, 1.0)), 0.0, 1.0);
  float shd = mix(0.75, 1.0, smoothstep(aa, -aa, -ad.w));
  vec3 bcol0 = mix(baseCol00, baseCol01, m0);
  vec3 bcol1 = mix(baseCol00, baseCol01, m1)*shd;
  vec3 bcol2 = mix(baseCol10, baseCol11, m1)*shd;
  float sd = min(min(sad.x, sad.y), sad.z);
  float od = min(min(ad.x, ad.y), ad.z);
  od = abs(od)-aa;

  sd += 0.025;
  sd = max(sd, 0.0175);
  sd *= sd;

  col += gcol/sd;
  col = mix(col, mix(bcol0, col, 0.0), smoothstep(aa, -aa, ad.x));
  col = mix(col, mix(bcol1, col, 0.0), smoothstep(aa, -aa, ad.y));
  col = mix(col, mix(bcol2, col, 0.0), smoothstep(aa, -aa, ad.z));
  col = mix(col, 1.0, smoothstep(aa, -aa, od));
  return col;
}

vec3 background(vec3 col, float aa, vec2 op) {
  const float angle = TAU/10.0;
  const mat2 rot = ROT(0.5*angle);
  const mat2 trot = transpose(rot);

  float gtm = 0.125*TIME;
  op = mul(ROT(0.25*gtm), op);
  float od = 1E4;

  for (int j = 0; j < 2; ++j){
    float tm = gtm+float(j)*0.5;
    float ctm = floor(tm);
    float ftm = fract(tm);
    float z = REV(ftm);
    vec2 p = op;
    p /= z;

    float d = 1E4;
    float n = floor(FWD(length(p)));
    float r0 = REV(n);
    float r1 = REV(n+1.0);

    for (int i = 0; i < 2; ++i) {
      vec2 pp = toPolar(p);
      mod1(pp.y, angle);
      vec2 rp = toRect(pp);

      float d0 = circle(rp, r0);
      float d1 = circle(rp, r1);
      float d2 = segment(rp, mul(rot,vec2(r0, 0.0)), vec2(r1, 0.0));
      float d3 = segment(rp, mul(trot,vec2(r0, 0.0)), vec2(r1, 0.0));
      d0 = abs(d0);
      d1 = abs(d1);
      d = min(d, d0);
      d = min(d, d1);
      d = min(d, d2);
      d = min(d, d3);
      float gd = d*z;
      p = mul(rot, p);
    }
    d *= z;
    od = min(od, d);
  }

  od -= aa*0.5;
  col = mix(col, mix(baseCol00, baseCol01, tanh(dot2(op*1.0))), smoothstep(aa, -aa, od));
  col += 50.0*gcol.zxy/max(dot2(op), 0.01);

  return col;
}


vec3 effect(vec2 p, vec2 pp) {
  float aa = sqrt(2.0)/RESOLUTION.y;
  vec3 col = (0.0);

  vec2 ap = p;
  float aaa = aa;
  const float iz = sqrt(0.5);
  ap /= iz;
  aaa /= iz;

  col = background(col, aa, p);
  col = aurelia(col, aaa, ap);
  col *= smoothstep(1.25, 0.5, length(pp));
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
