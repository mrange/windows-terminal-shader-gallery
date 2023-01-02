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
#define PI_2        (0.5*3.141592654)
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

static const vec3  bcol        = vec3(0., 1.0, 0.25)*sqrt(0.5);

static const float logo_radius = 0.25;
static const float logo_off    = 0.25;
static const float logo_width  = 0.10;

// License: MIT, author: Pascal Gilcher, found: https://www.shadertoy.com/view/flSXRV
float atan_approx(float y, float x) {
  float cosatan2 = x / (abs(x) + abs(y));
  float t = PI_2 - cosatan2 * PI_2;
  return y < 0.0 ? -t : t;
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

float spiralLength(float b, float a) {
  // https://en.wikipedia.org/wiki/Archimedean_spiral
  return 0.5*b*(a*sqrt(1.0+a*a)+log(a+sqrt(1.0+a*a)));
}

void spiralMod(inout vec2 p, float a) {
  vec2 op     = p;
  float b     = a/TAU;
  float  rr   = length(op);
  float  aa   = atan2(op.y, op.x);
  rr         -= aa*b;
  float nn    = mod1(rr, a);
  float sa    = aa + TAU*nn;
  float sl    = spiralLength(b, sa);
  p           = vec2(sl, rr);
}

float dsegmentx(vec2 p, vec2 dim) {
  p.x = abs(p.x);
  float o = 0.5*max(dim.x-dim.y, 0.0);
  if (p.x < o) {
    return abs(p.y) - dim.y;
  }
  return length(p-vec2(o, 0.0))-dim.y;
}

vec3 digit(vec3 col, vec2 p, vec3 acol, vec3 icol, float aa, float n, float t) {
  const int digits[16] = {
    0x7D // 0
  , 0x50 // 1
  , 0x4F // 2
  , 0x57 // 3
  , 0x72 // 4
  , 0x37 // 5
  , 0x3F // 2
  , 0x51 // 7
  , 0x7F // 8
  , 0x77 // 9
  , 0x7B // A
  , 0x3E // B
  , 0x2D // C
  , 0x5E // D
  , 0x2F // E
  , 0x2B // F
  };
  const vec2 dim = vec2(0.75, 0.075);
  const float eps = 0.001;
  vec2 ap = abs(p);
  if (ap.x > (0.5+dim.y+eps)) return col;
  if (ap.y > (1.0+dim.y+eps)) return col;
  float m = mod(floor(n), 16.0);
  int digit = digits[int(m)];

  vec2 cp = (p-0.5);
  vec2 cn = round(cp);

  vec2 p0 = p;
  p0.y -= 0.5;
  p0.y = p0.y-0.5;
  float n0 = round(p0.y);
  p0.y -= n0;
  float d0 = dsegmentx(p0, dim);

  vec2 p1 = p;
  vec2 n1 = sign(p1);
  p1 = abs(p1);
  p1 -= 0.5;
  p1 = p1.yx;
  float d1 = dsegmentx(p1, dim);

  vec2 p2 = p;
  p2.y = abs(p.y);
  p2.y -= 0.5;
  p2 = abs(p2);
  float d2 = dot(normalize(vec2(1.0, -1.0)), p2);

  float d = d0;
  d = min(d, d1);

  float sx = 0.5*(n1.x+1.0) + (n1.y+1.0);
  float sy = -n0;
  float s  = d2 > 0.0 ? (3.0+sx) : sy;
#if defined(WINDOWS_TERMINAL)
  // Can't get bit ops to work in kodelife
  // Praying bit shift operations aren't TOO slow
  vec3 scol = ((digit & (1 << int(s))) == 0) ? icol : acol;
#else
  vec3 scol = icol;
#endif

  col = mix(col, scol, smoothstep(aa, -aa, d)*t);
  return col;
}
vec3 digit(vec3 col, vec2 p, vec3 acol, vec3 icol, float n, float t) {
  vec2 aa2 = fwidth(p);
  float aa = max(aa2.x, aa2.y);
  return digit(col, p, acol, icol, aa, n, t);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

// License: Unknown, author: Unknown, found: don't remember
float hash2(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

float stripes(float d) {
  const float cc = 0.42;
  d = abs(d)-logo_width*cc;
  d = abs(d)-logo_width*cc*0.5;
  return d;
}

vec4 merge(vec4 s0, vec4 s1) {
  bool dt = s0.z < s1.z;
  vec4 b = dt ? s0 : s1;
  vec4 t = dt ? s1 : s0;

  b.x *= 1.0 - exp(-max(80.0*(t.w), 0.0));

  vec4 r = vec4(
      mix(b.xy, t.xy, t.y)
    , b.w < t.w ? b.z : t.z
    , min(b.w, t.w)
    );

  return r;
}

vec4 figure_8(vec2 p, float aa) {
  vec2  p1 = p-vec2(logo_off, -logo_off);
  float d1 = abs(circle(p1, logo_radius));
  float a1 = atan_approx(-p1.x, -p1.y);
  float s1 = stripes(d1);
  float o1 = d1 - logo_width;

  vec2  p2 = p-vec2(logo_off, logo_off);
  float d2 = abs(circle(p2, logo_radius));
  float a2 = atan_approx(p2.x, p2.y);
  float s2 = stripes(d2);
  float o2 = d2 - logo_width;

  vec4 c0 = vec4(smoothstep(aa, -aa, s1), smoothstep(aa, -aa, o1), a1, o1);
  vec4 c1 = vec4(smoothstep(aa, -aa, s2), smoothstep(aa, -aa, o2), a2, o2);

  return merge(c0, c1);
}

vec4 clogo(vec2 p, float aa, out float d) {
  const mat2 rot0 = ROT(PI/4.0);
  const mat2 rot1 = ROT(5.0*PI/4.0);

//#define SINGLE8

  float sgn = sign(p.y);
#if !defined(SINGLE8)
  p *= sgn;
#endif
  vec4 s0 = figure_8(p, aa);
  vec4 s1 = figure_8(mul(rot0, p), aa);
  vec4 s2 = figure_8(p-vec2(-0.5, 0.0), aa);
  vec4 s3 = figure_8(mul(rot1, p), aa);

  // This is very hackish to get it to look reasonable

  const float off = -PI;
  s1.z -= off;
  s3.z -= off;

  vec4 s = s0;
#if !defined(SINGLE8)
  s = merge(s, s1);
  s = merge(s, s2);
  s = merge(s, s3);
#endif

  d = s.w;
  return vec4(mix(0.025*bcol, bcol, s.x), s.y);
}

vec3 logoEffect(vec3 col, vec2 p, vec2 pp, float aa) {
  float d;
  vec4 ccol = clogo(p, aa, d);

  const float period = TAU*10.0;
  float ss = sin(period*d-TIME*TAU/10.0);
  const float off = 0.2;
  float doff = period*aa*cos(off);
//  col = mix(col, col*0.125, smoothstep(doff, -doff, abs(ss)-off));
  col = mix(col, ccol.xyz, ccol.w);
  return col;
}

vec3 spiralEffect(vec3 col, vec2 p, vec2 pp, float aa) {
  vec2 sp = p;
  spiralMod(sp, .5);

  vec2 dp = sp;
  float dz = 0.0125;
  dp /= dz;
  aa /= dz;
  float dny = mod1(dp.y, 3.06);
  float dhy = hash(dny+1234.5);
  dp.x = -dp.x;
  float ltm = (TIME+1234.5)*mix(2.0, 10.0, (dhy))*0.125;
  dp.x -= ltm;
  float opx = dp.x;
  float dnx = mod1(dp.x, 1.5);
  const float stepfx = 0.125*0.25;
  float fx  = -2.0*stepfx*ltm+stepfx*dnx;
  float fnx = floor(fx);
  float ffx = fract(fx);
  float dht = hash(fnx);
  float dhx = hash(dnx);
  float dh  = fract(dht+dhx+dhy);

  float l = length(p);
  float t = smoothstep(0.4, 0.5, l);

  const vec3 hcol = clamp(1.5*sqrt(bcol)+unit3*(0.2), 0.0, 1.0);
  const vec3 acol = bcol;
  const vec3 icol = acol*0.1;

  float fo = (smoothstep(0.0, 1.0, ffx));
  float ff = smoothstep(1.0-2.0*sqrt(stepfx), 1.0, ffx*ffx);
  col = digit(col, dp, mix(acol, hcol, ff), icol, aa, 100.0*dh, fo*t);

#if defined(CURSOR)
  float fc = smoothstep(1.0-stepfx, 1.0, ffx);
  const float rb = 0.2;
  float db = box(dp, vec2(0.5, 1.0))-rb;

  col = mix(col, mix(col, hcol, 0.33*fc*fc), smoothstep(aa, -aa, db)*t);
#endif

  return col;
}

vec3 glowEffect(vec3 col, vec2 p, vec2 pp, float aa) {
  float d = length(p);
  col += 0.25*bcol*exp(-9.0*max(d-2.0/3.0, 0.0));
  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  float aa = 2.0/RESOLUTION.y;
  vec3 col  = unit3*(0.0);
  col = spiralEffect(col, p, pp, aa);
  col = glowEffect(col,p, pp, aa);
  col = logoEffect(col, mul(ROT(-0.05*TIME), p), pp, aa);
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
  float r = RESOLUTION.x/RESOLUTION.y;
  p.x *= r;

  vec3 col = effect(p, pp);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
