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
#define BACKGROUND  Background
#else
float time;
float2 resolution;
static const float4 background = float4(1.,0.5,0.25, 1.)/6.;
#define TIME        time
#define RESOLUTION  resolution
#define BACKGROUND  background
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

//
// ╓――――――――――――――――――╖
// ║    CRT Effect    ║░
// ║        by        ║░
// ║   DeanTheCoder   ║░
// ╙――――――――――――――――――╜░
//  ░░░░░░░░░░░░░░░░░░░░
//
// Effects: Fish eye, scan lines, vignette, screen jitter,
//          background noise, electron bar, shadows,
//          screen glare, fake surround (with reflections).
//
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Parameterized values
static const vec3 brightnessBoost = pow(vec3(1.,1.,1.), 2.0);
static const float
    enableScanlines       = 1.
  , enableSurround        = 1.
  , enableSignalDistortion= 1.
  , enableShadows         = 1.
  ;

vec2 fisheye(vec2 uv)
{
    float r = 2.5;
    uv *= 1.05;
    return r * uv / sqrt(r * r - dot(uv, uv));
}

float bar(float y)
{
    y += 0.5;
    y = fract(y * 0.7 - TIME * 0.1);
    return smoothstep(0.7, 0.98, y) + smoothstep(0.98, 1.0, 1.-y);
}

float h21(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec4 image(vec2 q) {
  vec2 p = -1.+2.*q;
  p *= 1.025;
  vec2 b = step(abs(p), (1.));
  q = 0.5+0.5*p;
  vec4 icol = shaderTexture.Sample(samplerState, q);
  return vec4(icol.rgb, b.x*b.y*icol.w);
}

vec3 effect(vec2 fragCoord)
{
    vec2 res = RESOLUTION;

    // UV coords in the range of -0.5 to 0.5
    vec2 uv = (fragCoord / res) - 0.5;

    // Apply fisheye and border effect (if enabled).
    vec2 st = enableSurround > 0.5 ? fisheye(uv) : uv;

    float ns = h21(fragCoord); // Random number, to use later.

    // Monitor screen.
    float rnd = h21(fragCoord + TIME); // Jitter.

//    return vec4(imageRgb, 1.0);

    float bev = enableSurround > 0.5 ? (max(abs(st.x), abs(st.y)) - 0.498) / 0.035 : 0.0;
    if (bev > 0.0)
    {
        // We're somewhere outside the CRT screen area.
        vec3 col = vec3(0.68, 0.68, 0.592);
        if (bev > 1.0)
        {
            // Monitor face.
            col -= ns * 0.05;
        }
        else
        {
            // Bevel area.
            col *= mix(0.1, 1.0, bev);
            col = col - vec3(0.0, 0.05, 0.1) * ns;

            // Shadow.
            if (enableShadows > 0. && uv.y < 0.0)
                col *= min(1.0, 0.6 * smoothstep(0.8, 1.0, bev) + 0.8 + smoothstep(0.4, 0.3, length(uv * vec2(0.4, 1.0))));

            // Screen reflection in the bevel.
            float dir = sign(-uv.x);
            vec3 tint = (0);
            for (float i = -5.0; i < 5.0; i++)
            {
                for (float j = -5.0; j < 5.0; j++) {
                    vec4 tcol = image((st * 0.9 + vec2(dir * i, j * 2.0) * 0.002 + 0.5));
                    tint += tcol.rgb*tcol.w;
                }
            }

            tint /= 80.0;
            col = mix(tint, col, 0.8 + 0.2 * bev);
        }


        return col;
    }

    vec4 imageRgb = image(st + 0.5 + vec2(rnd * enableSignalDistortion, 0)/res);
    float lum = 1.0;

    // Background noise.
    lum += enableSignalDistortion * (rnd - 0.5)*0.15;

    // Scrolling electron bar.
    lum += enableSignalDistortion * bar(uv.y) * 0.2;

    // Apply scanlines (if enabled).
    int modv = 2+int(RESOLUTION.y/512.);
    if (enableScanlines > 0.5 && (int(fragCoord.y) % modv) <= modv/2)
        lum *= 0.8;

    // Apply main text color tint.
    imageRgb.rgb *= lum * brightnessBoost;


    vec3 col = BACKGROUND.rgb*BACKGROUND.w;
    if (enableShadows > 0.5)
    {
        // Screen shadow.
        float bright = 1.0;
        if (uv.y < 0.0)
            bright = smoothstep(0.43, 0.38, length(uv * vec2(0.4, 1.0)));
        col *= min(1.0, 0.5 + bright);

        // Glare.
        col = mix(col, (0.75 + 0.25 * ns), bright * 0.25 * smoothstep(0.7, 0.0, length((uv - vec2(0.15, -0.3)) * vec2(1.0, 2.0))));
    }

    col += imageRgb.rgb*imageRgb.w;

    // Vignette.
    col *= 1.0 - 1.2 * dot(uv, uv);

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
#if defined(WINDOWS_TERMINAL)
#else
  q.y = 1.-q.y;
#endif

  vec3 col = effect(q*RESOLUTION.xy);

  return vec4(col, 1.0);
}
