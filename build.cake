#nullable enable

var target = Argument("target", "GithubPages");

Task("Clean")
    .WithCriteria(c => HasArgument("rebuild"))
    .Does(() =>
{
    var paths = new []
    {
      "./docs/gen-assets/"
    };
    foreach (var path in paths)
    {
      Information($"Cleaning: {path}");
      CleanDirectory(path);
    }
});

Task("GithubPages")
    .IsDependentOn("Clean")
    .Does(() =>
{
    Information("Building Github Pages: ./docs/");
    DotNetTool(".", "t4", "-o docs/index.html ./src/T4Site/index.tt");
});

RunTarget(target);