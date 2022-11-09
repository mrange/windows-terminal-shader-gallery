namespace WindowsTerminalShaderTool;

sealed record VersionDetector
{
  [JsonPropertyName("metadata-version")]
  public string? MetadataVersion                  { get; set; }
}

sealed record LegalV1
{
  [JsonPropertyName("license-expressions")]
  public RecordArray<string>? LicenseExpressions  { get; set; }

  [JsonPropertyName("authors")]
  public RecordArray<string>? Authors             { get; set; }
}

sealed record InfoV1
{
  [JsonPropertyName("title")]
  public string? Title                            { get; set; }

  [JsonPropertyName("summary")]
  public string? Summary                          { get; set; }

  [JsonPropertyName("shadertoy")]
  public string? Shadertoy                        { get; set; }
}

sealed record MetadataV1
{
  [JsonPropertyName("metadata-version")]
  public string? MetadataVersion                  { get; set; }

  [JsonPropertyName("id")]
  public string? Id                               { get; set; }

  [JsonPropertyName("legal")]
  public LegalV1? Legal                           { get; set; }
}
