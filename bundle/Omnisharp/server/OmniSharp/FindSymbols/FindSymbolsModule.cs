using Nancy;

namespace OmniSharp.FindSymbols
{
    public class FindSymbolsModule : NancyModule
    {
        public FindSymbolsModule(FindSymbolsHandler handler)
        {
            Post["/findsymbols"] = x =>
                {
                    var res = handler.FindAllSymbols();
                    return Response.AsJson(res);
                };
        }
    }
}