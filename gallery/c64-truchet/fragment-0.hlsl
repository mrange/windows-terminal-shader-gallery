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

// CC0 - 10 PRINT CHR$(205.5+RND(1)); : GOTO 10
//  Attempting to recreate the classic C64 truchet pattern
//  Can be found here for example: https://en.wikipedia.org/wiki/Truchet_tiles

// While very simple (especially the C64 version) the labyrinth it creates is fascinating.

float hash(vec2 p) {
  float a = dot(p, vec2 (127.1, 311.7));
  return fract(sin (a)*43758.5453123);
}

float cell_df(vec2 np, vec2 mp, vec2 off) {
  const vec2 n0 = normalize(vec2(1.0, 1.0));
  const vec2 n1 = normalize(vec2(-1.0, 1.0));

  np += off;
  mp -= off;

  float hh = hash(np);
  vec2 n = hh > 0.5 ? n0 : n1;
  vec2 t = vec2(n.y, -n.x);


  vec2  p0 = mp;
  p0 = abs(p0);
  p0 -= 0.5;
  float d0 = length(p0)-0.0;

  vec2  p1 = mp;
  float d1 = dot(n, p1);
  float px = dot(t, p1);
  d1 = abs(px) > sqrt(0.5) ? d0 : abs(d1);

  float d = d0;
  d = min(d, d1);

  return d;
}

float truchet_df(vec2 p) {
  vec2 np = floor(p+0.5);
  vec2 mp = fract(p+0.5) - 0.5;
  float d = 1E6;
  const float off = 1.0;
  for (float x=-off;x<=off;++x) {
    for (float y=-off;y<=off;++y) {
      vec2 o = vec2(x,y);
      d = min(d,cell_df(np, mp, o));
    }
  }
  return d;
}

vec3 effect(vec2 p) {
  float aa = 2.0/RESOLUTION.y;

  float a = 0.025*TIME+1.0;
  float z = mix(0.125, 0.25, 0.5+0.5*sin(sqrt(1.0/3.0)*a))*0.5;
  p /= z;
  p += 40.0*sin(vec2(sqrt(0.5)*a, a));
  float d = truchet_df(p);
  d -= 0.1;
  d *= z;

  const vec3 bgcol = vec3(68.0, 71.0, 226.0)/(255.0);
  const vec3 fgcol = vec3(164.0, 166.0, 251.0)/(255.0);

  vec3 col = bgcol;
  col = mix(col,  fgcol, smoothstep(aa, -aa, d));
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

  vec3 col = effect(p);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
