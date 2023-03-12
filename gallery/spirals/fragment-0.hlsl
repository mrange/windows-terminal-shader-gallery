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

#define PI              3.141592654
#define TAU             (2.0*PI)
#define ROT(a)          mat2(cos(a), sin(a), -sin(a), cos(a))

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

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
vec2 rayCylinder(vec3 ro, vec3 rd, vec3 cb, vec3 ca, float cr) {
  vec3  oc = ro - cb;
  float card = dot(ca,rd);
  float caoc = dot(ca,oc);
  float a = 1.0 - card*card;
  float b = dot( oc, rd) - caoc*card;
  float c = dot( oc, oc) - caoc*caoc - cr*cr;
  float h = b*b - a*c;
  if( h<0.0 ) return (-1.0); //no intersection
  h = sqrt(h);
  return vec2(-b-h,-b+h)/a;
}

vec3 skyColor(vec3 ro, vec3 rd) {
  const vec3 l = normalize(vec3(0.0, 0.0, -1.0));
  const vec3 baseCol = 0.005*vec3(0.05, 0.33, 1.0);
  return baseCol/(1.00025+dot(rd, l));
}

vec3 color(vec3 ww, vec3 uu, vec3 vv, vec3 ro, vec2 p) {
  const float rdd = 2.0;
  const float mm  = 3.0;
  const float rep = 27.0;

  vec3 rd = normalize(-p.x*uu + p.y*vv + rdd*ww);

  vec3 skyCol = skyColor(ro, rd);

  vec2 etc = rayCylinder(ro, rd, ro, vec3(0.0, 0.0, 1.0), 1.0);
  vec3 etcp = ro+rd*etc.y;
  rd.yx = mul(rd.yx, ROT(-0.3*etcp.z));

  vec3 col = skyCol;

  // I read somewhere that if you call atan in a shader you got no business writing shader code.
  //  I even call it in a loop :)
  float a = atan2(rd.y, rd.x);
  for(float i = 0.0; i < mm; ++i) {
    float ma = a;
    float sz = rep+i*6.0;
    float slices = TAU/sz;
    float na = mod1(ma, slices);

    float h1 = hash(na+13.0*i+123.4);
    float h2 = fract(h1*3677.0);
    float h3 = fract(h1*8677.0);

    float tr = mix(0.5, 3.0, h1);
    vec2 tc = rayCylinder(ro, rd, ro, vec3(0.0, 0.0, 1.0), tr);
    vec3 tcp = ro + tc.y*rd;
    vec2 tcp2 = vec2(tcp.z, atan2(tcp.y, tcp.x));

    float zz = mix(0.025, 0.05, sqrt(h1))*rep/sz;
    float tnpy = mod1(tcp2.y, slices);
    float fo = smoothstep(0.5*slices, 0.25*slices, abs(tcp2.y));
    tcp2.x += -h2*TIME;
    tcp2.y *= tr*PI/3;
    float w = mix(.2, 1.0, h2);

    tcp2/=zz;
    float d = abs(tcp2.y);
    d *= zz;

    vec3 bcol = (1.0+cos(vec3(0.0, 1.0, 2.0)+TAU*h3+0.5*h2*h2*tcp.z))*0.00005;
    bcol /= max(d*d, 5E-7*tc.y*tc.y);
    bcol *= exp(-0.04*tc.y*tc.y);
    bcol *= smoothstep(-0.5, 1.0, sin(mix(0.125, 1.0, h2)*tcp.z));
    bcol *= fo;
    col += bcol;
  }

  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  float tm = TIME;
  vec3 ro   = vec3(0.0, 0.0, tm);
  vec3 dro  = normalize(vec3(1.0, 0.0, 3.0));
  dro.xz = mul(dro.xz, ROT(0.2*sin(0.05*tm)));
  dro.yz = mul(dro.yz, ROT(0.2*sin(0.05*tm*sqrt(0.5))));
  const vec3 up = vec3(0.0,1.0,0.0);
  vec3 ww = normalize(dro);
  vec3 uu = normalize(cross(up, ww));
  vec3 vv = (cross(ww, uu));
  vec3 col = color(ww, uu, vv, ro, p);
  col -= 0.125*vec3(0.0, 1.0, 2.0).yzx*length(pp);
  col = aces_approx(col);
  col *= smoothstep(1.5, 0.5, length(pp));
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

  vec3 col = effect(p, pp);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}
