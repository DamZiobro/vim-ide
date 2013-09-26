using Nancy;
using Nancy.ModelBinding;
using OmniSharp.AutoComplete;

namespace OmniSharp.Overrides {
    public class GetOverrideTargetsModule : NancyModule {

        public GetOverrideTargetsModule
            (OverrideHandler overrideHandler) {

            Post["/getoverridetargets"] = x =>
                {
                    var req = this.Bind<AutoCompleteRequest>();
                    var completions = overrideHandler.GetOverrideTargets(req);
                    return Response.AsJson(completions);
                };
        }

    }
}
