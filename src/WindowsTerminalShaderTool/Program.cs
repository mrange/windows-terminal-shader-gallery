namespace WindowsTerminalShaderTool;

static class Program
{
  public static int Main(string[] args)
  {
    Application.Init();

    try
    {


    }
    finally
    {
        Application.Shutdown();
    }

  }
}

sealed class VersionDetector
{
  [JsonPropertyName("metadata-version")]
  public string? MetadataVersion { get; set; }
}

sealed class LegalV1
{
  [JsonPropertyName("license-expressions")]
  public string[]? LicenseExpressions { get; set; }

  [JsonPropertyName("authors")]
  public string[]? Authors            { get; set; }
}

sealed class InfoV1
{
  [JsonPropertyName("title")]
  public string? Title                { get; set; }

  [JsonPropertyName("summary")]
  public string? Summary              { get; set; }

  [JsonPropertyName("shadertoy")]
  public string? Shadertoy            { get; set; }
}

sealed record MetadataV1
{
  [JsonPropertyName("metadata-version")]
  public string? MetadataVersion      { get; set; }

  [JsonPropertyName("id")]
  public string? Id                   { get; set; }

  [JsonPropertyName("legal")]
  public LegalV1? Legal               { get; set; }
}
