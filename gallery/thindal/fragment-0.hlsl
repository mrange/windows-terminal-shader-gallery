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

// License: CC0, author: Mårten Rånge
//  Inspired by: https://www.twitch.tv/thindal
//  Net of stars very obviously inspired by BigWings - The Universe Within:
//   https://www.shadertoy.com/view/lscczl

#define PI              3.141592654
#define TAU             (2.0*PI)
#define TTIME           (TAU*TIME)
#define ROT(a)          mat2(cos(a), sin(a), -sin(a), cos(a))
#define PCOS(x)         (0.5+0.5*cos(x))
#define LINECOL(x,y)    lineCol(aa, z, np, cp, cps[x], cps[y]);


static const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

static const vec3 baseLogoCol = HSV2RGB(vec3(0.715, 0.333, 0.8));

// License: Unknown, author: Unknown, found: don't remember
vec4 alphaBlend(vec4 back, vec4 front) {
  float w = front.w + back.w*(1.0-front.w);
  vec3 xyz = (front.xyz*front.w + back.xyz*back.w*(1.0-front.w))/w;
  return w > 0.0 ? vec4(xyz, w) : 0.0*unit4;
}

// License: Unknown, author: Unknown, found: don't remember
vec3 alphaBlend(vec3 back, vec4 front) {
  return mix(back, front.xyz, front.w);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

// License: Unknown, author: Unknown, found: don't remember
vec2 hash(vec2 p) {
  p = vec2(dot (p, vec2 (127.1, 311.7)), dot (p, vec2 (269.5, 183.3)));
  return -1. + 2.*fract (sin (p)*43758.5453123);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/articles/distfunctions2d
float segment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p-a, ba = b-a;
  float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
  return length(pa - ba*h);
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

vec2 cellPos(vec2 np) {
  vec2 hp = hash(np);
  return 0.3*vec2(sin(hp*TIME));
}

vec3 lineCol(float aa, float z, vec2 np, vec2 cp, vec2 p0, vec2 p1) {
  float l = length(p0 - p1);
  float d = segment(cp, p0, p1)-1.5*aa/z;

  float cd = min(length(cp-p0), length(cp-p1));

  float v = 2.0*exp(-1.75*l)*exp(-15.*max(d, 0.0));
  float s = 1.0-tanh_approx(v);
  vec3 hsv = vec3(0.715, s, v);

  return hsv2rgb(hsv);
}

float plane(vec2 p, vec2 n, float m) {
  return dot(p, n) + m;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/articles/distfunctions2d
float polygon4(vec2 v[4], vec2 p) {
  const int N = 4;
  float d = dot(p-v[0],p-v[0]);
  float s = 1.0;
  for( int i=0, j=N-1; i<N; j=i, ++i) {
    vec2 e = v[j] - v[i];
    vec2 w =    p - v[i];
    vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
    d = min( d, dot(b,b) );
    vector<bool, 3> c = vector<bool, 3>(p.y>=v[i].y,p.y<v[j].y,e.x*w.y>e.y*w.x);
    if( all(c) || all(!(c)) ) s*=-1.0;
  }
  return s*sqrt(d);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/articles/distfunctions2d
float isosceles(vec2 p, vec2 q) {
  p.x = abs(p.x);
  vec2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = p - q*vec2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
  float s = -sign( q.y );
  vec2 d = min( vec2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
               vec2( dot(b,b), s*(p.y-q.y)  ));
  return -sqrt(d.x)*sign(d.y);
}

float dthindal(vec2 p) {
  vec2 p0 = -p.yx;
  vec2 q0 = vec2(0.57, 0.96);

  vec2 p1 = -p.yx;
  vec2 q1 = vec2(0.31, 0.575);

  if (p.y > 0.0) {
    q0 = vec2(0.524, 0.88);
    q1 = vec2(0.29, 0.5);
  }

  p0.y += 0.59;
  p1.y += 0.35;

  const vec2 p2[4] = {vec2(-0.62, 0.075), vec2(-0.035, 0.075), vec2(-0.035, -0.075), vec2(-0.365, -0.075)};

  float d0 = isosceles(p0, q0);
  float d1 = isosceles(p1, q1);
  float d2 = polygon4(p2, p);
  float d3 = plane(p, normalize(vec2(1.0, 1.7)), -0.055);

  d0 = max(d0, -d1);
  if (p.y > 0.0) {
    d0 = max(d0, -d3);
  }

  float d = d0;
  d = min(d, d2);

  return d;
}

vec4 gridColor(vec2 p) {
  float z = 0.2;
  float aa = 2.0/RESOLUTION.y;

  vec3 col = 0.0*unit3;
  p /= z;
  vec2 cp = fract(p) - 0.5;
  vec2 np = floor(p);

  vec2 cps[9];
  int idx = 0;

  for (float y = -1.0; y <= 1.0; ++y) {
    for (float x = -1.0; x <= 1.0; ++x) {
      vec2 off = vec2(x, y);
      cps[idx++] = cellPos(np+off) + off;
    }
  }

  col += LINECOL(4, 0);
  col += LINECOL(4, 1);
  col += LINECOL(4, 2);
  col += LINECOL(4, 3);

  col += LINECOL(4, 5);
  col += LINECOL(4, 6);
  col += LINECOL(4, 7);
  col += LINECOL(4, 8);

  col += LINECOL(1, 3);
  col += LINECOL(1, 5);
  col += LINECOL(7, 3);
  col += LINECOL(7, 5);

  float i = col.x+col.y+col.z;

  return vec4(col, tanh_approx(i));
}

vec3 thindal(vec3 col, vec2 p, vec2 q) {
  const float zi = 1.1;
  vec2 op = p;
  float aa = 2.0/RESOLUTION.y;

  float fade = 0.9*mix(0.9, 1.0, PCOS(0.25*TTIME+10.0*q.x));

  vec2 pi = p;
  const float period = 10.0;
  const float coff = PI;
  float ptime = (1.0/period)*TIME;
  float mtime = mod(ptime, 2.0);
  float ntime = floor(ptime/2.0);
  float anim = min(1.0, mtime)*step(1.0, ptime);
  float h = hash(ntime+123.4);
  float s = floor(h*5.0);
  float off = 0.6*p.x+p.y;
  if (s == 1.0) {
    off = p.x+p.y*p.y;
  }  else if (s == 2.0) {
    off = p.x+p.y*p.y*p.y;
  } else if (s == 3.0) {
    off = p.x*p.y+p.y*p.x;
  } else if (s == 4.0) {
    off = p.x+p.y*p.x;
  }

  off += -2.0/3.0+PI*anim;
  float angle = off+mix(coff*0.42, -coff*0.42 , fade);
  float split = angle+coff;
  int _nsplit = int(mod1(split, 1.0*coff));

  pi /= zi;
  float di  = dthindal(pi);
  float dii = abs(di-0.0125) - 0.0025;
  di = min(di, dii);
  di *= zi;

  float dg = di;

  const vec3 lcol2 = vec3(2.0, 1.55, 1.25).xzy*0.85;

  float gmix = pow(abs(cos(angle)), 8.0);
  float gmix2 = abs(1.0/tanh_approx(split))*0.5;

  dg = abs(dg-0.025);
  float glow = exp(-10.0*max(dg+0., 0.0));
  vec3 glowCol = mix(lcol2.zyx*lcol2.zyx/6.0, lcol2.zyx, glow*glow)*gmix2;
  col -= 0.5*exp(-10.0*max(di+0.1, 0.0));
  col = mix(col, vec3(mix(baseLogoCol, sqrt(glowCol*0.5), gmix)), smoothstep(-aa, aa, -di));
  col += 0.5*smoothstep(0.5, 0.45, abs(anim-0.5))*glowCol*glow*gmix;

  return col;
}

// The path function
vec3 offset(float z) {
  float a = z;
  vec2 p = -0.075*(vec2(cos(a), sin(a*sqrt(2.0))) + vec2(cos(a*sqrt(0.75)), sin(a*sqrt(0.5))));
  return vec3(p, z);
}

// The derivate of the path function
//  Used to generate where we are looking
vec3 doffset(float z) {
  float eps = 0.1;
  return 0.5*(offset(z + eps) - offset(z - eps))/eps;
}

// The second derivate of the path function
//  Used to generate tilt
vec3 ddoffset(float z) {
  float eps = 0.1;
  return 0.125*(doffset(z + eps) - doffset(z - eps))/eps;
}

vec4 plane(vec3 ro, vec3 rd, vec3 pp, vec3 off, float aa, float n) {
  float h = hash(n);
  float s = mix(0.05, 0.25, h);

  vec3 hn;
  vec2 p = (pp-off*vec3(1.0, 1.0, 0.0)).xy;
  p = mul(ROT(TAU*h), p);

  return gridColor(p);
}

vec3 skyColor(vec3 ro, vec3 rd) {
  return 0.0*unit3;
}

vec3 color(vec3 ww, vec3 uu, vec3 vv, vec3 ro, vec2 p) {
  float lp = length(p);
  vec2 np = p + 1.0/RESOLUTION.xy;
  float rdd = (2.0+1.0*tanh_approx(lp));  // Playing around with rdd can give interesting distortions
  vec3 rd = normalize(p.x*uu + p.y*vv + rdd*ww);
  vec3 nrd = normalize(np.x*uu + np.y*vv + rdd*ww);

  const float planeDist = 1.0-0.;
  const int furthest = 4;
  const int fadeFrom = max(furthest-3, 0);

  const float fadeDist = planeDist*float(furthest - fadeFrom);
  float nz = floor(ro.z / planeDist);

  vec3 skyCol = skyColor(ro, rd);


  vec4 acol = 0.0*unit4;
  const float cutOff = 0.95;
  bool cutOut = false;

  // Steps from nearest to furthest plane and accumulates the color
  for (int i = 1; i <= furthest; ++i) {
    float pz = planeDist*nz + planeDist*float(i);

    float pd = (pz - ro.z)/rd.z;

    if (pd > 0.0 && acol.w < cutOff) {
      vec3 pp = ro + rd*pd;
      vec3 npp = ro + nrd*pd;

      float aa = 3.0*length(pp - npp);

      vec3 off = offset(pp.z);

      vec4 pcol = plane(ro, rd, pp, off, aa, nz+float(i));

      float nz = pp.z-ro.z;
      float fadeIn = smoothstep(planeDist*float(furthest), planeDist*float(fadeFrom), nz);
      float fadeOut = smoothstep(0.0, planeDist*0.1, nz);
      pcol.xyz = mix(skyCol, pcol.xyz, fadeIn);
      pcol.w *= fadeOut;
      pcol = clamp(pcol, 0.0, 1.0);

      acol = alphaBlend(pcol, acol);
    } else {
      cutOut = true;
      break;
    }

  }

  vec3 col = alphaBlend(skyCol, acol);
// To debug cutouts due to transparency
//  col += cutOut ? vec3(1.0, -1.0, 0.0) : vec3(0.0);
  return col;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/index.htm
vec3 postProcess(vec3 col, vec2 q) {
  col = clamp(col, 0.0, 1.0);
  col = sqrt(col);
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, unit3*(dot(col, unit3*(0.33))), -0.4);
  col *=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

vec3 effect(vec2 p, vec2 q) {
  float tm  = TIME*0.3;
  vec3 ro   = offset(tm);
  vec3 dro  = doffset(tm);
  vec3 ddro = ddoffset(tm);

  vec3 ww = normalize(dro);
  vec3 uu = normalize(cross(normalize(vec3(0.0,1.0,0.0)+ddro), ww));
  vec3 vv = normalize(cross(ww, uu));

  vec3 col = color(ww, uu, vv, ro, p);

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
#if defined(WINDOWS_TERMINAL)
  p.y = -p.y;
#endif
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect(p, q);
  col *= smoothstep(3.0, 6.0, TIME);
  col = thindal(col, p, q);
  col *= smoothstep(0.0, 10.0*q.y, TIME);
  col = postProcess(col, q);

  vec4 fg = shaderTexture.Sample(samplerState, q);
  vec4 sh = shaderTexture.Sample(samplerState, q-2.0*unit2/RESOLUTION.xy);

  col = mix(col, 0.0*unit3, sh.w);
  col = mix(col, fg.xyz, fg.w);

  return vec4(col, 1.0);
}



