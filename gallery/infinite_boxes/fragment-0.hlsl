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


static const float ExpBy = log2(1.2);

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
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

float forward(float n) {
  return exp2(ExpBy*n);
}

float reverse(float n) {
  return log2(n)/ExpBy;
}

vec2 cell(float n) {
  float n2  = forward(n);
  float pn2 = forward(n-1.0);
  float m   = (n2+pn2)*0.5;
  float w   = (n2-pn2)*0.5;
  return vec2(m, w);
}

vec2 df(vec2 p, float aa) {
  float tm = 0.5*TIME;
  float m = fract(tm);
  float f = floor(tm);
  float z = forward(m);

  vec2 p0 = p;
  p0 /= z;
  vec2 sp0 = sign(p0);
  p0 = abs(p0);

  float l0x = p0.x;
  float n0x = ceil(reverse(l0x));
  vec2 c0x  = cell(n0x);


  float l0y = p0.y;
  float n0y = ceil(reverse(l0y));
  vec2 c0y  = cell(n0y);


  vec2 p1 = vec2(p0.x, p0.y);
  vec2 o1 = vec2(c0x.x, c0y.x);
  vec2 c1 = vec2(c0x.y, c0y.y);
  p1 -= o1;

  float r1 = 0.5*aa/z;

  vec2 p2 = p1;
  vec2 c2 = c1;
  float n2 = 0.0;

  if (c1.x < c1.y) {
    float f2 = floor(c1.y/c1.x);
    c2 = vec2(c1.x, c1.y/f2);
    if (fract(0.5*f2) < 0.5) {
      p2.y -= -c2.y;
    }

    n2 = mod1(p2.y, 2.0*c2.y);
  } else if (c1.x > c1.y){
    float f2 = floor(c1.x/c1.y);
    c2 = vec2(c1.x/f2, c1.y);
    if (fract(0.5*f2) < 0.5) {
      p2.x -= -c2.x;
    }

    n2 = mod1(p2.x, 2.0*c2.x);
  }
  float h0 = hash(n2+vec2(n0x, n0y)-(f)+vec2(sp0.x, sp0.y));

  float d2 = box(p2, c2-2.0*r1)-r1;

  float d = d2;
  d *= z;

  return vec2(d, h0);
}

vec3 bcolor(float h) {
//  return hsv2rgb(vec3(fract(h), 0.85, 1.0));
  return 0.25*(0.125+1.0+cos(TAU*h+vec3(0.0, 1.0, 2.0)/3.0));
}

vec4 effect(vec2 p, float hue) {
  float aa = 2.0/RESOLUTION.y;
  vec2 d2 = df(p, aa);

  vec3 col = (0.0);
  vec3 bcol = bcolor((hue+0.3*d2.y));
  return vec4(bcol, smoothstep(aa, -aa, d2.x));
}

vec3 effect(vec2 p, vec2 pp) {

//#define TWIST
#if defined(TWIST)
  p.x = abs(p.x);
  p *= ROT(0.025*TIME-0.2*length(p));
#endif
  float hue = -length(p)+0.05*TIME;

  vec3 col = (0.0);
  vec4 col0 = effect(p, hue);
  col = mix(col, col0.xyz, col0.w);

  col += 2.0*sqrt(bcolor(hue))*mix(1.0, 0.0, tanh_approx(2.0*sqrt(length(p))));
  col *= smoothstep(1.5, 0.5, length(pp));
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
