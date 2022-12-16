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

// CC0: Longer Cosmic
//  Inspired by Cosmic by Xor: https://www.shadertoy.com/view/msjXRK
//  I am a big fan of high saturated glowin colors.
//  So I really liked Cosmic by Xor.
//  Making short shaders isn't part of my skill set but I was
//  thinking I could maybe remove the need for loop for each ring.

#define PI          3.141592654
#define PI_2        (0.5*PI)
#define TAU         (2.0*PI)

static const float overSample   = 4.0;
static const float ringDistance= 0.075*overSample/4.0;
static const float noOfRings   = 20.0*4.0/overSample;
static const float glowFactor  = 0.05;

// License: MIT, author: Pascal Gilcher, found: https://www.shadertoy.com/view/flSXRV
float atan_approx(float y, float x) {
  float cosatan2 = x / (abs(x) + abs(y));
  float t = PI_2 - cosatan2 * PI_2;
  return y < 0.0 ? -t : t;
}

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan_approx(p.y, p.x));
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

vec3 glow(vec2 pp, float h) {
  float hh = fract(h*8677.0);
  float b = TAU*h+0.5*TIME*(hh > 0.5 ? 1.0 : -1.0);
  float a = pp.y+b;
  float d = max(abs(pp.x)-0.001, 0.00125);
  return
    (   smoothstep(0.667*ringDistance, 0.2*ringDistance, d)
      * smoothstep(0.1, 1.0, cos(a))
      * glowFactor
      * ringDistance
      / d
    )
    * (cos(a+b+vec3(0,1,2))+unit3*(1.0))
    ;
}

vec3 effect(vec2 p) {
  p += -0.1;
  // Didn't really understand how the original Cosmic produced the fake projection.
  // Took part of the code and tinkered
  p = mul(mat2(1,-1, 2, 2), p);
  p += vec2(0.0, 0.33)*length(p);
  vec2 pp = toPolar(p);

  vec3 col = unit3*(0.0);
  float h = 1.0;
  const float nr = 1.0/overSample;

  for (float i = 0.0; i < overSample; ++i) {
    vec2 ipp = pp;
    ipp.x -= ringDistance*(nr*i);
    float rn = mod1(ipp.x, ringDistance);
    h = hash(rn+123.0*i);
    col += glow(ipp, h)*step(rn, noOfRings);
  }

  col += (0.01*vec3(1.0, 0.25, 0.0))/length(p);

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

  vec3 col = effect(p);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
