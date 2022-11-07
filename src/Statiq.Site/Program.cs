namespace Statiq.Site
{
    public class Program
    {
        public static async Task<int> Main(string[] args)
        {
            var ci = CultureInfo.InvariantCulture;
            CultureInfo.CurrentCulture                = ci;
            CultureInfo.CurrentUICulture              = ci;
            CultureInfo.DefaultThreadCurrentCulture   = ci;
            CultureInfo.DefaultThreadCurrentUICulture = ci;

            return await Bootstrapper
                .Factory
                .CreateWeb(args)
                .RunAsync()
                ;
        }
    }
}