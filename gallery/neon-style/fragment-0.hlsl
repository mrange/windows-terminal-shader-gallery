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

#define TIME        (0.5*time)
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


// CC0: For the neon style enjoyers
//  Or is it synthwave style? Don't know!
//  Anyone been tinkering with this for awhile and now want to get on with other stuff
//  Hopefully someone enjoys it.

//#define THAT_CRT_FEELING

#define PI          3.141592654
#define PI_2        (0.5*PI)
#define TAU         (2.0*PI)
#define SCA(a)      vec2(sin(a), cos(a))
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
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
vec3 rgb2hsv(vec3 c) {
  const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

static const vec3 skyCol       = HSV2RGB(vec3(0.58, 0.86, 1.0));
static const vec3 speCol1      = HSV2RGB(vec3(0.60, 0.25, 1.0));
static const vec3 speCol2      = HSV2RGB(vec3(0.55, 0.25, 1.0));
static const vec3 diffCol1     = HSV2RGB(vec3(0.60, 0.90, 1.0));
static const vec3 diffCol2     = HSV2RGB(vec3(0.55, 0.90, 1.0));
static const vec3 sunCol1      = HSV2RGB(vec3(0.60, 0.50, 0.5));
static const vec3 sunDir2      = normalize(vec3(0., 0.82, 1.0));
static const vec3 sunDir       = normalize(vec3(0.0, 0.05, 1.0));
static const vec3 sunCol       = HSV2RGB(vec3(0.58, 0.86, 0.0005));
static const float mountainPos = -20.0;

// License: MIT, author: Pascal Gilcher, found: https://www.shadertoy.com/view/flSXRV
float atan_approx(float y, float x) {
  float cosatan2 = x / (abs(x) + abs(y));
  float t = PI_2 - cosatan2 * PI_2;
  return y < 0.0 ? -t : t;
}

// License: Unknown, author: Unknown, found: don't remember
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

vec3 toSpherical(vec3 p) {
  float r   = length(p);
  float t   = acos(p.z/r);
  float ph  = atan_approx(p.y, p.x);
  return vec3(r, t, ph);
}

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

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/intersectors/intersectors.htm
float rayPlane(vec3 ro, vec3 rd, vec4 p) {
  return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}


// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float equilateralTriangle(vec2 p) {
  const float k = sqrt(3.0);
  p.x = abs(p.x) - 1.0;
  p.y = p.y + 1.0/k;
  if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
  p.x -= clamp( p.x, -2.0, 0.0 );
  return -length(p)*sign(p.y);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float segment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p-a, ba = b-a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length(pa - ba*h);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

// License: MIT, author: Inigo Quilez, found: https://www.shadertoy.com/view/XslGRr
float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);

  vec2 u = f*f*(3.0-2.0*f);

  float a = hash(i + vec2(0.0,0.0));
  float b = hash(i + vec2(1.0,0.0));
  float c = hash(i + vec2(0.0,1.0));
  float d = hash(i + vec2(1.0,1.0));

  float m0 = mix(a, b, u.x);
  float m1 = mix(c, d, u.x);
  float m2 = mix(m0, m1, u.y);

  return m2;
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/spherefunctions/spherefunctions.htm
vec2 raySphere(vec3 ro, vec3 rd, vec4 dim) {
  vec3 ce = dim.xyz;
  float ra = dim.w;
  vec3 oc = ro - ce;
  float b = dot( oc, rd );
  float c = dot( oc, oc ) - ra*ra;
  float h = b*b - c;
  if( h<0.0 ) return (-1.0); // no intersection
  h = sqrt( h );
  return vec2( -b-h, -b+h );
}

vec3 skyRender(vec3 ro, vec3 rd) {
  vec3 col = (0.0);
  col += 0.025*skyCol;
  col += skyCol*0.0033/pow((1.001+((dot(sunDir2, rd)))), 2.0);

  float tp0  = rayPlane(ro, rd, vec4(vec3(0.0, 1.0, 0.0), 4.0));
  float tp1  = rayPlane(ro, rd, vec4(vec3(0.0, -1.0, 0.0), 6.0));
  float tp = tp1;
  tp = max(tp0,tp1);


  if (tp1 > 0.0) {
    vec3 pos  = ro + tp1*rd;
    vec2 pp = pos.xz;
    float db = box(pp, vec2(5.0, 9.0))-3.0;

    col += (4.0)*skyCol*rd.y*rd.y*smoothstep(0.25, 0.0, db);
    col += (0.8)*skyCol*exp(-0.5*max(db, 0.0));
    col += 0.25*sqrt(skyCol)*max(-db, 0.0);
  }

  if (tp0 > 0.0) {
    vec3 pos  = ro + tp0*rd;
    vec2 pp = pos.xz;
    float ds = length(pp) - 0.5;

    col += (0.25)*skyCol*exp(-.5*max(ds, 0.0));
  }

  return clamp(col, 0.0, 10.0);
}

