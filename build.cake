#nullable enable

var target = Argument("target", "Publish");

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

Task("AllMetaData")
    .IsDependentOn("Clean")
    .Does(() =>
{
    Information("Building all metadata: ./gallery/all_metadata.json");
    DotNetTool(".", "t4", "-o ./gallery/all_metadata.json ./src/T4Site/all_metadata.tt");
});

Task("GithubPages")
    .IsDependentOn("Clean")
    .Does(() =>
{
    Information("Building Github Pages: ./docs/");
    DotNetTool(".", "t4", "-o ./docs/index.html ./src/T4Site/index.tt");
});

Task("Publish")
    .IsDependentOn("AllMetaData")
    .IsDependentOn("GithubPages")
    ;

RunTarget(target);