namespace WindowDesktopShaderTool;

sealed class OopsException : Exception
{
  public OopsException(string msg) : base(msg)
  {
  }
}

static class Program
{
  static void Print(ConsoleColor color, string msg)
  {
    var cc = Console.ForegroundColor;
    try
    {
      Console.ForegroundColor = color;
      Console.WriteLine(msg);
    }
    finally
    {
      Console.ForegroundColor = cc;
    }
  }

  static bool VerboseOn = false;

  static void Verbose(string msg)
  {
    if (VerboseOn)
    {
      Print(ConsoleColor.Magenta, msg);
    }
  }

  static void Info(string msg)
  {
    Print(ConsoleColor.Gray, msg);
  }

  static void Hilight(string msg)
  {
    Print(ConsoleColor.Cyan, msg);
  }

  static void Good(string msg)
  {
    Print(ConsoleColor.Green, msg);
  }

  static void Fail(string msg)
  {
    Print(ConsoleColor.Red, msg);
  }

  [DllImport("user32.dll", SetLastError = true)]
  public static extern IntPtr FindWindow(
      string  lpClassName
    , string? lpWindowName
    );

  [DllImport("user32.dll", SetLastError = true)]
  public static extern IntPtr FindWindowEx(
      IntPtr parentHandle
    , IntPtr childAfter
    , string className
    , IntPtr windowTitle
    );

  [Flags]
  public enum SendMessageTimeoutFlags : uint
  {
      SMTO_NORMAL             = 0x0
    , SMTO_BLOCK              = 0x1
    , SMTO_ABORTIFHUNG        = 0x2
    , SMTO_NOTIMEOUTIFNOTHUNG = 0x8
    , SMTO_ERRORONEXIT        = 0x20
  }

  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
  public static extern IntPtr SendMessageTimeout(
      IntPtr                  windowHandle
    , uint                    Msg
    , IntPtr                  wParam
    , IntPtr                  lParam
    , SendMessageTimeoutFlags flags
    , uint                    timeout
    , out                     IntPtr result);

  public delegate bool EnumWindowsProc(
      IntPtr hwnd
    , IntPtr lParam
    );