vec4 sphere(vec3 ro, vec3 rd, vec4 sdim) {
  vec2 si = raySphere(ro, rd, sdim);

  vec3 nsp = ro + rd*si.x;

  const vec3 lightPos1   = vec3(0.0, 10.0, 10.0);
  const vec3 lightPos2   = vec3(0.0, -80.0, 10.0);

  vec3 nld1   = normalize(lightPos1-nsp);
  vec3 nld2   = normalize(lightPos2-nsp);

  vec3 nnor   = normalize(nsp - sdim.xyz);

  vec3 nref   = reflect(rd, nnor);

  const float sf = 4.0;
  float ndif1 = max(dot(nld1, nnor), 0.0);
  ndif1       *= ndif1;
  vec3 nspe1  = pow(speCol1*max(dot(nld1, nref), 0.0), sf*vec3(1.0, 0.8, 0.5));

  float ndif2 = max(dot(nld2, nnor), 0.0);
  ndif2       *= ndif2;
  vec3 nspe2  = pow(speCol2*max(dot(nld2, nref), 0.0), sf*vec3(0.9, 0.5, 0.5));

  vec3 nsky   = skyRender(nsp, nref);
  float nfre  = 1.0+dot(rd, nnor);
  nfre        *= nfre;

  vec3 scol = (0.0);
  scol += nsky*mix((0.25), vec3(0.5, 0.5, 1.0), nfre);
  scol += diffCol1*ndif1;
  scol += diffCol2*ndif2;
  scol += nspe1;
  scol += nspe2;

  float t = tanh_approx(2.0*(si.y-si.x)/sdim.w);

  return vec4(scol, t);
}

vec3 sphereRender(vec3 ro, vec3 rd) {
  vec3 skyCol = skyRender(ro, rd);
  vec3 col = skyCol;
  const vec4 sdim0 = vec4(vec3(0.0, 0.0, 0.0), 2.0);
  vec4 scol0 = sphere(ro, rd, sdim0);
  col = mix(col, scol0.xyz, scol0.w);
  return col;
}

vec3 sphereEffect(vec2 p) {
  const float fov = tan(TAU/6.0);
  const vec3 ro = 1.0*vec3(0.0, 2.0, 5.0);
  const vec3 la = vec3(0.0, 0.0, 0.0);
  const vec3 up = vec3(0.0, 1.0, 0.0);

  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross(up, ww));
  vec3 vv = cross(ww,uu);
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww);

  vec3 col = sphereRender(ro, rd);

  return col;
}

vec3 cityOfKali(vec2 p) {
  vec2 c = -vec2(0.5, 0.5)*1.12;

  float s = 2.0;
  vec2 kp = p/s;

  const float a = PI/4.0;
  const vec2 n = vec2(cos(a), sin(a));

  float ot2 = 1E6;
  float ot3 = 1E6;
  float n2 = 0.0;
  float n3 = 0.0;

  const float mx = 12.0;
  for (float i = 0.0; i < mx; ++i) {
    float m = (dot(kp, kp));
    s *= m;
    kp = abs(kp)/m + c;
    float d2 = (abs(dot(kp,n)))*s;
    if (d2 < ot2) {
      n2 = i;
      ot2 = d2;
    }
    float d3 = (dot(kp, kp));
    if (d3 < ot3) {
      n3 = i;
      ot3 = d3;
    }
  }
  vec3 col = (0.0);
  n2 /= mx;
  n3 /= mx;
  col += 0.25*(hsv2rgb(vec3(0.8-0.2*n2*n2, 0.90, 0.025))/(sqrt(ot2)+0.0025));
  col += hsv2rgb(vec3(0.55+0.8*n3, 0.85, 0.00000025))/(ot3*ot3+0.000000025);
  return col;
}

