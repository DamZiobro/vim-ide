using System.Collections.Concurrent;
using ICSharpCode.NRefactory.Documentation;
using ICSharpCode.NRefactory.TypeSystem;
using OmniSharp.Solution;

namespace OmniSharp.Documentation
{
    public class DocumentationFetcher
    {
        static readonly ConcurrentDictionary<string, string> _documentationCache = new ConcurrentDictionary<string, string>();

        public string GetDocumentation(IProject project, IEntity entity)
        {
            string idString = entity.GetIdString();
            string result;
            if (_documentationCache.TryGetValue(idString, out result))
                return result;

            DocumentationComment documentationComment = null;
            if (entity.Documentation != null)
            {
                // Documentation from source code
                documentationComment = entity.Documentation;
            }
            else
            {
                if (entity.ParentAssembly.AssemblyName != null)
                {
                    IDocumentationProvider docProvider = 
                        XmlDocumentationProviderFactory.Get(project, entity.ParentAssembly.AssemblyName);

                    if (docProvider != null)
                    {
                        documentationComment = docProvider.GetDocumentation(entity);
                    }
                }
            }

            result = documentationComment != null 
                ? DocumentationConverter.ConvertDocumentation(documentationComment.Xml.Text) 
                : null;

            _documentationCache.TryAdd(idString, result);
            return result;
        }
    }
}
