using System.Net.Http.Json;

namespace WindowsTerminalShaderTool;

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

  [JsonPropertyName("info")]
  public InfoV1? Info                             { get; set; }
}

static class ModelLoader
{
  static readonly HttpClientHandler _httpClientHandler = new ()
    {
      AutomaticDecompression = DecompressionMethods.All
    };
  static readonly HttpClient _httpClient = new HttpClient(_httpClientHandler);

  static readonly JsonSerializerOptions _jsonOptions = new()
    {
    // Converters = ...
      AllowTrailingCommas       = false
    , DefaultBufferSize         = 128
    , DefaultIgnoreCondition    = JsonIgnoreCondition.WhenWritingNull
    , Encoder                   = null
    , IgnoreReadOnlyFields      = false
    , IgnoreReadOnlyProperties  = false
    , IncludeFields             = false
    , MaxDepth                  = 20
    , NumberHandling            = JsonNumberHandling.Strict
    , PropertyNamingPolicy      = JsonNamingPolicy.CamelCase
    , ReadCommentHandling       = JsonCommentHandling.Skip
    , WriteIndented             = true
    };

  static readonly Uri _allMetaDataJsonUri = new("https://raw.githubusercontent.com/mrange/windows-terminal-shader-gallery/main/gallery/all_metadata.json");

  public static RecordArray<MetadataV1> LoadAll()
  {
    return _httpClient.GetFromJsonAsync<RecordArray<MetadataV1>>(_allMetaDataJsonUri).BlockUntilResult();
  }
}
