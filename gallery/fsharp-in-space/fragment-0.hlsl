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

#define TTIME       (TAU*TIME)
#define PI          3.141592654
#define TAU         (2.0*PI)
#define SCA(a)      vec2(sin(a), cos(a))
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

#define COLORTUNE   0.

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
static const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

// License: Unknown, author: nmz (twitter: @stormoid), found: https://www.shadertoy.com/view/NdfyRM
vec3 sRGB(vec3 t) {
  return mix(1.055*pow(t, unit3*(1./2.4)) - 0.055, 12.92*t, step(t, unit3*(0.0031308)));
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

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pabs(float a, float k) {
  return -pmin(-a, a, k);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
vec2 pmin(vec2 a, vec2 b, float k) {
  vec2 h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
vec2 pabs(vec2 a, float k) {
  return -pmin(-a, a, k);
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float hexagon(vec2 p, float r) {
  const vec3 k = 0.5*vec3(-sqrt(3.0), 1.0, sqrt(4.0/3.0));
  p = abs(p);
  p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
  p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
  return length(p)*sign(p.y);
}

float ref(inout vec2 p, vec2 r) {
  float d = dot(p, r);
  p -= r*min(0.0, d)*2.0;
  return d < 0.0 ? 0.0 : 1.0;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float roundedX(vec2 p, float w, float r) {
  p = abs(p);
  return length(p-min(p.x+p.y,w)*0.5) - r;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float segment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p-a, ba = b-a;
  float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h );
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

vec2 dfsharpWeekly(vec2 p, vec2 off) {
  const vec2 refN = SCA(-PI/4.0);
  const float r = 0.125;
  const float rr = 2.0*r*sqrt(2.0);
  vec2 p0 = p;
  vec2 p1 = p-off;
  p0 = abs(p0);
  ref(p0, refN);
  p0.y -= rr;
  float d0 = roundedX(p0, rr, r);
  float d1 = segment(p1, rr*vec2(-1.0, 0.0), rr*vec2(0.0, 1.0))-r;
  float d2 = segment(p1, rr*vec2(0.5, -0.5), rr*vec2(0.0, -1.0))-r;
  float d3 = segment(p1, rr*vec2(-1.0, 0.0), rr*vec2(0.5, -1.5))-r;
  float d = d0;
  float dd = d1;
  dd = min(dd, d2);
  dd = min(dd, d3);

  return vec2(d, dd);
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

vec3 df(vec2 p) {
  vec2 op = p;

  vec2 ph = op;
  ph.y -= -0.025;
  ph = ph.yx;
  float dh = -hexagon(ph, 1.99);

  const float fz = 2.0;
  vec2 df = dfsharp(p/fz)*vec2(fz, 1.0);
  float d0 = df.y > 0.0 ? abs(df.x)-0.0125 : df.x;;

  float d = d0;

  return vec3(d, length(p), dh);
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

vec2 transform(vec2 p) {
  float a = TTIME/400.0;
  p *= 1.25;
  p = mul(ROT(a), p);
  vec2 p0 = toSmith(p);
  p0 += 1.0*vec2(0.5, -1.0);
  p = fromSmith(p0);
  p.y += 0.05*TIME;
  return p;
}

vec3 effect(vec2 p, vec2 pp, float r) {
  const float iz = 4.0;
  const float zf = 0.5;
  const float hoff = COLORTUNE;
  const vec3 bcol  = HSV2RGB(vec3(hoff+0.61, 0.9, 1.5));
  const vec3 gcol  = HSV2RGB(vec3(hoff+0.55, 0.9, 1.0));
  const vec3 bbcol = HSV2RGB(vec3(hoff+0.55, 0.75, 0.66));
  const vec3 scol  = HSV2RGB(vec3(hoff+0.50, 0.95, 2.0));

  vec2 pf = p;
  pf -= vec2(r, -1.0)-0.4*vec2(1.0,-1.0);
  pf /= zf;
  const mat2 rot = ROT(-PI/4.0);
  pf = mul(rot, pf);

  vec2 dfw = dfsharpWeekly(pf, vec2(-0.8, -0.35))*zf;
  float dfs = min(dfw.x, dfw.y);
  float aaa = 2.0/RESOLUTION.y;
  p = transform(p);
  float aa = iz*length(fwidth(p))*sqrt(0.5);
  vec2 n = hextile(p);
  p *= iz;
  vec3 d3 = df(p);
  float d = d3.x;
  float g = d3.y;
  float dd = d3.z;

  float amb = mix(0.025, 0.1, tanh_approx(0.1+0.25*g+0.33*p.y));

  vec3 col = unit3*(0.0);

  col = mix(col, 5.0*sqrt(amb)*bcol, smoothstep(aa, -aa, d));
  col = mix(col, 4.0*sqrt(amb)*bbcol, smoothstep(aa, -aa, dd));
  col += 0.125*bcol*exp(-12.0*max(min(d, dd), 0.0));
  col += gcol*amb;
  col += scol*aa;
  col *= mix(unit3*(0.5), unit3, smoothstep(-0.9, 0.9, sin(0.33*TAU*p.y/aa+TAU*vec3(0.0, 1., 2.0)/3.0)));
  col = mix(col, 1.2*sqrt(bcol), smoothstep(aaa, -aaa, dfs));
  col *= smoothstep(1.5, 0.5, length(pp));

  col = aces_approx(col);
  col = sRGB(col);

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

  vec3 col = effect(p, pp, r);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
