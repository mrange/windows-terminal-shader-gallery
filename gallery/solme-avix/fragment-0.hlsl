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


#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))
#define PI          3.141592654
#define TAU         (2.0*PI)

// License: Unknown, author: nmz (twitter: @stormoid), found: https://www.shadertoy.com/view/NdfyRM
vec3 sRGB(vec3 t) {
  return mix(1.055*pow(t, (1./2.4)) - 0.055, 12.92*t, step(t, (0.0031308)));
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
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

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

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float hexagon(vec2 p, float r) {
  const vec3 k = vec3(-0.866025404,0.5,0.577350269);
  p = abs(p);
  p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
  p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
  return length(p)*sign(p.y);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float shape(vec2 p) {
  return hexagon(p.yx, 0.4)-0.075;
}

float cellHeight(float h) {
  return 0.05*2.0*(-h);
}

vec3 cell(vec2 p, float h) {
  float hd = shape(p);

  const float he = 0.0075*2.0;
  float aa = he;
  float hh = -he*smoothstep(aa, -aa, hd);

  return vec3(hd, hh, cellHeight(h));
}

float height(vec2 p, float h) {
  return cell(p, h).y;
}

vec3 normal(vec2 p, float h) {
  vec2 e = vec2(4.0/RESOLUTION.y, 0);

  vec3 n;
  n.x = height(p + e.xy, h) - height(p - e.xy, h);
  n.y = height(p + e.yx, h) - height(p - e.yx, h);
  n.z = 2.0*e.x;

  return normalize(n);
}

vec3 planeColor(vec3 ro, vec3 rd, vec3 lp, vec3 pp, vec3 pnor, vec3 bcol, vec3 pcol) {
  vec3  ld = normalize(lp-pp);
  float dif  = pow(max(dot(ld, pnor), 0.0), 1.0);
  vec3 col = pcol;
  col = mix(bcol, col, dif);
  return col;
}

static const mat2 rots[6] = {
    ROT(0.0*TAU/6.0)
  , ROT(1.0*TAU/6.0)
  , ROT(2.0*TAU/6.0)
  , ROT(3.0*TAU/6.0)
  , ROT(4.0*TAU/6.0)
  , ROT(5.0*TAU/6.0)
};

static const vec2 unitX = vec2(1.0, 0.0);

static const vec2 offs[6] = {
    mul(unitX,rots[0])
  , mul(unitX,rots[1])
  , mul(unitX,rots[2])
  , mul(unitX,rots[3])
  , mul(unitX,rots[4])
  , mul(unitX,rots[5])
  };

float cutSlice(vec2 p, vec2 off) {
  // A bit like this but unbounded
  // https://www.shadertoy.com/view/MlycD3
  p.x = abs(p.x);
  off.x *= 0.5;

  vec2 nn = normalize(vec2(off));
  vec2 n  = vec2(nn.y, -nn.x);

  float d0 = length(p-off);
  float d1 = -(p.y-off.y);
  float d2 = dot(n, p);

  bool b = p.x > off.x && (dot(nn, p)-dot(nn, off)) < 0.0;

  return b ? d0 : max(d1, d2);
}

float hexSlice(vec2 p, int n) {
  n = 6-n;
  n = n%6;
  p = mul(p,rots[n]);
  p = p.yx;
  const vec2 dim  = vec2((0.5)*2.0/sqrt(3.0), (0.5));
  return cutSlice(p, dim);
}

vec3 backdrop(vec2 p) {
  const float z = 0.327;
  float aa = 2.0/(z*RESOLUTION.y);

  p.yx = p;

  vec3 lp = vec3(3.0, 0.0, 1.0);

  p -= vec2(0.195, 0.);
  p /= z;

  float toff = 0.1*TIME;
  p.x += toff;
  lp.x += toff;

  vec2 hp  = p;
  vec2 hn  = hextile(hp);
  float hh = hash(hn);
  vec3 c   = cell(hp, hh);
  float cd = c.x;
  float ch = c.z;

  vec3 fpp = vec3(p, ch);
  vec3 bpp = vec3(p, 0.0);

  vec3 ro = vec3(0.0, 0.0, 1.0);
  vec3 rd = normalize(fpp-ro);

  vec3  bnor = vec3(0.0, 0.0, 1.0);
  vec3  bdif = lp-bpp;
  float bl2  = dot(bdif, bdif);

  vec3  fnor = normal(hp, hh);
  vec3  fld  = normalize(lp-fpp);

  float sf = 0.0;

  for (int i = 0; i < 6; ++i) {
    vec2  ioff= offs[i];
    vec2  ip  = p+ioff;
    vec2  ihn = hextile(ip);
    float ihh = hash(ihn);
    float ich = cellHeight(ihh);
    float iii = (ich-ch)/fld.z;
    vec3  ipp = vec3(hp, ch)+iii*fld;

    float hsd = hexSlice(ipp.xy, i);
    if (ich > ch) {
      sf += exp(-20.0*tanh_approx(1.0/(10.0*iii))*max(hsd+0., 0.0));
    }
  }

  const float sat = 0.23;
  vec3 bpcol = planeColor(ro, rd, lp, bpp, bnor, (0.0), HSV2RGB(vec3(240.0/36.0, sat, 0.14)));
  vec3 fpcol = planeColor(ro, rd, lp, fpp, fnor, bpcol, HSV2RGB(vec3(240.0/36.0, sat, 0.19)));

  vec3 col = bpcol;
  col = mix(col, fpcol, smoothstep(aa, -aa, cd));
  col *= 1.0-tanh_approx(sf);

  float fo = exp(-0.025*max(bl2-0., 0.0));
  col *= fo;
  col = mix(bpcol, col, fo);

  return col;
}

static const mat2 rot45 = ROT(radians(45.0));
static const vec3 dim = vec3(0.675, -0.025, 0.012);

vec2 off(float offX, float n) {
  return vec2(offX, (1.5-n)*dim.x-dim.y);
//  return vec2(-(1.5-n)*dim.x-dim.y, 0.0);
//  return 0.5*sin(vec2(1.0, sqrt(0.5))*(TIME-1.25*n));
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

// License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
float pabs(float a, float k) {
  return -pmin(a, -a, k);
}

float segmentx(vec2 p, float off) {
  p.x -= off;
  float d0 = length(p);
  float d1 = abs(p.y);
  return p.x > 0.0 ? d0 : d1;
}

vec2 dBox(vec2 p) {
  p = mul(rot45,p);
  const float roff = 0.065;
  float d = box(p, (0.25-roff));
  float dd = d-0.18;
  d -= 0.0275+roff;
  d = abs(d);
  d -= dim.z;
  return vec2(d, dd);
}

vec2 dA(float offX, vec2 p) {
  p -= off(offX, 0.0);
  vec2 p0 = p;
  vec2 d0 = dBox(p0);
  vec2 p1 = p;
  const mat2 rot1 = ROT(radians(-62.0));
  p1.x = pabs(p1.x, dim.z*1.5);
  p1.x -= 0.095;
  p1.y += 0.075;
  p1 = mul(rot1,p1);
  float d1 = segmentx(p1, 0.03)-dim.z;
  vec2 p2 = p;
  p2.y -= -0.03;
  p2.x = abs(p2.x);
  float d2 = segmentx(p2, 0.07)-dim.z;
  float d = d0.x;
  d = min(d, d1);
  d = min(d, d2);
  return vec2(d, d0.y);
}

vec2 dV(float offX, vec2 p) {
  p -= off(offX, 1.0);
  vec2 p0 = p;
  vec2 d0 = dBox(p0);
  vec2 p1 = p;
  const mat2 rot1 = ROT(radians(62.0));
  p1.x = pabs(p1.x, dim.z*1.5);
  p1.x -= 0.095;
  p1.y -= 0.075;
  p1 = mul(rot1,p1);
  float d1 = segmentx(p1, 0.03)-dim.z;
  float d = d0.x;
  d = min(d, d1);
  return vec2(d, d0.y);
}

vec2 dI(float offX, vec2 p) {
  p -= off(offX, 2.0);
  vec2 p0 = p;
  vec2 d0 = dBox(p0);
  vec2 p1 = p;
  p1.y = abs(p1.y);
  p1 = p1.yx;
  float d1 = segmentx(p1, 0.10)-dim.z;
  float d = d0.x;
  d = min(d, d1);
  return vec2(d, d0.y);
}

vec2 dX(float offX, vec2 p) {
  p -= off(offX, 3.0);
  vec2 p0 = p;
  vec2 d0 = dBox(p0);
  vec2 p1 = p;
  p1 = abs(p1);
  p1 = mul(rot45,p1);
  float d1 = segmentx(p1, 0.145)-dim.z;
  float d = d0.x;
  d = min(d, d1);
  return vec2(d, d0.y);
}

vec3 avix(vec3 col, vec2 p) {
  const float iz = 1.5;
  float offX = (RESOLUTION.x/RESOLUTION.y-0.5)*iz;
  float aa = iz*4.0/RESOLUTION.y;
  p *= iz;
  vec2 da = dA(offX, p);
  vec2 dv = dV(offX, p);
  vec2 di = dI(offX, p);
  vec2 dx = dX(offX, p);

  float d = dx.x;
  d = pmax(d, -di.y, dim.z);
  d = min(d, di.x);
  d = pmax(d, -dv.y, dim.z);
  d = min(d, dv.x);
  d = pmax(d, -da.y, dim.z);
  d = min(d, da.x);

  float dd = dx.y;
  dd = min(dd, di.y);
  dd = min(dd, dv.y);
  dd = min(dd, da.y);
  dd += 0.18*0.5;
  col = mix(col, mix(col, (0.0), 0.25), smoothstep(0.0, -aa, dd));
  col = mix(col, (1.0), smoothstep(0.0, -aa, d));
  return col;
}

vec3 effect(vec2 p) {
  vec3 col = (0.0);

  col = backdrop(p);
  col = avix(col, p);

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

  vec3 col = effect(p);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}