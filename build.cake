#nullable enable
#addin nuget:?package=Cake.Git&version=2.0.0

using System.Text.RegularExpressions;

const string projDir    = "./src/WindowsTerminalShaderTool";
const string projPath   = "./src/WindowsTerminalShaderTool/WindowsTerminalShaderTool.csproj";
var target          = Argument("target", "Run");
var configuration   = Argument("configuration", "Release");

var nugetApi      = "https://api.nuget.org/v3/index.json";
var nugetApiKey   = EnvironmentVariable("NUGET_API_KEY");

record BuildData(
        string? Version
    );

Setup(ctx =>
    {
        var tip = GitLogTip(".");
        var tags = GitTags(".", true);
        var tipTag = tags
            .FirstOrDefault(tag => tag.Target.Sha == tip.Sha)
            ;
        string? version = null;

        if (tipTag is not null)
        {
            var tagName = tipTag.FriendlyName;
            var match   = Regex.Match(tagName, @"^v(?<version>\d+\.\d+\.\d+)$");
            if (match.Success)
            {
                version = match.Groups["version"].Value;
                Information($"Tip is tagged with version: {version}");
            }
            else
            {
                Warning($"Tip is tagged, but the tag doesn't match the version schema: {tagName}");
            }
        }
        else
        {
            Information("Tip is not tagged with version");
        }

        return new BuildData(version);
    });


Task("Clean")
    .WithCriteria(c => HasArgument("rebuild"))
    .Does(() =>
{
    Information($"Cleaning tool: {projDir}");
    DotNetClean(projPath);
});

Task("Restore")
    .IsDependentOn("Clean")
    .Does(() =>
{
    Information($"Restoring tool: {projDir}");
    DotNetRestore(
            projPath
        ,   new()
        {
            LockedMode      = true
        });
});

Task("Build")
    .IsDependentOn("Restore")
    .Does(() =>
{
    Information($"Building tool: {projDir}");
    DotNetBuild(
            projPath
        ,   new()
        {
            Configuration   = configuration
        ,   NoRestore       = true
        });
});

Task("Pack")
    .IsDependentOn("Build")
    .Does<BuildData>((ctx, bd) =>
{
    Information($"Packing tool: {projDir}");
    var bs = new DotNetMSBuildSettings()
        .SetVersion(bd.Version??"0.0.1")
        ;

    DotNetPack(projPath, new()
    {
        Configuration   = configuration
    ,   NoBuild         = true
    ,   NoRestore       = true
    ,   MSBuildSettings = bs
    });
});

Task("PublishToNuGet")
    .WithCriteria<BuildData>((ctx, bd) => bd.Version is not null)
    .IsDependentOn("Pack")
    .Does<BuildData>((ctx, bd) =>
{
    Information($"Publishing tool to nuget: {projDir}");
    var packPath = $"{projDir}/nupkg/WindowsTerminalShaderTool.{bd.Version}.nupkg";
    Information($"Publishing package: {packPath}");
    DotNetNuGetPush(packPath, new()
    {
        ApiKey = nugetApiKey
    ,   Source = nugetApi
    });
});


Task("Run")
    .IsDependentOn("Build")
    .Does(() =>
{
    Information($"Running tool: {projDir}");
    DotNetRun(
            projPath
        ,   new DotNetRunSettings ()
        {
            // Already built by Build step
            NoBuild         = true
            // Already restored by Restore step
        ,   NoRestore       = true
        ,   Configuration   = configuration
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

Task("Site")
    .IsDependentOn("AllMetaData")
    .IsDependentOn("GithubPages")
    ;

Task("All")
    .IsDependentOn("Pack")
    .IsDependentOn("Site")
    ;

RunTarget(target);