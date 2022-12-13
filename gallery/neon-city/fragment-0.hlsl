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

// CC0: Neon city for Windows Terminal
//  An older shader of mine seems to have some fans that really like it.
//  I personally feel I evolved beyond the techniques of the shader but it seems to appeal
//  to some people.
//  This is a recreation for windows terminal
//  Hopefully I didn't destroy what people like about it in the process :)


#define PI          3.141592654
#define TAU         (2.0*PI)

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
static const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

static const vec3 shineCol = HSV2RGB(vec3(0.55, 0.5, 0.75));
static const vec3 gridCol  = HSV2RGB(vec3(0.60, 0.5, 1.0));
static const vec3 cityCol  = HSV2RGB(vec3(0.55, 0.25, 0.4));
static const vec3 skyCol1  = HSV2RGB(vec3(283.0/360.0, 0.83, 0.16));
static const vec3 skyCol2  = HSV2RGB(vec3(297.0/360.0, 0.79, 0.43));

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

float psin(float a) {
  return 0.5 + 0.5*sin(a);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float planex(vec2 p, float w) {
  return abs(p.y) - w;
}

float pmin(float a, float b, float k) {
  float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float sun(vec2 p) {
  const float ch = 0.0125;
  vec2 sp = p;
  vec2 cp = p;
  mod1(cp.y, ch*6.0);

  float d0 = circle(sp, 0.5);
  float d1 = planex(cp, ch);
  float d2 = p.y+ch*3.0;

  float d = d0;
  d = pmax(d, -max(d1, d2), ch*2.0);

  return d;
}

float city(vec2 p) {
  float fd = -(p.y+0.4);
  float cd = 1E6;

  const float count = 5.0;
  const float width = 0.1;

  for (float i = 0.0; i < count; ++i) {
    vec2 pp = p;
    pp.x += i*width/count;
    float nn = mod1(pp.x, width);
    float rr = hash(nn+sqrt(3.0)*i);
    float dd = box(pp-vec2(0.0, -0.5), vec2(0.02, 0.35*(1.0-smoothstep(0.0, 10.0, abs(nn)))*rr+0.1));
    cd = min(cd, dd);
  }

  return max(fd, cd);
}

vec3 cityEffect(vec2 p, float dc) {
  float aa = 2.0 / RESOLUTION.y;
  dc = abs(dc)-aa;
  vec3 col = unit3*(0.0);
  col = mix(col, cityCol*0.75, smoothstep(aa, -aa, dc));
  return col;
}

vec3 sunEffect(vec2 p, float dc) {
  float aa = 4.0 / RESOLUTION.y;

  vec3 col = unit3*(0.1);
  col = mix(skyCol1, skyCol2, pow(clamp(0.5*(1.0+p.y+0.1*sin(4.0*p.x+TIME*0.5)), 0.0, 1.0), 4.0));

  p.y -= 0.49;
  float ds = sun(p);

  float dd = circle(p, 0.5);

  vec3 sunCol = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 1.0), clamp(0.5 - 1.0*p.y, 0.0, 1.0));
  vec3 glareCol = sqrt(sunCol);
  vec3 cityCol = sunCol*sunCol;

  col += glareCol*(exp(-30.0*ds))*step(0.0, ds);


  float t1 = smoothstep(0.0, 0.075, -dd);
  float t2 = smoothstep(0.0, 0.3, -dd);
  col = mix(col, sunCol, smoothstep(-aa, 0.0, -ds));
  col = mix(col, glareCol, smoothstep(-aa, 0.0, -dc)*t1);
  col += vec3(0.0, 0.25, 0.0)*(exp(-90.0*dc))*step(0.0, dc)*t2;
  return col;
}

float ground(vec2 p) {
  p.y += TIME*40.0;
  p *= 0.075;
  vec2 gp = p;
  gp = fract(gp) - unit2*(0.5);
  float d0 = abs(gp.x);
  float d1 = abs(gp.y);
  float d2 = circle(gp, 0.05);

  const float rw = 2.5;
  const float sw = 0.0125;

  vec2 rp = p;
  mod1(rp.y, 12.0);
  float d3 = abs(rp.x) - rw;
  float d4 = abs(d3) - sw*2.0;
  float d5 = box(rp, vec2(sw*2.0, 2.0));
  vec2 sp = p;
  mod1(sp.y, 4.0);
  sp.x = abs(sp.x);
  sp -= vec2(rw - 0.125, 0.0);
  float d6 = box(sp, vec2(sw, 1.0));

  float d = d0;
  d = pmin(d, d1, 0.1);
  d = max(d, -d3);
  d = min(d, d4);
  d = min(d, d5);
  d = min(d, d6);

  return d;
}

vec3 groundEffect(vec2 p) {
  vec3 ro = vec3(0.0, 20.0, 0.0);
  vec3 ww = normalize(vec3(0.0, -0.025, 1.0));
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0), ww));
  vec3 vv = normalize(cross(ww,uu));
  vec3 rd = normalize(p.x*uu + p.y*vv + 2.5*ww);

  float distg = (-9.0 - ro.y)/rd.y;

  vec3 col = unit3*(0.0);
  if (distg > 0.0) {
    vec3 pg = ro + rd*distg;
    float aa = length(ddx(pg))*0.0002*RESOLUTION.x;

    float dg = ground(pg.xz);

    col = mix(col, gridCol, smoothstep(-aa, 0.0, -(dg+0.0175)));
    col += shineCol*(exp(-10.0*clamp(dg, 0.0, 1.0)));
    col = clamp(col, 0.0, 1.0);

    col *= pow(1.0-smoothstep(ro.y*3.0, 220.0+ro.y*2.0, distg), 2.0);
  }

  return col;
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/index.htm
vec3 postProcess(vec3 col, vec2 q)  {
  col = clamp(col,0.0,1.0);
  // No Gamma correction
  // col = pow(col, 1.0/vec3(2.2));
  col=col*0.6+0.4*col*col*(3.0-2.0*col);
  col=mix(col, unit3*(dot(col, unit3*(0.33))), -0.4);
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

vec3 effect(vec2 p, vec2 q) {
  vec3 col = unit3*(0.0);

  vec2 off = vec2(0.0, 0.15);

  float dc = city(p-vec2(0.0, 0.375)+off);
  col += cityEffect(p+off,dc );
  col += sunEffect(p+off,dc);
  col += groundEffect(p+off);

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
  float r = RESOLUTION.x/RESOLUTION.y;
  p.x *= r;

  vec3 col = effect(p, q);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
