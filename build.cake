#nullable enable

var target = Argument("target", "GithubPages");

Task("Clean")
    .WithCriteria(c => HasArgument("rebuild"))
    .Does(() =>
{
    Information("Cleaning Github Pages: ./docs/");
    CleanDirectory("./docs/");
});

Task("GithubPages")
    .IsDependentOn("Clean")
    .Does(() =>
{
    Information("Building Github Pages: ./docs/");
    DotNetTool(".", "t4", "-o docs/index.html ./src/T4Site/index.tt");
});

RunTarget(target);