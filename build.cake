#nullable enable

var target = Argument("target", "All");

Task("Clean")
    .WithCriteria(c => HasArgument("rebuild"))
    .Does(() =>
{
    Information("Cleaning tool: ./src/WindowsTerminalShaderTool");
    DotNetClean("./src/WindowsTerminalShaderTool/WindowsTerminalShaderTool.csproj");
});

Task("Build")
    .IsDependentOn("Clean")
    .Does(() =>
{
    Information("Building tool: ./src/WindowsTerminalShaderTool");
    DotNetBuild("./src/WindowsTerminalShaderTool/WindowsTerminalShaderTool.csproj");
});

Task("Run")
    .IsDependentOn("Build")
    .Does(() =>
{
    Information("Running tool: ./src/WindowsTerminalShaderTool");
    DotNetRun(
            "./src/WindowsTerminalShaderTool/WindowsTerminalShaderTool.csproj"
        ,   new DotNetRunSettings ()
        {
            // Already built by Build step
            NoBuild = true
        });
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

Task("All")
    .IsDependentOn("Build")
    .IsDependentOn("AllMetaData")
    .IsDependentOn("GithubPages")
    ;

RunTarget(target);