/*
Copyright 2022 Mårten Rånge
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
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
