namespace WindowsTerminalShaderTool;

static class Program
{
  static string GetTitle(MetadataV1 md) => md?.Info?.Title??md?.Id??"N/A";

  public static int Main(string[] args)
  {
    Application.Init();

    try
    {
      var win = new Window("Windows Terminal Shader Gallery") 
      {
        X       = 0
      , Y       = 0
      , Width   = Dim.Fill()
      , Height  = Dim.Fill()
      };

      var info = new Label("Downloading shader metadata...");
      var dialog = new Dialog("Loading...", 40, 3);
      dialog.Add(info);
      win.Add(dialog);
      Application.ExitRunLoopAfterFirstIteration = true;
      Application.Run(win);

      var model = ModelLoader.LoadAll();
      win.Remove(dialog);

      var shaderList = model
        .Select(GetTitle)
        .ToArray()
        ;
      var nav = new ListView(shaderList)
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
      allShaders.Add(nav);
      win.Add(allShaders);

      var summary = new Label("N/A");
      var summaryFrame = new FrameView("Description")
      {
        X         = 0
      , Y         = 0
      , Width     = Dim.Fill()
      , Height    = 4
      , CanFocus  = false
      };
      summaryFrame.Add(summary);

      var authorsFrame = new FrameView("Authors")
      {
        X         = 0
      , Y         = 4
      , Width     = 24
      , Height    = 6
      , CanFocus  = false
      };

      var licensesFrame = new FrameView("Licenses")
      {
        X         = 24
      , Y         = 4
      , Width     = 16
      , Height    = 6
      , CanFocus  = false
      };

      var applyButton = new Button("Apply")
      {
        X           = 24
      , Y           = 12
      , Width       = Dim.Fill()
      , Height      = Dim.Fill()
      , CanFocus    = false
      };

      var previewFrame = new FrameView("Preview")
      {
        X           = 24
      , Y           = 12
      , Width       = Dim.Fill()
      , Height      = Dim.Fill()
      , CanFocus    = false
      };

      var shader = new FrameView("<== Select a shader")
      {
        X         = 24
      , Y         = 0
      , Width     = Dim.Fill()
      , Height    = 12
      , CanFocus  = true
      };
      shader.Add(summaryFrame);
      shader.Add(authorsFrame);
      shader.Add(licensesFrame);

      win.Add(shader);
      win.Add(previewFrame);

      nav.SelectedItemChanged += e =>
      {
        var metadata  = model[e.Item];
        shader.Title  = GetTitle(metadata);
        summary.Text  = metadata?.Info?.Summary??"N/A";
      };

      Application.ExitRunLoopAfterFirstIteration = false;
      Application.Run(win);

      Application.Shutdown();

      return 0;
    }
    finally
    {
        Application.Shutdown();
    }

  }
}

