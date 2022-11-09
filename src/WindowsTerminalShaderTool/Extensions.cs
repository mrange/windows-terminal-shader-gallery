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

}
