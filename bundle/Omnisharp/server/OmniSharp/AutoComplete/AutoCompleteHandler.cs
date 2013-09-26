using System;
using System.Collections.Generic;
using System.Linq;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.Completion;
using ICSharpCode.NRefactory.Completion;
using OmniSharp.Parser;
using OmniSharp.Solution;

namespace OmniSharp.AutoComplete
{
    public class AutoCompleteHandler
    {
        private readonly ISolution _solution;
        private readonly BufferParser _parser;
        private readonly Logger _logger;

        public AutoCompleteHandler(ISolution solution, BufferParser parser, Logger logger)
        {
            _solution = solution;
            _parser = parser;
            _logger = logger;
        }

        public IEnumerable<ICompletionData> CreateProvider(AutoCompleteRequest request)
        {
            request.Column = request.Column - request.WordToComplete.Length;

            var completionContext = new BufferContext (request, _parser);

            var partialWord = request.WordToComplete;

            var project = _solution.ProjectContainingFile(request.FileName);

            ICompletionContextProvider contextProvider = new DefaultCompletionContextProvider
                (completionContext.Document, completionContext.ParsedContent.UnresolvedFile);

            var instantiating = IsInstantiating(completionContext.NodeCurrentlyUnderCursor);

            var engine = new CSharpCompletionEngine
                ( completionContext.Document
                , contextProvider
                , new CompletionDataFactory
                  ( project
                  , partialWord
                  , instantiating
                  , request.WantDocumentationForEveryCompletionResult)
                , completionContext.ParsedContent.ProjectContent
                , completionContext.ResolveContext)
                {
                    EolMarker = Environment.NewLine
                };

            _logger.Debug("Getting Completion Data");

            IEnumerable<ICompletionData> data = engine.GetCompletionData(completionContext.CursorPosition, true);
            _logger.Debug("Got Completion Data");
            return data.Where(d => d != null && d.CompletionText.IsValidCompletionFor(partialWord))
                       .FlattenOverloads()
                       .RemoveDupes()
					   .OrderByDescending(d => d.CompletionText.IsValidCompletionStartsWithExactCase(partialWord))
					   .ThenByDescending(d => d.CompletionText.IsValidCompletionStartsWithIgnoreCase(partialWord))
					   .ThenByDescending(d => d.CompletionText.IsCamelCaseMatch(partialWord))
					   .ThenByDescending(d => d.CompletionText.IsSubsequenceMatch(partialWord))
                       .ThenBy(d => d.CompletionText);
        }

        private static bool IsInstantiating(AstNode nodeUnderCursor)
        {
            bool instantiating = false;

            if (nodeUnderCursor != null 
                && nodeUnderCursor.Parent != null 
                && nodeUnderCursor.Parent.Parent != null) 
            {
                instantiating =
                    nodeUnderCursor.Parent.Parent.Children.Any(child => child.Role.ToString() == "new");
            }
            return instantiating;
        }
    }
}
