using Nancy;
using Nancy.ModelBinding;

namespace OmniSharp.GotoFile {
    public class GotoFileModule : NancyModule {
        public GotoFileModule(GotoFileHandler gotoFileHandler) {
            Post["/gotofile"] = x => {
                var res = gotoFileHandler.GetSolutionFiles();
                return Response.AsJson(res);
            };
        }
    }
}
