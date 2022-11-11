# windows-terminal-shader-gallery
A gallery of shaders made for Windows Terminal

See the [project's github pages](https://mrange.github.io/windows-terminal-shader-gallery/).

## Build

```bash
# Install tools
dotnet tool restore
# Build site and tool
dotnet cake -- --target All
# Run windows terminal shader tool
dotnet cake -- --target Run
```