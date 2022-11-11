namespace WindowsTerminalShaderTool;

partial class RecordArrayConverter<T> : JsonConverter<RecordArray<T>>
{
  public RecordArrayConverter() {}

  public override bool CanConvert(Type typeToConvert) =>
    typeToConvert == typeof(RecordArray<T>)
    ;

  public override RecordArray<T> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
  {
    var vs = JsonSerializer.Deserialize<T[]>(ref reader, options);
    return vs is not null ? new(vs) : default;
  }

  public override void Write(Utf8JsonWriter writer, RecordArray<T> value, JsonSerializerOptions options)
  {
    var vs = value._vs ?? Array.Empty<T>();
    JsonSerializer.Serialize(writer, vs, options);
  }
}

partial class RecordArrayConverter : JsonConverterFactory
{
  public override bool CanConvert(Type typeToConvert) =>
    typeToConvert.GetGenericTypeDefinition() == typeof(RecordArray<>)
    ;

  public override JsonConverter? CreateConverter(Type typeToConvert, JsonSerializerOptions options)
  {
    if (typeToConvert.GetGenericTypeDefinition() != typeof(RecordArray<>))
    {
      throw new ArgumentException(
          $"Expected typeToConvert to be RecordArray<> but is {typeToConvert.Name}"
        , nameof(typeToConvert)
        );
    }

    var nested  = typeToConvert.GetGenericArguments()[0];
    var rac     = typeof(RecordArrayConverter<>).MakeGenericType(nested);
    var ctor    = rac.GetConstructor(Array.Empty<Type>());
    return (JsonConverter?)ctor?.Invoke(null);
  }
}

static partial class RecordArraysExtensions
{
  public static RecordArray<T> ToRecordArray<T>(this T[]? vs) =>
    new(vs)
    ;

  public static RecordArray<T> ToRecordArray<T>(this IEnumerable<T>? vs) =>
    (vs?.ToArray()).ToRecordArray()
    ;
}

[JsonConverter(typeof(RecordArrayConverter))]
partial struct RecordArray<T> 
  : IEquatable<RecordArray<T>>
  , IEnumerable<T>
  , IStructuralEquatable
  , IStructuralComparable
{
  internal readonly T[]? _vs;

  public RecordArray(params T[]? vs)
  {
    _vs = vs;
  }

  public int Length
  {
    get
    {
      var vs = _vs;
      return vs is not null ? vs.Length : 0;
    }
  }

  public T this[int index]
  {
    get
    {
      var vs = _vs;
      return 
          vs is not null 
        ? vs[index] 
        : throw new IndexOutOfRangeException()
        ;
    }
  }

  public bool Equals(RecordArray<T> other)
  {
    var vs = _vs;
    var ovs = other._vs;

    if (vs is not null && ovs is not null)
    {
      IStructuralEquatable seq = vs;
      return seq.Equals(ovs, EqualityComparer<T>.Default);
    }
    else
    {
      return vs is null && ovs is null;
    }
  }

  public override bool Equals(object? other) =>
    other is RecordArray<T> ra && Equals(ra)
    ;

  public override int GetHashCode()
  {
    IStructuralEquatable seq = _vs ?? Array.Empty<T>();
    return seq.GetHashCode(EqualityComparer<T>.Default);
  }

  public override string ToString()
  {
    var sb = new StringBuilder(64);
    sb.Append("[");

    var vs = _vs;
    if (vs is not null)
    {
      var pre = "";
      foreach (var v in vs)
      {
        sb.Append(pre);
        sb.Append(v);
        pre = "; ";
      }
    }
    sb.Append("]");

    return sb.ToString();
  }

  public IEnumerator<T> GetEnumerator()
  {
    var vs = _vs;
    if (vs is not null)
    {
      foreach (var v in vs) yield return v;
    }
  }

  IEnumerator IEnumerable.GetEnumerator()
  {
    return GetEnumerator();
  }

  public bool Equals(object? other, IEqualityComparer comparer)
  {
    var vs = _vs ?? Array.Empty<T>();
    IStructuralEquatable seq = vs;
    return seq.Equals(other, comparer);
  }

  public int GetHashCode(IEqualityComparer comparer)
  {
    var vs = _vs ?? Array.Empty<T>();
    IStructuralEquatable seq = vs;
    return seq.GetHashCode(comparer);
  }

  public int CompareTo(object? other, IComparer comparer)
  {
    var vs = _vs ?? Array.Empty<T>();
    IStructuralComparable sc = vs;
    return sc.CompareTo(other, comparer);
  }
}