vec3 outerSkyRender(vec3 ro, vec3 rd) {
  vec3 center = ro+vec3(-100.0, 40.0, 100.0);
  vec4 sdim = vec4(center, 50);
  vec2 pi = raySphere(ro, rd, sdim);
  const vec3 pn = normalize(vec3(0., 1.0, -0.8));
  vec4 pdim = vec4(pn, -dot(pn, center));
  float ri = rayPlane(ro, rd, pdim);

  vec3 col = (0.0);

  col += sunCol/pow((1.001-((dot(sunDir, rd)))), 2.0);

  if (pi.x != -1.0) {
    vec3 pp = ro + rd*pi.x;
    vec3 psp= pp-sdim.xyz;
    vec3 pn = normalize(pp-sdim.xyz);
    psp = psp.zxy;

    const mat2 r0 = ROT(-0.5);
    psp.yz = mul(r0, psp.yz);
    psp.xy = mul(ROT(0.025*TIME), psp.xy);

    vec3 pss= toSpherical(psp);
    vec3 pcol = (0.0);
    float dif = max(dot(pn, sunDir), 0.0);
    vec3 sc = 2000.0*sunCol;
    pcol += sc*dif;
    pcol += (cityOfKali(pss.yz))*smoothstep(0.125, 0.0, dif);
    pcol += pow(max(dot(reflect(rd, pn), sunDir), 0.0), 9.0)*sc;
    col = mix(col, pcol, tanh_approx(0.125*(pi.y-pi.x)));

  }

  vec3 gcol = (0.0);

  vec3 rp = ro + rd*ri;
  float rl = length(rp-center);
  float rb = 1.55*sdim.w;
  float re = 2.45*sdim.w;
  float rw = 0.1*sdim.w;
  vec3 rcol = hsv2rgb(vec3(clamp((0.005*(rl+32.0)), 0.6, 0.8), 0.9, 1.0));
  gcol = rcol*0.025;
  if (ri > 0.0 && (pi.x == -1.0 || ri < pi.x)) {
    float mrl = rl;
    float nrl = mod1(mrl, rw);
    float rfre = 1.0+dot(rd, pn);
    vec3 rrcol = (rcol/max(abs(mrl), 0.1+smoothstep(0.7, 1.0, rfre)));
    rrcol *= smoothstep(1.0, 0.3, rfre);
    rrcol *= smoothstep(re, re-0.5*rw, rl);
    rrcol *= smoothstep(rb-0.5*rw, rb, rl);
    col += rrcol;;
  }

  col += gcol/max(abs(rd.y), 0.0033);

return col;
}

vec3 triRender(vec3 col, vec3 ro, vec3 rd, inout float maxt) {
  const vec3 tpn = normalize(vec3(0.0, 0.0, 1.0));
  const vec4 tpdim = vec4(tpn, -2.0);
  float tpd = rayPlane(ro, rd, tpdim);

  if (tpd < 0.0 || tpd > maxt) {
    return col;
  }

  vec3 pp = ro+rd*tpd;
  vec2 p = pp.xy;
  p *= 0.5;

  const float off = 1.2-0.02;
  vec2 op = p;
  p.y -= off;
  const vec2 n = SCA(-PI/3.0);
  vec2 gp = p;
  float hoff = 0.15*dot(n, p);
  vec3 gcol = hsv2rgb(vec3(clamp(0.7+hoff, 0.6, 0.8), 0.90, 0.02));
  vec2 pt = p;
  pt.y = -pt.y;
  const float zt = 1.0;
  float dt = equilateralTriangle(pt/zt)*zt;
//  col += 2.0*gcol;
  col = dt < 0.0 ? sphereEffect(1.5*(p)) : col;
  col += (gcol/max(abs(dt), 0.001))*smoothstep(0.25, 0.0, dt);
  if (dt < 0.0) {
    maxt = tpd;
  }
  return col;
}

float heightFactor(vec2 p) {
  return 4.0*smoothstep(7.0, 0.5, abs(p.x))+.5;
}

float hifbm(vec2 p) {
  p *= 0.25;
  float hf = heightFactor(p);
  const float aa = 0.5;
  const float pp = 2.0-0.;

  float sum = 0.0;
  float a   = 1.0;

  for (int i = 0; i < 5; ++i) {
    sum += a*vnoise(p);
    a *= aa;
    p *= pp;
  }

  return hf*sum;
}

float hiheight(vec2 p) {
  return hifbm(p);
}

float lofbm(vec2 p) {
  p *= 0.25;
  float hf = heightFactor(p);
  const float aa = 0.5;
  const float pp = 2.0-0.;

  float sum = 0.0;
  float a   = 1.0;

  for (int i = 0; i < 3; ++i) {
    sum += a*vnoise(p);
    a *= aa;
    p *= pp;
  }

  return hf*sum;
}

float loheight(vec2 p) {
  return lofbm(p)-0.5;
}

