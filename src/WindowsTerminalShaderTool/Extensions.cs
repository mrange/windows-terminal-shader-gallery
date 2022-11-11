namespace WindowsTerminalShaderTool;

static class Extensions
{
  public static T BlockUntilResult<T>(this Task<T> t)
  {
    return t.GetAwaiter().GetResult();
  }

  public static void BlockUntilDone(this Task t)
  {
    t.GetAwaiter().GetResult();
  }

  public static JsonNode? FindProperty(this JsonNode? node, string name)
  {
    if (node is JsonObject obj)
    {
      _ = obj.TryGetPropertyValue(name, out var inner);
      return inner;
    }
    else
    {
      return null;
    }
  }

}
