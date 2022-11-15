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

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define TAU         (2.0*PI)

static const float gravity = 1.0;
static const float waterTension = 0.01;

static const vec3 skyCol1 = vec3(0.6, 0.35, 0.3).zyx*0.5;
static const vec3 skyCol2 = vec3(1.0, 0.3, 0.3).zyx*0.5 ;
static const vec3 sunCol1 = vec3(1.0,0.5,0.4).zyx;
static const vec3 sunCol2 = vec3(1.0,0.8,0.8).zyx;
static const vec3 seaCol1 = vec3(0.1,0.2,0.2)*0.2;
static const vec3 seaCol2 = vec3(0.2,0.9,0.6)*0.5;

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

vec2 wave(in float t, in float a, in float w, in float p) {
  float x = t;
  float y = a*sin(t*w + p);
  return vec2(x, y);
}

vec2 dwave(in float t, in float a, in float w, in float p) {
  float dx = 1.0;
  float dy = a*w*cos(t*w + p);
  return vec2(dx, dy);
}

vec2 gravityWave(in float t, in float a, in float k, in float h) {
  float w = sqrt(gravity*k*tanh_approx(k*h));
  return wave(t, a ,k, w*TIME);
}

vec2 capillaryWave(in float t, in float a, in float k, in float h) {
  float w = sqrt((gravity*k + waterTension*k*k*k)*tanh_approx(k*h));
  return wave(t, a, k, w*TIME);
}

vec2 gravityWaveD(in float t, in float a, in float k, in float h) {
  float w = sqrt(gravity*k*tanh_approx(k*h));
  return dwave(t, a, k, w*TIME);
}

vec2 capillaryWaveD(in float t, in float a, in float k, in float h) {
  float w = sqrt((gravity*k + waterTension*k*k*k)*tanh_approx(k*h));
  return dwave(t, a, k, w*TIME);
}

void mrot(inout vec2 p, in float a) {
  float c = cos(a);
  float s = sin(a);
  p = vec2(c*p.x + s*p.y, -s*p.x + c*p.y);
}

vec4 sea(in vec2 p, in float ia) {
  float y = 0.0;
  vec3 d = unit3*(0.0);

  const int maxIter = 8;
  const int midIter = 4;

  float kk = 1.0/1.3;
  float aa = 1.0/(kk*kk);
  float k = 1.0*pow(kk, -float(maxIter) + 1.0);
  float a = ia*0.25*pow(aa, -float(maxIter) + 1.0);

  float h = 25.0;
  p *= 0.5;

  vec2 waveDir = vec2(0.0, 1.0);
{
  for (int i = midIter; i < maxIter; ++i) {
    float t = dot(-waveDir, p) + float(i);
    y += capillaryWave(t, a, k, h).y;
    vec2 dw = capillaryWaveD(-t, a, k, h);

    d += vec3(waveDir.x, dw.y, waveDir.y);

    mrot(waveDir, PI/3.0);

    k *= kk;
    a *= aa;
  }
}
  waveDir = vec2(0.0, 1.0);
{
  for (int i = 0; i < midIter; ++i) {
    float t = dot(waveDir, p) + float(i);
    y += gravityWave(t, a, k, h).y;
    vec2 dw = gravityWaveD(t, a, k, h);

    vec2 d2 = vec2(0.0, dw.x);

    d += vec3(waveDir.x, dw.y, waveDir.y);

    mrot(waveDir, -step(2.0, float(i)));

    k *= kk;
    a *= aa;
  }
}
  vec3 t = normalize(d);
  vec3 nxz = normalize(vec3(t.z, 0.0, -t.x));
  vec3 nor = cross(t, nxz);

  return vec4(y, nor);
}

vec3 sunDirection() {
  vec3 dir = normalize(vec3(0, 0.06, 1));
  return dir;
}

vec3 skyColor(in vec3 rd) {
  vec3 sunDir = sunDirection();
  float sunDot = max(dot(rd, sunDir), 0.0);
  vec3 final = unit3*(0.0);
  final += mix(skyCol1, skyCol2, rd.y);
  final += 0.5*sunCol1*pow(sunDot, 90.0);
  final += 4.0*sunCol2*pow(sunDot, 900.0);
  return final;
}

vec3 render(in vec3 ro, in vec3 rd) {
  vec3 col = unit3*(0.0);

  float dsea = (0.0 - ro.y)/rd.y;

  vec3 sunDir = sunDirection();

  vec3 sky = skyColor(rd);

  if (dsea > 0.0) {
    vec3 p = ro + dsea*rd;
    vec4 s = sea(p.xz, 1.0);
    float h = s.x;
    vec3 nor = s.yzw;
    nor = mix(nor, vec3(0.0, 1.0, 0.0), smoothstep(0.0, 200.0, dsea));

    float fre = clamp(1.0 - dot(-nor,rd), 0.0, 1.0);
    fre = fre*fre*fre;
    float dif = mix(0.25, 1.0, max(dot(nor,sunDir), 0.0));

    vec3 refl = skyColor(reflect(rd, nor));
    vec3 refr = seaCol1 + dif*sunCol1*seaCol2*0.1;

    col = mix(refr, 0.9*refl, fre);

    float atten = max(1.0 - dot(dsea,dsea) * 0.001, 0.0);
    col += seaCol2*(p.y - h) * 2.0 * atten;

    col = mix(col, sky, 1.0 - exp(-0.01*dsea));

  } else {
    col = sky;
  }

  return col;
}

vec3 effect(vec2 p) {
  vec3 ro = vec3(0.0, 10.0, 0.0);
  vec3 ww = normalize(vec3(0.0, -0.1, 1.0));
  vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww));
  vec3 vv = normalize(cross(ww,uu));
  vec3 rd = normalize(p.x*uu + p.y*vv + 2.5*ww);

  vec3 col = render(ro, rd);

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



