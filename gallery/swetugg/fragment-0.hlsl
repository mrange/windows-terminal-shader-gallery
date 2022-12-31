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

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
static const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float triangle_(vec2 p, vec2 p0, vec2 p1, vec2 p2) {
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
    return -sqrt(d.x)*sign(d.y);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float polygon5(vec2 p, vec2 v[5]) {
  float d = dot(p-v[0],p-v[0]);
  float s = 1.0;
  for( int i=0, j=5-1; i<5; j=i, i++ ) {
    vec2 e = v[j] - v[i];
    vec2 w =    p - v[i];
    vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
    d = min( d, dot(b,b) );
    bool3 c = bool3(p.y>=v[i].y,p.y<v[j].y,e.x*w.y>e.y*w.x);
    if( all(c) || all(!(c)) ) s*=-1.0;
  }
  return s*sqrt(d);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float polygon8(vec2 p, vec2 v[8]) {
  float d = dot(p-v[0],p-v[0]);
  float s = 1.0;
  for( int i=0, j=8-1; i<8; j=i, i++ ) {
    vec2 e = v[j] - v[i];
    vec2 w =    p - v[i];
    vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
    d = min( d, dot(b,b) );
    bool3 c = bool3(p.y>=v[i].y,p.y<v[j].y,e.x*w.y>e.y*w.x);
    if( all(c) || all(!(c)) ) s*=-1.0;
  }
  return s*sqrt(d);
}

vec3 swetugg(vec2 p) {
  const vec2 p2[8] = {
    vec2(0.98, 0.965)-0.98*vec2(1.0, 0.67)
  , vec2(0.98, 0.965)
  , vec2(1.245, 0.935)
  , vec2(1.13, 0.165)
  , vec2(1.18, -0.09)
  , vec2(0.91, -0.625)
  , vec2(0.405, -0.97)
  , vec2(0.00, 0.08)
  };

  const vec2 p3[5] = {
    vec2(-0.1, -0.8)
  , vec2(0.082, -0.42)
  , vec2(0.045, 0.18)
  , vec2(0.1, 0.38)
  , vec2(-0.1, 0.4)
  };

  p.x = abs(p.x);
  float d3 = polygon5(p, p3);

  p.x *= mix(0.95, 1.05, (0.5+0.5*sin(TAU*TIME*5.0))*smoothstep(0.9, 1.0, sin(TAU*TIME/10.0)));
  float d0 = triangle_(p, vec2(0.055, -0.07), vec2(0.405, -0.97), vec2(0.91, -0.625));
  float d1 = triangle_(p, vec2(1.13, 0.165)-1.18*vec2(1.0, 0.0375), vec2(1.245, 0.935), vec2(1.13, 0.165));
  float d2 = polygon8(p, p2);

  float dx = d0;
  dx = min(dx, d1);
  float dy = d2;
  float dz = d3;

  return vec3(dx, dy, dz);
}

vec3 df(vec2 p) {
  const float z = 0.5;
  const mat2 rot = ROT(radians(7.0));
  p /= z;
  p.xy = mul(rot, p.xy);
  return swetugg(p)*z;
}

vec3 effect(vec2 p, vec2 pp) {
  float aa = 2.0/RESOLUTION.y;
  vec3 dd = df(p);
  float dt = min(min(dd.x, dd.y), dd.z);

  const vec3 col0 = vec3(104.0, 0.0, 19.0)/255.0;
  const vec3 col1 = vec3(166.0, 0.0, 31.0)/255.0;
  const vec3 col2 = vec3(16.0, 16.0, 17.0)/255.0;

  vec3 col  = 0.1*sqrt(col0);
  col += col1*exp(-20.0*dd.z*dd.z);
  col = mix(col, col1*2.0, smoothstep(aa, -aa, abs(dt)-0.005));
  col = mix(col, col1*mix(0.5, 1.0, 40.0*dd.y*dd.y), smoothstep(aa, -aa, dd.y));
  col = mix(col, col0*mix(0.5, 1.0, 30.0*-dd.x), smoothstep(aa, -aa, dd.x));
  col = mix(col, col2*20.0*-dd.z, smoothstep(aa, -aa, dd.z));

  col *= 1.5*smoothstep(1.25, 0.0, length(pp));
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
