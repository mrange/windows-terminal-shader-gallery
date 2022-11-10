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

static class Models
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

  static readonly JsonNodeOptions _jsonNodeOptions = new()
  {
    PropertyNameCaseInsensitive = false
  };

  static readonly JsonWriterOptions _jsonWriterOptions = new()
  {
    Encoder         = null
  , Indented        = true
  , MaxDepth        = 128
  , SkipValidation  = false
  };

  static readonly JsonDocumentOptions _jsonDocOptions = new()
    {
    // Converters = ...
      AllowTrailingCommas       = true
    , CommentHandling           = JsonCommentHandling.Skip
    , MaxDepth                  = 128
    };

  const string _rootMetadataUrl             = "https://raw.githubusercontent.com/mrange/windows-terminal-shader-gallery/main/gallery/";
  static readonly Uri _allMetadataJsonUri   = new($"{_rootMetadataUrl}/all_metadata.json");

  public static RecordArray<MetadataV1> LoadMetadataFromGithub()
  {
    return _httpClient.GetFromJsonAsync<RecordArray<MetadataV1>>(_allMetadataJsonUri, _jsonOptions).BlockUntilResult();
  }

  public static byte[] LoadFragment0FromGithub(MetadataV1 metadata)
  {
    var uri = new Uri($"{_rootMetadataUrl}/{metadata.Id}/fragment-0.hlsl");
    return _httpClient.GetByteArrayAsync(uri).BlockUntilResult();
  }

  public static JsonNode? LoadSettings(string settingsPath)
  {
    using var stream = File.OpenRead(settingsPath);
    return JsonNode.Parse(stream, _jsonNodeOptions, _jsonDocOptions);
  }

  public static void SaveSettings(string settingsPath, JsonNode root)
  {
    using var stream = File.Create(settingsPath);
    using var writer = new Utf8JsonWriter(stream, _jsonWriterOptions);
    root.WriteTo(writer, _jsonOptions);
  }

}