vec3 mountainRender(vec3 col, vec3 ro, vec3 rd, bool flip, inout float maxt) {
  const vec3 tpn = normalize(vec3(0.0, 0.0, 1.0));
  const vec4 tpdim = vec4(tpn, mountainPos);
  float tpd = rayPlane(ro, rd, tpdim);

  if (tpd < 0.0 || tpd > maxt) {
    return col;
  }

  vec3 pp = ro+rd*tpd;
  vec2 p = pp.xy;
  const float cw = 1.0-0.25;
  float hz = 0.0*TIME+1.0;
  float lo = loheight(vec2(p.x, hz));
  vec2 cp = p;
  float cn = mod1(cp.x, cw);


  const float reps = 1.0;

  float d = 1E3;

  for (float i = -reps; i <= reps; ++i) {
    float x0 = (cn -0.5 + (i))*cw;
    float x1 = (cn -0.5 + (i + 1.0))*cw;

    float y0 = hiheight(vec2(x0, hz));
    float y1 = hiheight(vec2(x1, hz));

    float dd = segment(cp, vec2(-cw*0.5 + cw * float(i), y0), vec2(cw*0.5 + cw * float(i), y1));

    d = min(d, dd);
  }

  vec3 rcol = hsv2rgb(vec3(clamp(0.7+(0.5*(rd.x)), 0.6, 0.8), 0.95, 0.125));

  float sd = 1.0001-((dot(sunDir, rd)));

  vec3 mcol = col;
  float aa = fwidth(p.y);
  if ((ddy(d) > 0.0) == !flip) {
    mcol *= mix(0.0, 1.0, smoothstep(aa, -aa, d-aa));
    mcol += HSV2RGB(vec3(0.55, 0.85, 0.8))*smoothstep(0.0, 5.0, lo-p.y);
    col = mcol;
    maxt = tpd;
  }
  col += 3.*rcol/(abs(d)+0.005+800.*sd*sd*sd*sd);
  col += HSV2RGB(vec3(0.55, 0.96, 0.075))/(abs(p.y)+0.05);

  return col;
}

vec3 groundRender(vec3 col, vec3 ro, vec3 rd, inout float maxt) {
  const vec3 gpn = normalize(vec3(0.0, 1.0, 0.0));
  const vec4 gpdim = vec4(gpn, 0.0);
  float gpd = rayPlane(ro, rd, gpdim);

  if (gpd < 0.0) {
    return col;
  }

  maxt = gpd;

  vec3 gp     = ro + rd*gpd;
  float gpfre = 1.0 + dot(rd, gpn);
  gpfre *= gpfre;
  gpfre *= gpfre;
  gpfre *= gpfre;

  vec3 grr = reflect(rd, gpn);

  vec2 ggp    = gp.xz;
  ggp.y += TIME;
  float dfy   = -ddy(ggp.y);
  float gcf = sin(ggp.x)*sin(ggp.y);
  vec2 ggn    = mod2(ggp, (1.0));
  float ggd   = min(abs(ggp.x), abs(ggp.y));

  vec3 gcol = hsv2rgb(vec3(0.7+0.1*gcf, 0.90, 0.02));

  float rmaxt = 1E6;
  vec3 rcol = outerSkyRender(gp, grr);
  rcol = mountainRender(rcol, gp, grr, true, rmaxt);
  rcol = triRender(rcol, gp, grr, rmaxt);

  col = gcol/max(ggd, 0.0+0.25*dfy)*exp(-0.25*gpd);
  rcol += HSV2RGB(vec3(0.65, 0.85, 1.0))*gpfre;
  rcol = 4.0*tanh(rcol*0.25);
  col += rcol*gpfre;

  return col;
}

vec3 render(vec3 ro, vec3 rd) {
  float maxt = 1E6;

  vec3 col = outerSkyRender(ro, rd);
  col = groundRender(col, ro, rd, maxt);
  col = mountainRender(col, ro, rd, false, maxt);
  col = triRender(col, ro, rd, maxt);

  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  const float fov = tan(TAU/6.0);
  const vec3 ro = 1.0*vec3(0.0, 1.0, -4.);
  const vec3 la = vec3(0.0, 1.0, 0.0);
  const vec3 up = vec3(0.0, 1.0, 0.0);

  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross(up, ww));
  vec3 vv = cross(ww,uu);
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww);

  float aa = 2.0/RESOLUTION.y;

  vec3 col = render(ro, rd);
#if defined(THAT_CRT_FEELING)
  col *= smoothstep(1.5, 0.5, length(pp));
  col *= 1.25*mix((0.5), (1.0),smoothstep(-0.9, 0.9, sin(0.25*TAU*p.y/aa+TAU*vec3(0.0, 1., 2.0)/3.0)));
#endif
  col -= 0.05*vec3(.00, 1.0, 2.0).zyx;
  col = aces_approx(col);
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
