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


// CC0: F# Weekly Windows Terminal Shader
//  A shader background for Windows Terminal featuring the F# weekly logo

#define PI          3.141592654
#define TAU         (2.0*PI)
#define SCA(a)      vec2(sin(a), cos(a))
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
static const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

static const vec3 skyCol   = HSV2RGB(vec3(0.58, 0.86, 1.0));
static const vec3 speCol1  = HSV2RGB(vec3(0.55, 0.9, 1.0));
static const vec3 speCol2  = HSV2RGB(vec3(0.8 , 0.6, 1.0));
static const vec3 speCol3  = HSV2RGB(vec3(0.9, 0.86, 4.0));
static const vec3 matCol   = HSV2RGB(vec3(0.8,0.50, 0.5));
static const vec3 diffCol1 = HSV2RGB(vec3(0.60,0.90, 2.0));
static const vec3 diffCol2 = HSV2RGB(vec3(0.85,0.90, 2.0));
static const vec3 sunDir1  = normalize(vec3(0.9, -0.4, 1.0));
static const vec3 sunDir2  = normalize(vec3(-0.9 , 0.0, 1.0));


static const float outerZoom = 1.5;
static const float innerZoom = 1.0-0.4;
static const float height = -0.065*outerZoom;

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

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// License: Unknown, author: Unknown, found: don't remember
vec2 hash2(vec2 p) {
  p = vec2(dot (p, vec2 (127.1, 311.7)), dot (p, vec2 (269.5, 183.3)));
  return fract(sin(p)*43758.5453123);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
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

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float equilateralTriangle(vec2 p) {
  const float k = sqrt(3.0);
  p.x = abs(p.x) - 1.0;
  p.y = p.y + 1.0/k;
  if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
  p.x -= clamp( p.x, -2.0, 0.0 );
  return -length(p)*sign(p.y);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/intersectors/intersectors.htm
float rayPlane(vec3 ro, vec3 rd, vec4 p) {
  return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
vec2 pmin(vec2 a, vec2 b, float k) {
  vec2 h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

vec2 pabs(vec2 a, float k) {
  return -pmin(-a, a, k);
}

float ref(inout vec2 p, vec2 r) {
  float d = dot(p, r);
  p -= r*min(0.0, d)*2.0;
  return d < 0.0 ? 0.0 : 1.0;
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

vec2 dfsharpWeekly(vec2 p, vec2 off) {
  const mat2 rot45 = ROT(PI/4.0);
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

vec2 df(vec2 p) {
  const mat2 rot45 = ROT(PI/4.0);
  p = mul(transpose(rot45), p);
  vec2 cp = (p-0.5);
  vec2 cn = round(cp);
  cp -= cn;
  cp = mul(rot45, cp);

  return dfsharp(cp/innerZoom)*innerZoom;
}

float hf(vec2 p) {
  const float a = .05;
  p += 0.125*sin(vec2(1.0, sqrt(0.5))*TIME*a)/a;
  const float aa = 0.06;
  p /= outerZoom;
  vec2 d2 = df(p);
  float h = smoothstep(aa, -0.5*aa, (d2.x-0.0125));
  h *= height;
  return h;
}

vec3 normal(vec2 p) {
  vec2 eps = vec2(4.0/RESOLUTION.y, 0.0);

  vec3 n;

  n.x = hf(p + eps.xy) - hf(p - eps.xy);
  n.y = 2.0*eps.x;
  n.z = hf(p + eps.yx) - hf(p - eps.yx);

  return normalize(n);
}

vec3 skyColor(vec3 ro, vec3 rd) {
  vec3 col = unit3*(0.0);
  col = 0.025*skyCol;
//  col += speCol3*0.25E-3/max(abs(rd.y-0.35), 0.0001);
  col += speCol1*0.25E-2/pow((1.0001+((dot(sunDir1, rd)))), 2.0);
  col += speCol2*0.25E-2/pow((1.0001+((dot(sunDir2, rd)))), 2.0);

  float tp0  = rayPlane(ro, rd, vec4(vec3(0.0, 1.0, 0.0), 4.0));
  float tp1  = rayPlane(ro, rd, vec4(vec3(0.0, -1.0, 0.0), 6.0));
  float tp = tp1;
  tp = max(tp0,tp1);


  if (tp1 > 0.0) {
    vec3 pos  = ro + tp1*rd;
    vec2 pp = pos.xz;
    float db = box(pp, vec2(5.0, 9.0))-3.0;

    col += unit3*(4.0)*skyCol*rd.y*rd.y*smoothstep(0.25, 0.0, db);
    col += unit3*(0.8)*skyCol*exp(-0.5*max(db, 0.0));
  }

  return clamp(col, 0.0, 10.0);
}

vec3 fsharpEffect(vec2 p) {
  float s = 1.5;
  vec3 lp1 = sunDir1;
  vec3 lp2 = sunDir2;
  float h  = hf(p);
  vec3 n   = normal(p);
  vec3 ro  = vec3(0.0, 10.0, 0.0);
  vec3 pp  = vec3(p.x, h, p.y);
  vec3 rd  = normalize(pp-ro);
  vec3 ref = reflect(rd, n);
  vec3 ld1 = normalize(lp1 - pp);
  vec3 ld2 = normalize(lp2 - pp);

  const mat2 rot = ROT(-PI/2.0+0.4);
  ref.zy = mul(rot, ref.zy);

  const float dm = 1.0;
  float diff1 = pow(max(dot(ld1, n), 0.0), dm);
  float diff2 = pow(max(dot(ld2, n), 0.0), dm);
  vec3 rsky   = skyColor(pp, ref);

  vec3 col = unit3*(0.0);

  float hh = smoothstep(0.00, height, h);
  col += (matCol*diffCol1)*diff1*mix(0.2, 1.0, hh);
  col += (matCol*diffCol2)*diff2*mix(0.2, 1.0, hh);
  col += rsky*mix(1.0, 0.5, hh);
  col -= 0.05*vec3(2.0, 2.0, 1.0);

  return col;
}

vec3 stars(vec2 sp, float hh) {
  const vec3 scol0 = HSV2RGB(vec3(0.85, 0.8, 1.0));
  const vec3 scol1 = HSV2RGB(vec3(0.65, 0.5, 1.0));
  vec3 col = unit3*(0.0);

  const float m = 4.0;

  for (float i = 0.0; i < m; ++i) {
    vec2 pp = sp+0.5*i;
    float s = i/(m-1.0);
    vec2 dim  = unit2*(mix(0.05, 0.003, s)*PI);
    vec2 np = mod2(pp, dim);
    vec2 h = hash2(np+127.0+i);
    vec2 o = -1.0+2.0*h;
    pp += o*dim*0.5;
    float l = length(pp);

    float h1 = fract(h.x*1667.0);
    float h2 = fract(h.x*1887.0);
    float h3 = fract(h.x*2997.0);

    vec3 scol = mix(8.0*h2, 0.25*h2*h2, s)*mix(scol0, scol1, h1*h1);

    vec3 ccol = col + exp(-0.5*(mix(6000.0, 2000.0, hh)/mix(2.0, 0.25, s))*max(l-0.001, 0.0))*scol;
    ccol *= mix(0.125, 1.0, smoothstep(1.0, 0.99, sin(0.25*TIME+TAU*h.y)));
    col = ccol;
  }

  return col;
}

vec3 triEffect(vec3 col, vec2 p) {
  vec2 op = p;
  const vec2 n = SCA(-PI/3.0);
  float hoff = 0.15*dot(n, p);
  vec3 gcol = hsv2rgb(vec3(clamp(0.7+hoff, 0.6, 0.8), 0.90, 0.02));
  vec2 pt = p;
  pt.y -= 0.3;
  pt.y = -pt.y;
  const float zt = 1.0;
  float dt = equilateralTriangle(pt/zt)*zt;
  col = dt < 0.0 ? col : stars(op, 0.8);
  col += 2.0*gcol;
  col = dt < 0.0 ? fsharpEffect(p) : col;
  col += gcol/abs(dt);
  return col;
}

vec3 fsharpWeeklyEffect(vec3 col, float aa, vec2 p) {
  const vec2 n = SCA(-PI/4.0);

  vec2 pf = p;
  pf.y -= -0.32;
  float hoff = 0.15*dot(n, pf);
  vec3 gcol = hsv2rgb(vec3(0.625+hoff, 0.85, 1.0));

  vec2 df2 = dfsharpWeekly(pf, unit2*(0.0));

  col = mix(col, col*sqrt(gcol), smoothstep(aa, -aa, df2.x));
  col += 0.005*gcol/abs(df2.x);

  float fy = pf.y+0.18;
  vec3 skyCol = hsv2rgb(vec3(0.7+0.125*fy, 0.95, 0.3*(1.0+.0*abs(fy))));
  vec3 fcol = unit3*(0.0);
  fcol += clamp(skyCol/pow(abs(fy), 0.65), 0.0, 10.0);
  col = mix(col, fcol, smoothstep(aa, -aa, df2.y));
  col = mix(col, unit3*(2.0), smoothstep(aa, -aa, abs(df2.y)-0.003));

  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  float aa = 2.0/RESOLUTION.y;
  vec3 col = unit3*(0.0);

  col = triEffect(col, p);
  col = fsharpWeeklyEffect(col, aa, p);

  col *= smoothstep(1.5, 0.25, length(pp));
  col *= mix(unit3*(0.5), unit3,smoothstep(-0.9, 0.9, sin(0.25*TAU*p.y/aa+TAU*vec3(0.0, 1., 2.0)/3.0)));

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
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect(p, q);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
