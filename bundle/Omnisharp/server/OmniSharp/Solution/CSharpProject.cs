// Copyright (c) AlphaSierraPapa for the SharpDevelop Team
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
// to whom the Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.TypeSystem;
using ICSharpCode.NRefactory.Utils;
using Mono.Cecil;

namespace OmniSharp.Solution
{
    public class CSharpProject : IProject
    {
        public static readonly string[] AssemblySearchPaths = {
            //Windows Paths
            @"C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.5",
            @"C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.0",
            @"C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\v3.5",
            @"C:\Program Files\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.5",
            @"C:\Program Files\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.0",
            @"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.5",
            @"C:\Windows\Microsoft.NET\Framework\v2.0.50727",
            @"C:\Program Files (x86)\Microsoft ASP.NET\ASP.NET Web Pages\v2.0\Assemblies",
            @"C:\Program Files (x86)\Microsoft ASP.NET\ASP.NET Web Pages\v1.0\Assemblies",
            @"C:\Program Files (x86)\Microsoft ASP.NET\ASP.NET MVC 4\Assemblies",
            @"C:\Program Files (x86)\Microsoft ASP.NET\ASP.NET MVC 3\Assemblies",
            @"C:\Program Files\Microsoft ASP.NET\ASP.NET Web Pages\v2.0\Assemblies",
            @"C:\Program Files\Microsoft ASP.NET\ASP.NET Web Pages\v1.0\Assemblies",
            @"C:\Program Files\Microsoft ASP.NET\ASP.NET MVC 4\Assemblies",
            @"C:\Program Files\Microsoft ASP.NET\ASP.NET MVC 3\Assemblies",
            @"C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v4.5",
            @"C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v4.0",
            @"C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v2.0",
            @"C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\ReferenceAssemblies\v2.0",
            @"C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\IDE\PublicAssemblies",
            @"C:\Program Files\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v4.5",
            @"C:\Program Files\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v4.0",
            @"C:\Program Files\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v2.0",
            @"C:\Program Files\Microsoft Visual Studio 10.0\Common7\IDE\ReferenceAssemblies\v2.0",
            @"C:\Program Files\Microsoft Visual Studio 9.0\Common7\IDE\PublicAssemblies",
            
            //Unix Paths
            @"/usr/local/lib/mono/4.0",
            @"/usr/local/lib/mono/3.5",
            @"/usr/local/lib/mono/2.0",
            @"/usr/lib/mono/4.0",
            @"/usr/lib/mono/3.5",
            @"/usr/lib/mono/2.0",

            //OS X Paths
            @"/Library/Frameworks/Mono.Framework/Libraries/mono/4.5",
            @"/Library/Frameworks/Mono.Framework/Libraries/mono/4.0",
            @"/Library/Frameworks/Mono.Framework/Libraries/mono/3.5",
            @"/Library/Frameworks/Mono.Framework/Libraries/mono/2.0",
        };

        private readonly ISolution _solution;
        private readonly string _assemblyName;
        public string FileName { get; private set; }
        public Guid ProjectId { get; private set; }

        public string Title { get; private set; }
        public IProjectContent ProjectContent { get; set; }
        public List<CSharpFile> Files { get; private set; }

        private readonly CompilerSettings _compilerSettings;

