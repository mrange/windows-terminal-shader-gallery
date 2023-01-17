// ----------------------------------------------------------------------------
// CC0: Simple DirectX pixel shader for Windows Terminal

// I like to use KodeLife to develop shaders in
//  When I am working in KodeLife the following line is commented
//  Then I uncomment it when deploying Windows Terminal
#define WINDOWS_TERMINAL

// When developing a shader the foreground can be distracting
//  When deploying in Windows Terminal I uncomment next line to get the text
#define DRAW_FOREGROUND

// ----------------------------------------------------------------------------
// The "interface" to Windows Terminal

Texture2D shaderTexture;
SamplerState samplerState;

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
// this is the "interface" to KodeLife
float time;
float2 resolution;

#define TIME        time
#define RESOLUTION  resolution
#endif
// ----------------------------------------------------------------------------

#if defined(WINDOWS_TERMINAL)
float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
#else
float4 ps_main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
#endif
{
  float2 q = tex;
  float2 p = -1.0 + 2.0*q;

  // Compute a simple gradient
  float3 col = float3(.0, q).zxy;
  // Reduce intensity of gradient more to the corners
  col *= 0.71*smoothstep(1.75, 0., length(p));

#if defined(DRAW_FOREGROUND)
  // Draw the foreground
  float4 fg = shaderTexture.Sample(samplerState, q);
  float4 sh = shaderTexture.Sample(samplerState, q-2.0/RESOLUTION.xy);

  // In order to make the text more readable with "wild" backgrounds
  //  draw the foreground as black first with a slight offset
  col = lerp(col, 0.0, sh.w);
  col = lerp(col, fg.xyz, fg.w);
#endif

  return float4(col, 1.0);
}
