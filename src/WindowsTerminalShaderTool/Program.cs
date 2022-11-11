namespace WindowsTerminalShaderTool;

class OopsException : Exception
{
  public OopsException(string msg) : base(msg)
  {
  }
}

static class Program
{
  static string GetTitle(MetadataV1 md) => md?.Info?.Title??md?.Id??"N/A";

  static void Error(string msg)
  {
    var cc = Console.ForegroundColor;
    try
    {
      Console.ForegroundColor = ConsoleColor.Red;
      Console.WriteLine(msg);
    }
    finally
    {
      Console.ForegroundColor = cc;
    }
  }

  static readonly string _tempPath        = Path.GetTempPath();
  static readonly string _downloadsPath   = Path.Combine(_tempPath, "wt-shader-tool", "downloads");

  static void ApplyShader(
      string      settingsPath
    , string      backupSettingsPath
    , MetadataV1? metadata
    )
  {
    string? hlslPath = null;
    if (metadata is not null)
    {
      var hlslBits = Models.LoadFragment0FromGithub(metadata);

      hlslPath     = Path.Combine(_downloadsPath, $"{metadata.Id}.hlsl");

      Directory.CreateDirectory(_downloadsPath);
      File.WriteAllBytes(hlslPath, hlslBits);
    }

    var root = Models.LoadSettings(settingsPath);
    if (root is null)
    {
      throw new OopsException($"We couldn't loading Windows Terminal settings:{settingsPath}");
    }

    const string ProfilesKey    = "profiles"                    ;
    const string DefaultsKey    = "defaults"                    ;
    const string ShaderPathKey  = "experimental.pixelShaderPath";

    var profiles = root.FindProperty(ProfilesKey) as JsonObject;
    if (profiles is null)
    {
      throw new OopsException($"We couldn't find a profiles section in Windows Terminal settings: {settingsPath}");
    }
    var defaultProfile  = profiles.FindProperty(DefaultsKey) as JsonObject;
    if (defaultProfile is null)
    {
      defaultProfile = new JsonObject(defaultProfile?.Options);
      profiles.Remove(DefaultsKey);
      profiles.Add(DefaultsKey, defaultProfile);
    }

    defaultProfile.Remove(ShaderPathKey);
    if (hlslPath is not null)
    {
      defaultProfile.Add(ShaderPathKey, JsonValue.Create(hlslPath));
    }

    if (!File.Exists(backupSettingsPath))
    {
      File.Copy(settingsPath, backupSettingsPath, overwrite: true);
    }
    Models.SaveSettings(settingsPath, root);
  }

