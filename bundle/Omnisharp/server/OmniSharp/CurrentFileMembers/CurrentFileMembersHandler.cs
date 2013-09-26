using System.Collections.Generic;
using System.Linq;
using OmniSharp.AutoComplete;
using OmniSharp.Common;
using OmniSharp.Parser;

namespace OmniSharp.CurrentFileMembers {

    public class CurrentFileMembersHandler {
        private readonly BufferParser _parser;

        public CurrentFileMembersHandler(BufferParser parser) {
            _parser = parser;
        }

        /// <summary>
        ///   Returns a representation of the current buffer's members
        ///   and their locations. The caller may build a UI that lets
        ///   the user navigate to them quickly.
        /// </summary>
        public CurrentFileMembersAsTreeResponse
            GetCurrentFileMembersAsTree(CurrentFileMembersRequest request) {
            var context = new BufferContext(request, this._parser);

            var typesDefinedInThisFile = context.ParsedContent
                .UnresolvedFile.TopLevelTypeDefinitions;

            return new CurrentFileMembersAsTreeResponse
                (typesDefinedInThisFile, context.Document);
        }

        /// <summary>
        ///   Like GetCurrentFileMembersAsTree() but the result has no
        ///   tree hierarchy and is completely flat. The Locations
        ///   appear in the order they are in the given file.
        /// </summary>
        public IEnumerable<QuickFix>
            GetCurrentFileMembersAsFlat(CurrentFileMembersRequest request) {

            // Get and flatten a tree response.
            var treeResponse = this.GetCurrentFileMembersAsTree(request);

            // Ensure all topLevelTypeDefinitions have their members
            // right after them in the response
            var locationsOfTypesAndChildren = treeResponse
                .TopLevelTypeDefinitions
                .SelectMany(tld => new[] {tld.Location}
                            .Concat(tld.ChildNodes
                                    .Select(cn => cn.Location)));

            return locationsOfTypesAndChildren;
        }
    }
}