        public CSharpProject(ISolution solution, string title, string fileName, Guid id)
        {
            _solution = solution;
            Title = title;
            FileName = fileName;
            ProjectId = id;
            Files = new List<CSharpFile>();

            var p = new Microsoft.Build.Evaluation.Project(FileName);
            _assemblyName = p.GetPropertyValue("AssemblyName");

            _compilerSettings = new CompilerSettings()
                {
                    AllowUnsafeBlocks = GetBoolProperty(p, "AllowUnsafeBlocks") ?? false,
                    CheckForOverflow = GetBoolProperty(p, "CheckForOverflowUnderflow") ?? false,
                };
            string[] defines = p.GetPropertyValue("DefineConstants").Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (string define in defines)
                _compilerSettings.ConditionalSymbols.Add(define);

            foreach (var item in p.GetItems("Compile"))
            {
                try
                {
                    string path = Path.Combine(p.DirectoryPath, item.EvaluatedInclude).FixPath();
                    if (File.Exists(path))
                        Files.Add(new CSharpFile(this, new FileInfo(path).FullName));
                }
                catch (NullReferenceException)
                {
                }
            }

            References = new List<IAssemblyReference>();
            string mscorlib = FindAssembly(AssemblySearchPaths, "mscorlib");
            if (mscorlib != null)
                AddReference(LoadAssembly(mscorlib));
            else
                Console.WriteLine("Could not find mscorlib");

            bool hasSystemCore = false;
            foreach (var item in p.GetItems("Reference"))
            {

                string assemblyFileName = null;
                if (item.HasMetadata("HintPath"))
                {
                    assemblyFileName = Path.Combine(p.DirectoryPath, item.GetMetadataValue("HintPath")).FixPath();
                    if (!File.Exists(assemblyFileName))
                        assemblyFileName = null;
                }
                //If there isn't a path hint or it doesn't exist, try searching
                if (assemblyFileName == null)
                    assemblyFileName = FindAssembly(AssemblySearchPaths, item.EvaluatedInclude);

                //If it isn't in the search paths, try the GAC
                if (assemblyFileName == null)
                    assemblyFileName = FindAssemblyInNetGac(item.EvaluatedInclude);

                if (assemblyFileName != null)
                {
                    if (Path.GetFileName(assemblyFileName).Equals("System.Core.dll", StringComparison.OrdinalIgnoreCase))
                        hasSystemCore = true;

                    Console.WriteLine("Loading assembly " + item.EvaluatedInclude);
                    try
                    {
                        AddReference(LoadAssembly(assemblyFileName));
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine(e);
                    }

                }
                else
                    Console.WriteLine("Could not find referenced assembly " + item.EvaluatedInclude);
            }
            if (!hasSystemCore && FindAssembly(AssemblySearchPaths, "System.Core") != null)
                AddReference(LoadAssembly(FindAssembly(AssemblySearchPaths, "System.Core")));

            foreach (var item in p.GetItems("ProjectReference"))
                AddReference(new ProjectReference(_solution, item.GetMetadataValue("Name")));

            this.ProjectContent = new CSharpProjectContent()
                .SetAssemblyName(this._assemblyName)
                .AddAssemblyReferences(References)
                .AddOrUpdateFiles(Files.Select(f => f.ParsedFile));
            
        }

        public List<IAssemblyReference> References { get; set; }

        public void AddReference(IAssemblyReference reference)
        {
            References.Add(reference);
        }

        public void AddReference(string reference)
        {
            AddReference(LoadAssembly(reference));
        }

        public CSharpFile GetFile(string fileName)
        {
            return Files.Single(f => f.FileName.Equals(fileName, StringComparison.InvariantCultureIgnoreCase));
        }

        public CSharpParser CreateParser()
        {
            return new CSharpParser(_compilerSettings);
        }

        public XDocument AsXml()
        {
            return XDocument.Load(FileName);
        }

        public void Save(XDocument project)
        {
            project.Save(FileName);
        }
        
        public override string ToString()
        {
            return string.Format("[CSharpProject AssemblyName={0}]", _assemblyName);
        }

        static ConcurrentDictionary<string, IUnresolvedAssembly> assemblyDict = new ConcurrentDictionary<string, IUnresolvedAssembly>(Platform.FileNameComparer);

        public static IUnresolvedAssembly LoadAssembly(string assemblyFileName)
        {
            return assemblyDict.GetOrAdd(assemblyFileName, file => new CecilLoader().LoadAssemblyFile(file));
        }

        public static string FindAssembly(IEnumerable<string> assemblySearchPaths, string evaluatedInclude)
        {
            if (evaluatedInclude.IndexOf(',') >= 0)
                evaluatedInclude = evaluatedInclude.Substring(0, evaluatedInclude.IndexOf(','));
            
            string directAssemblyFile = (evaluatedInclude + ".dll").FixPath();
            if (File.Exists(directAssemblyFile))
                return directAssemblyFile;

            foreach (string searchPath in assemblySearchPaths)
            {
                string assemblyFile = Path.Combine(searchPath, evaluatedInclude + ".dll").FixPath();
                if (File.Exists(assemblyFile))
                    return assemblyFile;
            }
            return null;
        }

        public static string FindAssemblyInNetGac(string evaluatedInclude)
        {
            try
            {
                AssemblyNameReference assemblyNameReference = AssemblyNameReference.Parse(evaluatedInclude);
                return GacInterop.FindAssemblyInNetGac(assemblyNameReference);
            }
            catch(TypeInitializationException) 
            {
                Console.WriteLine ("Fusion not available - cannot get {0} from the gac.", evaluatedInclude);
                return null;
            }
        }


        static bool? GetBoolProperty(Microsoft.Build.Evaluation.Project p, string propertyName)
        {
            string val = p.GetPropertyValue(propertyName);
            if (val.Equals("true", StringComparison.OrdinalIgnoreCase))
                return true;
            if (val.Equals("false", StringComparison.OrdinalIgnoreCase))
                return false;
            return null;
        }
    }
}