  [DllImport("user32.dll")]
  [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool EnumWindows(
      EnumWindowsProc lpEnumFunc
    , IntPtr          lParam
    );

  /// <summary>Values to pass to the GetDCEx method.</summary>
  [Flags()]
  public enum DeviceContextValues : uint
  {
      /// <summary>DCX_WINDOW: Returns a DC that corresponds to the window rectangle rather
      /// than the client rectangle.</summary>
      Window            = 0x00000001

      /// <summary>DCX_CACHE: Returns a DC from the cache, rather than the OWNDC or CLASSDC
      /// window. Essentially overrides CS_OWNDC and CS_CLASSDC.</summary>
    , Cache             = 0x00000002

      /// <summary>DCX_NORESETATTRS: Does not reset the attributes of this DC to the
      /// default attributes when this DC is released.</summary>
    , NoResetAttrs      = 0x00000004

      /// <summary>DCX_CLIPCHILDREN: Excludes the visible regions of all child windows
      /// below the window identified by hWnd.</summary>
    , ClipChildren      = 0x00000008

      /// <summary>DCX_CLIPSIBLINGS: Excludes the visible regions of all sibling windows
      /// above the window identified by hWnd.</summary>
    , ClipSiblings      = 0x00000010

      /// <summary>DCX_PARENTCLIP: Uses the visible region of the parent window. The
      /// parent's WS_CLIPCHILDREN and CS_PARENTDC style bits are ignored. The origin is
      /// set to the upper-left corner of the window identified by hWnd.</summary>
    , ParentClip        = 0x00000020

      /// <summary>DCX_EXCLUDERGN: The clipping region identified by hrgnClip is excluded
      /// from the visible region of the returned DC.</summary>
    , ExcludeRgn        = 0x00000040

      /// <summary>DCX_INTERSECTRGN: The clipping region identified by hrgnClip is
      /// intersected with the visible region of the returned DC.</summary>
    , IntersectRgn      = 0x00000080

      /// <summary>DCX_EXCLUDEUPDATE: Unknown...Undocumented</summary>
    , ExcludeUpdate     = 0x00000100

      /// <summary>DCX_INTERSECTUPDATE: Unknown...Undocumented</summary>
    , IntersectUpdate   = 0x00000200

      /// <summary>DCX_LOCKWINDOWUPDATE: Allows drawing even if there is a LockWindowUpdate
      /// call in effect that would otherwise exclude this window. Used for drawing during
      /// tracking.</summary>
    , LockWindowUpdate  = 0x00000400

      /// <summary>DCX_USESTYLE: Undocumented, something related to WM_NCPAINT message.</summary>
    , UseStyle          = 0x00010000

    /// <summary>DCX_VALIDATE When specified with DCX_INTERSECTUPDATE, causes the DC to
    /// be completely validated. Using this function with both DCX_INTERSECTUPDATE and
    /// DCX_VALIDATE is identical to using the BeginPaint function.</summary>
    , Validate          = 0x00200000
  }

  [DllImport("user32.dll")]
  public static extern IntPtr GetDCEx(
      IntPtr              hWnd
    , IntPtr              hrgnClip
    , DeviceContextValues flags
    );

  [DllImport("user32.dll", EntryPoint = "ReleaseDC")]
  public static extern IntPtr ReleaseDC(IntPtr hWnd, IntPtr hDc);


  static void Run()
  {
    VerboseOn = true;
    var ci = CultureInfo.InvariantCulture;
    CultureInfo.CurrentCulture                = ci;
    CultureInfo.CurrentUICulture              = ci;
    CultureInfo.DefaultThreadCurrentCulture   = ci;
    CultureInfo.DefaultThreadCurrentUICulture = ci;

    // The approach taken from here: https://www.codeproject.com/Articles/856020/Draw-Behind-Desktop-Icons-in-Windows-plus
    Verbose("Looking for Progman window");
    var progmainWindow = FindWindow("Progman", null);
    if (progmainWindow == IntPtr.Zero)
    {
      throw new OopsException($"Didn't find the Progman window");
    }
    Verbose($"Found Progman window(0x{progmainWindow:X})");

    Verbose($"Poking Progman window to make it create the worker window");
    var sendResult = SendMessageTimeout(
        progmainWindow
      , 0x052C
      , 0
      , IntPtr.Zero
      , SendMessageTimeoutFlags.SMTO_NORMAL
      , 1000
      , out var result
      );
    if (sendResult == 0)
    {
      throw new OopsException($"Poking Progman window failed");
    }
    
    var workerwWindow = IntPtr.Zero;

    Verbose($"Poked Progman window, now to find WorkerW window next to icons window (SHELLDLL_DefView)");
    var enumResult = EnumWindows((tophandle, topparamhandle) =>
        {
          var iconsWindow = FindWindowEx(
              tophandle
            , IntPtr.Zero
            , "SHELLDLL_DefView"
            , IntPtr.Zero
            );

          if (iconsWindow != IntPtr.Zero)
          {
              workerwWindow = FindWindowEx(
                  IntPtr.Zero
                , tophandle
                , "WorkerW"
                , IntPtr.Zero
                );
          }

          return true;
        }
      , IntPtr.Zero
      );

    if (!(enumResult && workerwWindow != IntPtr.Zero))
    {
      throw new OopsException($"Couldn't locate the WorkerW window");
    }

    Verbose($"Found WorkerW window(0x{workerwWindow:X}), create device context");

    var dc = GetDCEx(
        workerwWindow
      , IntPtr.Zero
      ,   DeviceContextValues.Window
        | DeviceContextValues.Cache
        | DeviceContextValues.LockWindowUpdate
      );
    if (dc == IntPtr.Zero)
    {
      throw new OopsException($"Couldn't create device context for WorkerW window");
    }

    Verbose($"Created device context(0x{dc:X})");

    try
    {
      Verbose($"Draw a rectangle");
      using var b = new SolidBrush(Color.White);
      using var g = Graphics.FromHdc(dc);
      g.FillRectangle(b, 0, 0, 500, 500);
    }
    finally
    {
      ReleaseDC(workerwWindow, dc);
    }
  }

  [STAThread]
  public static int Main(string[] args)
  {
    try
    {
      Run();
      return 0;
    }
    catch(OopsException oops)
    {
      Fail(oops.Message??"We crashed but we don't know why!");
      return 98;
    }
    catch(Exception exc)
    {
      Fail($"We ran into an unknown issue and crashed, perhaps you should create an issue here: https://github.com/mrange/windows-terminal-shader-gallery/issues\nDetailed information to follow\n{exc}");
      return 99;
    }
  }
}
