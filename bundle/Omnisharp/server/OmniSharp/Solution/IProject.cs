using System;
using System.Collections.Generic;
using System.Xml.Linq;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.TypeSystem;

namespace OmniSharp.Solution
{
    public interface IProject
    {
        IProjectContent ProjectContent { get; set; }
        string Title { get; }
        string FileName { get; }
        List<CSharpFile> Files { get; }
        List<IAssemblyReference> References { get; set; }
        CSharpFile GetFile(string fileName);
        CSharpParser CreateParser();
        XDocument AsXml();
        void Save(XDocument project);
        Guid ProjectId { get; }
        void AddReference(IAssemblyReference reference);
        void AddReference(string reference);
    }
}