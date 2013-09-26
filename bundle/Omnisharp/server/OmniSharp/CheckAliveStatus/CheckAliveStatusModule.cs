using Nancy;

namespace OmniSharp.CheckAliveStatus
{
    public class CheckAliveStatusModule : NancyModule
    {
        public CheckAliveStatusModule()
        {
            Post["/checkalivestatus"] = x =>
                {
                    return Response.AsJson(true);
                };
        }
    }
}