  static void RunApp(string settingsPath, string[] args)
  {
    var now = DateOnly.FromDateTime(DateTime.Now);
    var backupSettingsPath  = settingsPath + $".{now.Year:D4}-{now.Month:D2}-{now.Day:D2}.backup";

    Application.Init();

    try
    {
      var win = new Window("Windows Terminal Shader Gallery (hit Ctrl-Q to quit)") 
      {
        X       = 0
      , Y       = 0
      , Width   = Dim.Fill()
      , Height  = Dim.Fill()
      };

      var info = new Label("Downloading shader metadata...\n(If it seems to get stuck here hit enter)");
      var dialog = new Dialog("Loading...", 40, 4);
      dialog.Add(info);
      win.Add(dialog);
      Application.ExitRunLoopAfterFirstIteration = true;
      Application.Run(win);

      var noShader = new MetadataV1()
      {
        MetadataVersion = "1"
      , Id              = "no-shader"
      , Info            = new()
        {
          Title     = "No shader"
        , Summary   = "Dull and boring background. Cheap to compute though!"
        }
      };
      var model = Models
        .LoadMetadataFromGithub()
        .Prepend(noShader)
        .ToArray()
        ;
      win.Remove(dialog);

      var shaderList = model
        .Select(GetTitle)
        .ToArray()
        ;
      var navigation = new ListView(shaderList)
      {
        X             = 0
      , Y             = 0
      , Width         = Dim.Fill()
      , Height        = Dim.Fill()
      , AllowsMarking = false
      , CanFocus      = true
      };

      var allShaders = new FrameView("All shaders")
      {
        X         = 0
      , Y         = 0
      , Width     = 23
      , Height    = Dim.Fill()
      , CanFocus  = true
      };
      allShaders.Add(navigation);
      win.Add(allShaders);

      var summary = new TextView()
      {
        X         = 0
      , Y         = 0
      , Width     = Dim.Fill()
      , Height    = Dim.Fill()
      , CanFocus  = false
      , WordWrap  = true
      , ReadOnly  = true
      };
      var summaryFrame = new FrameView("Description")
      {
        X         = 0
      , Y         = 0
      , Width     = Dim.Fill()
      , Height    = 5
      , CanFocus  = false
      };
      summaryFrame.Add(summary);

      var authors = new ListView()
      {
        X             = 0
      , Y             = 0
      , Width         = Dim.Fill()
      , Height        = Dim.Fill()
      , AllowsMarking = false
      , CanFocus      = false
      };
      var authorsFrame = new FrameView("Authors")
      {
        X         = 0
      , Y         = 5
      , Width     = 24
      , Height    = 6
      , CanFocus  = false
      };
      authorsFrame.Add(authors);

      var licenses = new ListView()
      {
        X             = 0
      , Y             = 0
      , Width         = Dim.Fill()
      , Height        = Dim.Fill()
      , AllowsMarking = false
      , CanFocus      = false
      };
      var licensesFrame = new FrameView("Licenses")
      {
        X         = 24
      , Y         = 5
      , Width     = 16
      , Height    = 6
      , CanFocus  = false
      };
      licensesFrame.Add(licenses);

      var applyButton = new Button("Apply shader")
      {
        X           = 40
      , Y           = 9
      };

      var shadertoyLink = new Label("")
      {
        X           = 41
      , Y           = 7
      };

      var black   = new Terminal.Gui.Attribute(0, Color.Black, Color.Black);
      var blackScheme = new ColorScheme
      {
        Disabled  = black
      , Focus     = black
      , HotFocus  = black
      , HotNormal = black
      , Normal    = black
      };

      var preview = new Label(" ")
      {
        X           = 0
      , Y           = 0
      , Width       = Dim.Fill()
      , Height      = Dim.Fill()
      , CanFocus    = false
      , ColorScheme = blackScheme
      };

      var previewFrame = new FrameView("Preview")
      {
        X           = 24
      , Y           = 13
      , Width       = Dim.Fill()
      , Height      = Dim.Fill()
      , CanFocus    = false
      };
      previewFrame.Add(preview);

      var shader = new FrameView("No shader selected")
      {
        X         = 24
      , Y         = 0
      , Width     = Dim.Fill()
      , Height    = 13
      , CanFocus  = true
      };
      shader.Add(summaryFrame);
      shader.Add(authorsFrame);
      shader.Add(licensesFrame);
      shader.Add(shadertoyLink);
      shader.Add(applyButton);

      win.Add(shader);
      win.Add(previewFrame);

      navigation.SelectedItemChanged += e =>
      {
        var metadata        = model[e.Item];
        var shaderToy       = metadata.Info?.Shadertoy;
        shader.Title        = GetTitle(metadata);
        summary.Text        = metadata.Info?.Summary??"N/A";
        shadertoyLink.Text  = 
          shaderToy is not null
          ? $"https://www.shadertoy.com/view/{shaderToy}"
          : ""
          ;
        authors.SetSource(metadata.Legal?.Authors?.ToArray()??Array.Empty<string>());
        licenses.SetSource(metadata.Legal?.LicenseExpressions?.Order()?.ToArray()??Array.Empty<string>());
      };

      void ApplyCurrentShader()
      {
        if (!(navigation.SelectedItem >= 0 && navigation.SelectedItem < model.Length))
        {
          return;
        }

        var metadata = model[navigation.SelectedItem];

        var effectiveMetaData = metadata.Id == noShader.Id ? null : metadata;

        ApplyShader(settingsPath, backupSettingsPath, effectiveMetaData);
      }

      navigation.KeyPress += e =>
      {
        if (e.KeyEvent.Key == Key.Enter)
        {
          ApplyCurrentShader();
          e.Handled = true;
        }
      };

      applyButton.Clicked += () => 
      {
        ApplyCurrentShader();
      };

      if (model.Length > 0)
      {
        navigation.SelectedItem = 0;
      }
      win.FocusFirst();


      Application.ExitRunLoopAfterFirstIteration = false;
      Application.Run(win);
    }
    finally
    {
      Application.Shutdown();
    }
  }



  public static int Main(string[] args)
  {
    try
    {
      var ci = CultureInfo.InvariantCulture;
      CultureInfo.DefaultThreadCurrentCulture   = ci;
      CultureInfo.DefaultThreadCurrentUICulture = ci;
      CultureInfo.CurrentCulture                = ci;
      CultureInfo.CurrentUICulture              = ci;

      var localAppDataPath      = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
      var packagePath           = Path.Combine(localAppDataPath, "Packages");
      var windowsTerminalPaths  = Directory.GetDirectories(packagePath, "Microsoft.WindowsTerminal_*");

      if (windowsTerminalPaths.Length == 0)
      {
        throw new OopsException("Windows Terminal doesn't seem to be installed on your system! We need Windows Terminal!");
      }

      if (windowsTerminalPaths.Length > 1)
      {
        throw new OopsException("We found multiple installation of Windows Terminal and got confused. Create issue here: https://github.com/mrange/windows-terminal-shader-gallery/issues");
      }

      var windowsTerminalPath = windowsTerminalPaths[0];
      var settingsPath        = Path.Combine(windowsTerminalPath, "LocalState", "settings.json");

      if (!File.Exists(settingsPath))
      {
        throw new OopsException("We didn't find a settings file for Windows Terminal. Please launch Windows Terminal and save your settings.");
      }

      RunApp(settingsPath, args);

      return 0;

    }
    catch(OopsException oops)
    {
      Error(oops.Message??"We crashed but we don't know why!");
      return 98;
    }
    catch(Exception exc)
    {
      Error($"We ran into an unknown issue and crashed, perhaps you should create an issue here: https://github.com/mrange/windows-terminal-shader-gallery/issues\nDetailed information to follow\n{exc}");
      return 99;
    }

  }
}

