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

#define TIME        (0.5*Time)
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
static const float MaxIter = 12.0;

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

vec4 plane(vec2 p, float i, float zf, float z, vec3 bgcol) {
  float sz = 0.5*zf;
  vec2 cp = p;
  vec2 cn = mod2(cp, vec2(2.0*sz, sz));
  float h0 = hash(cn+i+123.4);
  float h1 = fract(4483.0*h0);
  float h2 = fract(8677.0*h0);
  float h3 = fract(9677.0*h0);
  float h4 = fract(7877.0*h0);
  float h5 = fract(9967.0*h0);
  if (h4 < 0.5) {
    return (0.0);
  }
  float fi = exp(-0.25*max(z-1.0, 0.0));
  float aa = mix(6.0, 1.0, fi)*2.0/RESOLUTION.y;
  float r  = sz*mix(0.1, 0.475, h0*h0);
  float amp = mix(0.5, 0.5, h3)*r;
  cp.x -= amp*sin(mix(3.0, 0.25, h0)*TIME+TAU*h2);
  cp.x += 0.95*(sz-r-amp)*sign(h3-0.5)*h3;
  cp.y += 0.475*(sz-2.0*r)*sign(h5-0.5)*h5;
  float d = length(cp)-r;
  vec3 ocol = (0.5+0.5*sin(vec3(0.0, 1.0, 2.0)+h1*TAU));
  vec3 icol = sqrt(ocol);
  ocol *= 1.5;
  icol *= 2.0;
  const vec3 lightDir = normalize(vec3(1.0, 1.5, 2.0));
  float z2 = (r*r-dot(cp, cp));
  vec3 col = ocol;
  if (z2 > 0.0) {
    float z = sqrt(z2);
    vec3 pp = vec3(cp, z);
    vec3 nn = normalize(pp);
    float dd= max(dot(lightDir, nn), 0.0);

    col = mix(ocol, icol, dd*dd*dd);
  }
  col *= mix(0.8, 1.0, h0);
  col = mix(bgcol, col, fi);
  float t = smoothstep(aa, -aa, d);
  return vec4(col, t);
}

// License: Unknown, author: Claude Brezinski, found: https://mathr.co.uk/blog/2017-09-06_approximating_hyperbolic_tangent.html
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

vec3 effect(vec2 p, vec2 pp) {
  const vec3 bgcol0 = vec3(0.1, 0.0, 1.0)*0.1;
  const vec3 bgcol1 = vec3(0.0, 0.4, 1.0)*0.6;
  vec3 bgcol = mix(bgcol1, bgcol0, tanh_approx(1.5*length(p)));
  vec3 col = bgcol;

  for (float i = 0.0; i < MaxIter; ++i) {
    const float Near = 4.0;
    float z = MaxIter - i;
    float zf = Near/(Near + MaxIter - i);
    vec2 sp = p;
    float h = hash(i+1234.5);
    sp.y += -mix(0.2, 0.3, h*h)*TIME*zf;
    sp += h;
    vec4 pcol = plane(sp, i, zf, z, bgcol);
    col = mix(col, pcol.xyz, pcol.w);
  }
  col *= smoothstep(1.5, 0.5, length(pp));
  col = clamp(col, 0.0, 1.0);
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
